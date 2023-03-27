from spreco.common import utils
from spreco.model.ncsn import ncsn

import os
import numpy as np
import tqdm
import argparse

import tensorflow.compat.v1 as tf
tf.disable_eager_execution()

def main(config_path, filelist, gpu_id, file_batches):

    try:
        config = utils.load_config(config_path)
    except:
        raise Exception('Loading config failed, check the path for config file') 

    try:
        model_config = utils.load_config(config['model_folder']+'/config.yaml')
    except:
        raise Exception('Loading config failed, check the path for the model')

    model_path   = os.path.join(config['model_folder'], config['model_name'])

    np.random.seed(model_config['seed'])
    os.environ["CUDA_DEVICE_ORDER"]    = "PCI_BUS_ID"
    os.environ["CUDA_VISIBLE_DEVICES"] = gpu_id

    batch_size = config['nr_samples']*file_batches
    x = tf.placeholder(tf.float32, shape=[batch_size]+model_config['input_shape'])
    y = tf.placeholder(tf.float32, shape=[batch_size]+model_config['input_shape'][:-1])
    h = tf.placeholder(tf.int32, shape=[batch_size])
    tau = tf.placeholder(tf.float32, shape=[1])
    std = tf.placeholder(tf.float32, shape=[1])
    ins_ncsn = ncsn(model_config)

    grad_op = ins_ncsn.net.forward(x,h)
    saver   = tf.train.Saver()
    sess    = tf.Session()
    sess.run(tf.global_variables_initializer())
    saver.restore(sess, model_path)
    sigmas  = sess.run(ins_ncsn.sigmas)

    loss_op = tf.reduce_sum(tf.math.square(tf.sqrt(x[...,0]*x[...,0]+x[...,1]*x[...,1])-y), axis=[1,2])
    gradient_x_op = tf.gradients(loss_op, x)
    run_op = x - config['step_size']*gradient_x_op[0] + tau*grad_op + tf.random.normal(x.shape)*std

    def ancestral_sampler_tf(mag, nr_samples=2, n_steps_each=50):

        x_mod = np.random.rand(*x.shape)

        for i in range(len(sigmas)-1):

            sigma     = sigmas[i]
            adj_sigma = sigmas[i+1]
            tau_val       = (sigma ** 2 - adj_sigma ** 2)
            std_val       = np.sqrt(adj_sigma ** 2 * tau_val / (sigma ** 2))
            labels = np.array([i]*nr_samples, dtype=np.int32)

            for _ in range(n_steps_each):
                x_mod = sess.run(run_op, {x:x_mod, h:labels, y:mag, tau:[tau_val], std: [std_val]})

        return x_mod

    try: 
        files = utils.read_filelist(filelist)
    except:
        raise Exception('Execution of shell script failed, please check!')

    nr_files = len(files)

    def load_single_file(path):

        basename = os.path.basename(path)
        truth = np.load(path)[config['key']]
        truth = truth/np.max(np.abs(truth))
        mag   = np.abs(truth)

        return mag, basename

    def load_batches(batches):
        mags      = []
        basenames = []
        for file in batches:
            print("Augmenting %s ..."%file)
            mag, basename = load_single_file(file)
            mags.append(mag)
            basenames.append(basename)
        return mags, basenames

    def write_file(cplxes, cplxes_, basenames):
        for cplx, cplx_, basename in zip(cplxes, cplxes_, basenames):
            utils.writecfl(os.path.join(config['savepath'], basename[:-4]), cplx)
            utils.writecfl(os.path.join(config['savepath'], basename[:-4])+'_mag_reserved', cplx_)


    if nr_files != 0:
        for idx in tqdm.tqdm(range(0, nr_files, file_batches)):
            
            mags = []
            basenames = []

            if idx+file_batches <= nr_files:
                mags, basenames = load_batches(files[idx: idx+file_batches])

            else:
                for file in files[idx: idx+file_batches]:
                    mag, basename = load_single_file(file)
                    mags.append(mag)
                    basenames.append(basename)
                for _ in range(file_batches-nr_files%file_batches):
                    mags.append(mag)

            mags = np.array(mags)[:,np.newaxis,...]
            mags = np.repeat(mags,config['nr_samples'], axis=1)
            mags = np.reshape(mags, y.shape)

            cplx  = utils.float2cplx(ancestral_sampler_tf(mags, config['nr_samples']*file_batches, config['n_steps_each']))
            phase = np.angle(cplx)
            cplx_ = mags*np.exp(phase*1j)

            cplxs = np.split(cplx, file_batches)
            cplxs_ = np.split(cplx_, file_batches)

            if idx+file_batches < nr_files:
                write_file(cplxs, cplxs_, basenames)
            else:
                le=len(basenames)
                write_file(cplxs[0:le], cplxs_[0:le], basenames)
    else:
        raise Exception('No file was found, please check filelist')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--config', metavar='path', default='/home/gluo/workspace/nlinv/scripts/configs/phase_abide.yaml', help='')
    parser.add_argument('--filelist', metavar='path', default='/home/gluo/workspace/nlinv/scripts/data/curie_filelist_ac', help='')
    parser.add_argument('--gpu_id', metavar='gpu_id', default='0', help='')
    parser.add_argument('--file_batches', metavar='file_batches', type=int, default=2, help='')

    args = parser.parse_args()
    main(args.config, args.filelist, args.gpu_id, args.file_batches)