# Copyright 2023. Uecker Lab. University Medical Center Göttingen.
# All rights reserved.

# Authors:
# Guanxiong Luo

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

log        = sys.argv[1]
meta       = sys.argv[2]
path       = sys.argv[3]
name       = sys.argv[4]
prior      = sys.argv[5]
sigm       = sys.argv[6]
seq        = sys.argv[7]


e = exporter(log, meta, path, name, sigma_type=sigm, default_out=False, sigma_max=0.3, sigma_min=0.01, gpu_id='3')

if seq == '2DMAG':

    x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")
    t = tf.placeholder(tf.float32, shape=[1], name="input_1")
    if prior == 'SDE' or prior == 'SDE2':
        m = tf.placeholder(tf.float32, shape=[1], name="input_2")

    #x_mag      = tf.math.sqrt(tf.math.reduce_sum(tf.math.square(x), axis=(3), keepdims=True))
    #x_mag_max  = tf.math.reduce_max(x_mag, axis=(1,2), keepdims=True)
    x_cplx = tf.complex(x[..., 0], x[..., 1])
    x_mag  = tf.abs(x_cplx)[..., tf.newaxis]
    #x_mag_normed   = x_mag/(x_mag_max+1e-10)
    #x_cplx_normed  = tf.concat([x_mag_normed*tf.cos(x_angle), x_mag_normed*tf.sin(x_angle)], axis=-1)

    logits = e.model.eval(x_mag)
    loss   = e.model.loss_func(x_mag, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])
    grad   = tf.squeeze(tf.gradients(loss, x))[tf.newaxis, ...]

    x_out = x - t*grad



if seq == '2DCPLX':

    x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")
    t = tf.placeholder(tf.float32, shape=[1], name="input_1")
    if prior == 'SDE' or prior == 'SDE2':
        m = tf.placeholder(tf.float32, shape=[1], name="input_2")

    cplx_x = tf.complex(x[..., 0], x[..., 1])
    x_mag  = tf.abs(cplx_x)[..., tf.newaxis]
    x_mag_max  = tf.math.reduce_max(x_mag, axis=(1,2), keepdims=True)
    x_normed  = x/(x_mag_max+1e-16)

    logits = e.model.eval(x_normed)
    loss   = e.model.loss_func(x_normed, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])
    grad    = tf.squeeze(tf.gradients(loss, x_normed))[tf.newaxis, ...]
    x_updated = x_normed - t*grad

    x_out = x_updated*(x_mag_max+1e-16)

assert x_out.shape == x.shape
e.export([x, t, m] if prior == 'SDE' or prior == 'SDE2' else [x, t], [x_out])