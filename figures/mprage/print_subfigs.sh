#!/bin/bash

set -ex

crop_and_cnvrt()
{
    tmpfile1=$(mktemp /tmp/abc-script.XXXXXX)
    tmpfile2=$(mktemp /tmp/abc-script.XXXXXX)
    bart extract 2 $3 $(($3 + 1)) $1/$2/$5 $tmpfile1
    bart extract 0 100 150 1 45 185 2 $3 $(($3 + 1)) $1/$2/$5 $tmpfile2
    cfl2png -c $4 $tmpfile1 $6
    cfl2png -c $4 $tmpfile2 $6_crop
}

print()
{
    mkdir -p sub_figs/$2
    cd sub_figs/$2
    crop_and_cnvrt $1 $2 $3 $4 cvolume cvolume
    crop_and_cnvrt $1 $2 $3 $4 abide_pics_volume abide_pics
    crop_and_cnvrt $1 $2 $3 $4 abide_f_pics_volume abide_f_pics
    crop_and_cnvrt $1 $2 $3 $4 hku_pics_volume hku_pics
    crop_and_cnvrt $1 $2 $3 $4 l1_pics_volume l1_pics
    crop_and_cnvrt $1 $2 $3 $4 l2_pics_volume l2_pics
    crop_and_cnvrt $1 $2 $3 $4 abide_nlinv_volume abide_nlinv
    crop_and_cnvrt $1 $2 $3 $4 abide_f_nlinv_volume abide_f_nlinv
    crop_and_cnvrt $1 $2 $3 $4 hku_nlinv_volume hku_nlinv
    crop_and_cnvrt $1 $2 $3 $4 l2_nlinv_volume l2_nlinv
    crop_and_cnvrt $1 $2 $3 $4 l1_nlinv_volume l1_nlinv
    crop_and_cnvrt $1 $2 $3 $4 nlinv_volume nlinv
    cd ../../
}

result_path=/home/ague/archive/projects/2023/gluo/learned_reg
config=/home/gluo/workspace/nlinv_prior/figures/mprage/view_config
config2=/home/gluo/workspace/nlinv_prior/figures/mprage/view_config2
expr=redu_3_5_5_2
slice=45
print $result_path $expr $slice $config2 

expr=redu_3_5_5_3
slice=45
print $result_path $expr $slice $config2