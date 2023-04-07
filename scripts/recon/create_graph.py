#

# ----------
# This script is to export tf graphs that will be used as regularization
# for image reconstruction. The kspace data were acquired with different
# sequence and scanner. Due to this, the cropping and resizing of images
# are necessary before fed into the pre-trained network in most cases!
# ----------

from spreco.exporter import exporter
import tensorflow.compat.v1 as tf
tf.disable_eager_execution()

import sys
import numpy as np

total      = int(sys.argv[1])
batches    = int(sys.argv[2])
batch_size = int(sys.argv[3]) 
log        = sys.argv[4]
meta       = sys.argv[5]
path       = sys.argv[6]
name       = sys.argv[7]
prior      = sys.argv[8]
sigm       = sys.argv[9]
seq        = sys.argv[10]

assert batches*batch_size == total 

## sequence -> t1_mprage_tra_p2_iso

if seq == 'MPRAGE':
    x = tf.placeholder(tf.float32, shape=[total, 282, 256, 2], name="input_0")
    t = tf.placeholder(tf.float32, shape=[1], name="input_1")
    if prior == 'SDE':
        m = tf.placeholder(tf.float32, shape=[1], name="input_2")

    split_axis = 0
    splits     = tf.split(x, batches, axis=0)

    def resize_or_pad(xs):

        x_mag      = tf.math.sqrt(tf.math.reduce_sum(tf.math.square(xs), axis=(3), keepdims=True))
        x_mag_max  = tf.math.reduce_max(x_mag, axis=(1,2), keepdims=True)
        x_normed   = xs/(x_mag_max+1e-10)
        x_resize   = tf.image.resize_with_crop_or_pad(x_normed, 256, 256)
        return x_resize, x_mag_max

    def update(x):

        if prior == 'SDE':
            diffusion = e.model.sde(x, t, e.model.config['sigma_type'])[1]
            d_score   = e.model.score(x, t, e.model.config['sigma_type']) * diffusion**2
            x_updated = x + m*d_score
        
        if prior == 'PIXELCNN':

            logits = e.model.eval(x)
            loss   = e.model.loss_func(x, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])
            grad    = tf.squeeze(tf.gradients(loss, x)) 
            x_updated = x - t*grad

        return x_updated


    def resize_or_pad_T(sx, scale):
        x_resize_T   = tf.image.resize_with_crop_or_pad(sx, 282, 256)
        x_normed_T   = x_resize_T*(scale+1e-10)
        return x_normed_T

## squence -> t1_tfl3d_ns_sag_TI900_FA9

if seq == 'TFL3D':

    x = tf.placeholder(tf.float32, shape=[176, 256, total, 2], name="input_0")
    t = tf.placeholder(tf.float32, shape=[1], name="input_1")
    if prior == 'SDE':
        m = tf.placeholder(tf.float32, shape=[1], name="input_2")

    split_axis = 2
    splits     = tf.split(x, batches, axis=split_axis)

    def resize_or_pad(xs):

        x_permuted = tf.transpose(xs, perm=[2, 0, 1, 3])
        x_mag      = tf.math.sqrt(tf.math.reduce_sum(tf.math.square(x_permuted), axis=(3), keepdims=True))

        x_mag_max  = tf.math.reduce_max(x_mag, axis=(1,2), keepdims=True)
        x_normed   = x_permuted/(x_mag_max+1e-10)
        x_resize   = tf.random.normal([batch_size,256,256,2])*0.001 + tf.image.resize_with_crop_or_pad(x_normed, 256, 256)
        return x_resize, x_mag_max

    def update(x):
        if prior == 'SDE':
            diffusion = e.model.sde(x, t, e.model.config['sigma_type'])[1]
            d_score   = e.model.score(x, t, e.model.config['sigma_type']) * diffusion**2
            x_updated = x + m*d_score
        
        if prior == 'PIXELCNN':

            logits = e.model.eval(x)
            loss   = e.model.loss_func(x, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])
            grad    = tf.squeeze(tf.gradients(loss, x)) 
            x_updated = x - t*grad

        return x_updated

    def resize_or_pad_T(sx, scale):
        x_resize_T   = tf.image.resize_with_crop_or_pad(sx, 176, 256)
        x_normed_T   = x_resize_T*(scale+1e-10)
        x_permuted_T = tf.transpose(x_normed_T, perm=[1, 2, 0, 3])
        return x_permuted_T

e = exporter(log, meta, path, name, sigma_type=sigm, default_out=False, sigma_max=0.3, sigma_min=0.01, gpu_id='3')

so = []
def gpu_tower(ss):
    for split in ss:
        x_r, scale  = resize_or_pad(split)
        x_up = update(x_r)
        x_o  = resize_or_pad_T(x_up, scale)
        so.append(x_o)

with tf.device('/gpu:0'):
    gpu_tower(splits)

with tf.device('/gpu:0'):
    x_out = tf.concat(so, axis=split_axis)

assert x_out.shape == x.shape
e.export([x, t, m] if prior == 'SDE' else [x, t], [x_out])