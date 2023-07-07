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

Then use program `aug_phase.sh` to start augmentation tasks. Before that, please check if the following things are correct

1. `model_folder` in scripts/configs/phase_abide.yaml
2. `model_name` in scripts/configs/phase_abide.yaml
3. `save_path` in scripts/configs/phase_abide.yaml
4. `FILELIST` in scripts/augmentation/aug_phase.sh


