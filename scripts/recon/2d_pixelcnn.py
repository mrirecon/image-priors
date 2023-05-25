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

    x_cplx = tf.complex(x[..., 0], x[..., 1])
    x_mag  = tf.abs(x_cplx)[..., tf.newaxis]

    logits = e.model.eval(x_mag)
    loss   = e.model.loss_func(x_mag, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])



if seq == '2DCPLX':

    x = tf.placeholder(tf.float32, shape=[1, 256, 256, 2], name="input_0")

    logits = e.model.eval(x)
    loss   = e.model.loss_func(x, logits) / np.log(2.0) / np.prod(e.model.config['input_shape'])


e.export([x], [loss], attach_gradients=True)