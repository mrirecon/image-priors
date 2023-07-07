## Image reconstruction with priors

Congrats 😃, you get to the final step. Before performing the reconstruction task, make sure you have installed [bart](https://github.com/mrirecon/bart) toolbox properly with TensorFlow graph support.
We prepare a [tutorial](https://github.com/mrirecon/bart-workshop/tree/master/ismrm2021) to present how to create a regularization term with TensorFlow and use it for image reconstruction in BART.

Basically, we have two main steps to improve reconstruction with your priors. Firstly, export your trained model for BART; then, use `pics` or `nlinv` command in BART.



