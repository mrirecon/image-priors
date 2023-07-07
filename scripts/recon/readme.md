## Image reconstruction with priors

Congrats 😃, you get to the final step. Before performing the reconstruction task, make sure you have installed [bart](https://github.com/mrirecon/bart) toolbox properly with TensorFlow graph support.
We prepare a [tutorial](https://github.com/mrirecon/bart-workshop/tree/master/ismrm2021) to present how to create a regularization term with TensorFlow and use it for image reconstruction in BART.

If you'd like to have a quick tryout with our priors, you could get priors from this huggingface [page](https://huggingface.co/Guanxiong/MRI-Image-Priors) or [zenodo](https://zenodo.org/record/8083750)

We have two main steps to improve reconstruction with your priors. Firstly, export your trained model as computation graph for BART; then, use `pics` or `nlinv` command in BART with the exported graph as regularization. We provide an [example](2d_example.sh) for 2D reconstruction.

```shell
...

## export graph
log=../../MRI-Image-Priors/PixelCNN/cplx_large  # the folder that has models
meta=pixelcnn  # the name of a model
path=../../MRI-Image-Priors/exported/graph
name=pixelcnn_cplx_large
python 2d_pixelcnn.py $log $meta $path $name PIXELCNN none 2DCPLX
GRAPH=$path/$name

...
...

## perform reconstruction
bart pics -g -i100 -d4 -R TF:{$GRAPH}:0.8 und_kspace coilsen prior_abide_pics
```


