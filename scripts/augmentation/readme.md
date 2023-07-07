## Data preparation

Please go to the webpage for [Autism Brain Imaging Data Exchange (ABIDE)](https://fcon_1000.projects.nitrc.org/indi/abide/) and download the dataset that contains nii files. Before using program `preprocess.py` to preprocess them, make sure you have installed library [spreco](https://github.com/mrirecon/spreco).
```shell
python preprocess.py --folder={the folder contains the nii files} --savepath={where you want to save preprocessed images}
```

## Phase augmentation
Before performing phase augmentation, make sure you have downloaded models from this [zenodo page](https://zenodo.org/record/6521188)
```shell
wget https://zenodo.org/record/6521188/files/models.tar
```
and make sure you create a list of files like below after the data preparation step

```txt
./dataset/abide_2/train/abide_1000000.npz
./dataset/abide_2/train/abide_1000001.npz
./dataset/abide_2/train/abide_1000002.npz
./dataset/abide_2/train/abide_1000003.npz
```

Then use program `aug_phase.sh` to start augmentation tasks. Before that, please check if the following things in [phase_abide.yaml](../configs/phase_abide.yaml) are correct

1. specify where the downloaded model is with `model_folder` 
2. specify which model to use with `model_name` 
3. specify where to save the phase-augmented images with `save_path` 

and the following things in [aug_phase.sh](aug_phase.sh)

1. specify the location of config file with `CONFIG`
2. specify the location of the list of files with `FILELIST`
3. the [runner](runner) can parallelize your jobs, specify the number of GPU available with `NUM_GPUS` and `GPU_IDS`
4. if your GPU has a not sufficient memory, reduce `FILE_BATCHES`
5. specify your tmp_list with `TMP`
