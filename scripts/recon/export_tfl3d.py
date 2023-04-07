from spreco.exporter import exporter
import tensorflow.compat.v1 as tf
tf.disable_eager_execution()

import sys


total      = int(sys.argv[1])
batches    = int(sys.argv[2])
batch_size = int(sys.argv[3]) 
sigm       = sys.argv[4]
log        = sys.argv[5]
meta       = sys.argv[6]
path       = sys.argv[7]
name       = sys.argv[8]

assert batches*batch_size == total 

x = tf.placeholder(tf.float32, shape=[176, 256, total, 2], name="input_0")
t = tf.placeholder(tf.float32, shape=[1], name="input_1")
m = tf.placeholder(tf.float32, shape=[1], name="input_2")

splits = tf.split(x, batches, axis=2)

def resize_or_pad(xs):

    x_permuted = tf.transpose(xs, perm=[2, 0, 1, 3])
    x_mag      = tf.math.sqrt(tf.math.reduce_sum(tf.math.square(x_permuted), axis=(3), keepdims=True))

    x_mag_max  = tf.math.reduce_max(x_mag, axis=(1,2), keepdims=True)
    x_normed   = x_permuted/(x_mag_max+1e-10)
    x_resize   = tf.random.normal([batch_size,256,256,2])*0.001 + tf.image.resize_with_crop_or_pad(x_normed, 256, 256)
    return x_resize, x_mag_max

def update(x):
    diffusion = e.model.sde(x, t, e.model.config['sigma_type'])[1]
    d_score   = e.model.score(x, t, e.model.config['sigma_type']) * diffusion**2
    x_updated = x + m*d_score
    return x_updated


def resize_or_pad_T(sx, scale):
    x_resize_T   = tf.image.resize_with_crop_or_pad(sx, 176, 256)
    x_normed_T   = x_resize_T*(scale+1e-10)
    x_permuted_T = tf.transpose(x_normed_T, perm=[1, 2, 0, 3])
    return x_permuted_T

e = exporter(log, meta, path, name, sigm, default_out=False, sigma_max=0.3, sigma_min=0.01)

so = []
for split in splits:
    x_r, scale  = resize_or_pad(split)
    x_up = update(x_r)
    x_o  = resize_or_pad_T(x_up, scale)
    so.append(x_o)

x_out = tf.concat(so, axis=2)

assert x_out.shape == x.shape

e.export([x, t, m], [x_out])
