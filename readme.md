# Using a learned generative prior as regularization for nonlinear MRI reconstruction

# Recipe
1. preprocess the data
    ```shell
    python preprocess.py --folder=/home/ague/data/gluo/ABIDE --savepath=/home/ague/data/gluo/dataset/abide_2/magnitude
    ```

2. prepare training data
   ```shell
   bash aug_phase.sh
   ```

3. train priors
   ```shell
   python train_prior.py --config=configs/pixelcnn_abide.yaml
   ```

4. export priors
   ```shell
   python export.py --folder=xxx --model_name=xxx --exported_folder=xxx --exported_name=xxx
   ```

5. reconstruct image using priors, see mprage.sh for details
   ```
   bart nlinv -R LP:prior:lambda kspace reco
   bart pics -R TF:prior:lambda kspace coils reco
   ```

## TODOs

- [ ] provide a figure to show the overview of the concept and idea behind this work
- [ ] provide a figure to show the improvement in the image quality as a result of using diffusion prior for phase augmentation
- [ ] provide a figure show the convergence of the proposed algorithm and phase maps
- [ ] provide a figure to compare the performance of different priors
- [ ] provide a figure to show the results for cross-domain validation for the different priors and how it demonstrates the property of a learnt prior
- [ ] use bart_tf.py to export graph