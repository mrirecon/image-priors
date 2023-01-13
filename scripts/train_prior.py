from spreco.common import utils, pipe
from spreco.workbench.worker import worker

import os
import numpy as np
import argparse

def main(config_path):

    try:
        config = utils.load_config(config_path)
    except:
        raise Exception('Loading config file failed, please check if it exists.')

    try: 
        train_files = utils.read_filelist(config['train_list'])
    except:
        raise Exception("Load the list of train files failed, please check!")
    
    try:
        test_files = utils.read_filelist(config['test_list'])
    except:
        raise Exception("Load the list of test files failed, please check!")

    def load_file(x):
        """
        x     ---> file path
        imgs  ---> normalized images with shape (batch_size, x, y, 2)
        """
        path, ext = os.path.splitext(x)
        if ext == '.cfl' or ext == '.hdr':
            imgs = np.squeeze(utils.readcfl(path))
            imgs = imgs / np.max(np.abs(imgs), axis=(1,2), keepdims=True)
            imgs = utils.cplx2float(imgs)
        elif ext == '.npz':
            x = np.squeeze(utils.npz_loader(x, 'rss'))
            x = utils.normalize_with_max(x)
            imgs = x[np.newaxis, ...]
        return imgs

    def flip_and_rotate(x, case=1):

        if case == 1:
            # flip leftside right
            x = x[:,:,::-1,...]
        elif case == 2:
            # flip upside down
            x = x[:,::-1,:,...]
        elif case == 3:
            # 
            x = x[:,:,::-1,...]
            x = x[:,::-1,:,...]
        elif case == 4:
            x = np.rot90(x, k=1, axes=(1,2))
        elif case == 5:
            x = np.rot90(x, k=1, axes=(1,2))
            x = x[:,:,::-1,...]
        elif case == 6:
            x = np.rot90(x, k=3, axes=(1,2))
        elif case == 7:
            x = np.rot90(x, k=3, axes=(1,2))
            x = x[:,:,::-1,...]
        elif case == 8:
            x = x
        else:
            raise Exception("check you the number of possible cases!")
        return x
    

    def aug_load_file(x):
        x = np.mean(load_file(x), axis=0, keepdims=True)
        case_nums = np.random.randint(1,9,1)
        for i, case in enumerate(case_nums):
            x[i] = flip_and_rotate(x[i][np.newaxis, ...], case)
        return x

    def randint(x, dtype='int32'):
        # x is a dummy arg
        return np.random.randint(0, config['nr_levels'], (5), dtype=dtype)

    def randfloat(x, eps= 1.e-5, T= 1.):
        # x is a dummy arg
        return np.random.uniform(eps, T, size=(100))

    if config['model'] == 'NCSN':
        parts_funcs = [[aug_load_file], [randint]]
        shape_info      = [config['input_shape'], [1]]
        names           = ['inputs', 't']
    elif config['model'] == 'SDE':
        parts_funcs = [[aug_load_file], [randfloat]]
        shape_info      = [config['input_shape'], [1]]
        names           = ['inputs', 't']
    elif config['model'] == 'PIXELCNN':
        parts_funcs = [[aug_load_file]]
        shape_info      = [config['input_shape']]
        names           = ['inputs']
    else:
        raise Exception("You can only train ncsn and pixelcnn with this script")

    train_pipe = pipe.create_pipe(parts_funcs,
                        source=train_files,
                        buffer_size=config['num_prepare'],
                        batch_size=config['batch_size']*config['nr_gpu'],
                        shape_info=shape_info, names=names)

    test_pipe  = pipe.create_pipe(parts_funcs, test_files,
                                buffer_size=config['num_prepare'],
                                batch_size = config['batch_size']*config['nr_gpu'],
                                shape_info=shape_info, names=names)

    go = worker(train_pipe, test_pipe, config)
    utils.log_to(os.path.join(go.log_path, 'config.yaml'), [utils.get_timestamp(), "The training is starting"], prefix="#")
    go.train()
    utils.log_to(os.path.join(go.log_path, 'config.yaml'), [utils.get_timestamp(), "The training is ending"], prefix="#")
    utils.color_print('TRAINING FINISHED')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--config', metavar='path', default='config file for training', help='')

    args = parser.parse_args()
    main(args.config)