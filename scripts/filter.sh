#!/bin/bash

# this program helps you manually kick out images of lower quality

set -e

root_path=/home/jason/gluo_remote/workspace
file_root=/media/radon_ague/data/gluo/dataset/abide_2/train
filelist=$root_path/nlinv_prior/data/abide/abide_train_p
view_config=$root_path/nlinv_prior/scripts/configs/view_config
out=$root_path/nlinv_prior/data/abide/abide_train_p_filtered_

for i in $(seq 1 20000)
do
    file=$(sed -n "${i}p" $filelist)
    base_name=$(basename ${file})
    view -l $view_config $file_root/$base_name
    read -p "Good or Bad [Y]: " value
    value=${value:-Y}
    echo $value
    if [ ${value} == "Y" ]; then
        echo $file >> $out
    fi
done
