#!/bin/sh

path=/home/ague/data/gluo/dataset/abide_2/train
pattern="abide_*.hdr"
filelist=/tmp/filelist
train_list=/tmp/train
test_list=/tmp/test

#find $path -name $pattern | grep -v "mag_re" | sort > $filelist

nr_files=$(cat $tmp | wc -l)

ratio=0.9
nr_train_file=$(echo "scale=4; $nr_files*$ratio" | bc -l)
nr_train_file=${nr_train_file%.*}
nr_test_file=$((nr_files-nr_train_file))

head -n$nr_train_file $tmp > $train_list
tail -n$nr_test_file $tmp > $test_list

python train_prior.py --config=sde.yaml