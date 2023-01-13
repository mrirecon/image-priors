# Recipe for a prior

use env neue on curie with spreco (vq-x)

1. Where is your training data, and how do you preprocess it?

    The training data is from the Autism Brain Imaging Data Exchange [(ABIDE)](https://fcon_1000.projects.nitrc.org/indi/abide/), we downloaded it and saved it under the path /home/ague/data/gluo/ABIDE. The preprocessing contains procedures to resample the image to a specified size, add background noise, normalize it to maximum, and save it in 'npz' format. The dataset comes in volumes. We turned it into slices with ID numbers after preprocessing, and some slices with no content were thrown away. Use `preprocess.py` to finished these procedures.
2. How do you do the phase augmentation for phase-loss images?

    Images from ABIDE come with only magnitude parts. A reversed diffusion process is used to generate complex images that are conditional on those magnitude parts. Given a set of images ${\mathbf{m}_i}$ that only have the magnitude part, we use a diffussion process to generate complex images $\mathbf{c}_i$ conditioning on the magnitude images. The diffussion prior is trained with complex images $\mathbf{x}_i$.

    $$p(\mathbf{c}|\mathbf{m}) \propto p(\mathbf{c}) \cdot p(\mathbf{m}|\mathbf{c})$$

    and we have

    $$\mathbf{m}=\sqrt{\mathbf{c}_r^2 + \mathbf{c}_i^2 }$$
    To complete this step, use `aug_phase.sh` and provide it with the config file and a list of magnitude parts. This script run the `runner` program to augment phase in parallel. The runner program uses `augment_phase.py` to finish this augmentation process.
3. How to train a PixelCNN prior with the augmented images?

    PixelCNN is an autoregressive model for image representation, and we implement it in 'spreco' lib. To train it, run the program `train_prior.py` and provide it with a config file. The config file contains the necessary hyperparamters used for training and the location of training data.

4. How to use the trained prior as a regularization term in BART?

    The `pics` command in BART has an option for loading an exported computation graph and using it as a regularization. To export a trained model for BART, run the program `export.py` and provide required arguments for it, including the location of the trained model and the destination for export.
