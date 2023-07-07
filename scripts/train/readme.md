## Train generative priors

Use [train.sh](train.sh) to train your generative priors. Before that, please prepare a list of files like below for your dataset. This dataset contains the complex images that are obtained after phase augmentation.

```txt
../abide_2/train/abide_1000000.hdr
../abide_2/train/abide_1000001.hdr
../abide_2/train/abide_1000002.hdr
../abide_2/train/abide_1000003.hdr
```

The command [find](https://linuxize.com/post/how-to-find-files-in-linux-using-the-command-line/) could help you to create such a list of files.

```shell
folder=/path/to/folder/that/contains/complex/images
pattern="abide_*.hdr"
find $path -name $pattern | sort > /path/to/filelist
```

Then go to the [config file](../configs/sde.yaml) and check following things.

1. specify where to save the trained models with `log_folder`
2. if the variables `train_list` and `test_list` are modified in `train.sh`, please change it in the config file as well
3. specify the number of GPU available with `nr_gpu` and `gpu_id`
4. please go to [spreco](https://github.com/mrirecon/spreco) for the information on the other configurations