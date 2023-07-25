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
cplx       = sys.argv[7]
cplx       = cplx.split('_')[0]

e = exporter(log, meta, path, name, sigma_type=sigm, default_out=False, sigma_max=0.3, sigma_min=0.01, gpu_id='3')

if prior == 'PixelCNN':

    if cplx == 'mag':

        x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")

        x_cplx = tf.complex(x[..., 0], x[..., 1])
        x_mag  = tf.abs(x_cplx)[..., tf.newaxis]

        logits = e.model.eval(x_mag)
        loss   = e.model.loss_func(x_mag, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])



    elif cplx == 'cplx':

        x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")

        logits = e.model.eval(x)
        loss   = e.model.loss_func(x, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])
    
    else:
        ValueError("check your name in the table")


    e.export([x], [loss], attach_gradients=True)

elif prior == 'SMLD':
    
    x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")
    t = tf.placeholder(tf.float32, shape=[1], name="input_1")
    m = tf.placeholder(tf.float32, shape=[1], name="input_2")

    diffusion = e.model.sde(x, t, e.model.config['sigma_type'])[1]
    d_score   = e.model.score(x, t, e.model.config['sigma_type']) * diffusion**2
    
    x_updated = x + m*d_score
    e.export([x, t, m], [x_updated])
    
else:
    ValueError("check your prior type")