#!/bin/sh
set -e
export LIBRARY_PATH=$LIBRARY_PATH:/home/gluo/local_lib/1.x
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/gluo/local_lib/1.x
export TF_CPP_MIN_LOG_LEVEL=3

TOOLBOX_PATH=~/bart
export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
    echo '$TOOLBOX_PATH is not set correctly'
    exit 1
fi

RES_PATH=/home/gluo/nlinv_prior

if [ ! -e $RES_PATH ] ; then
    mkdir $RES_PATH
fi

nx=256
ny=256
cal=20

DATA_PATH=/home/ague/data/gluo/dataset/brain_mat/test/hku_100000
bart fft -i $(bart bitmask 0 1) $DATA_PATH coils
bart rss $(bart bitmask 3) coils rss

#generate sampling mask
#python gen_mask.py mask_2d_equal 2d 2 3 $cal $nx $ny
#python gen_mask.py mask 2d 0.15 $cal $nx $ny
python gen_mask.py mask 1d 0.2 $cal $nx $ny
bart fmac mask $DATA_PATH und_kspace

bart fft -i $(bart bitmask 0 1) und_kspace zero_filled
bart rss $(bart bitmask 3) zero_filled zero_filled_rss

#bart ecalib -r$cal -m1 -c0.0001 und_kspace coilsen

#bart pics -d5 -l1 -r 0.01 und_kspace coilsen l1_recon

bart nlinv -i8 -d5 und_kspace nlinv_recon nlinv_recon_coils

#bart nlinv -A -a 660 -b44 -i8 -l1 -e 0.03 -r2 -d5 -C30 und_kspace l1_nlinv_recon_admm l1_nlinv_recon_coils_admm
bart nlinv -a 660 -b44 -i10 -l1 -e 0.01 -r3 -d5 -C50 und_kspace l1_nlinv_recon_fista l1_nlinv_recon_coils_fista

graph_path=/home/ague/archive/projects/2021/gluo/prior/pixel_cnn

bart nlinv -i12 -R LP:{$graph_path}:5:0.7:1:256 -r3.5 -d5 -C30 -y0.5 und_kspace prior_recon prior_recon_coils

rho=1

#bart nlinv -A -i8 -r2 -d5 -C40 und_kspace prior_recon_admm prior_recon_coils_admm
#bart nlinv -A -i8 -u $rho -R LP:{$graph_path}:4:0.65:1:256 -r3.5 -d5 -C30 und_kspace prior_recon_admm prior_recon_coils_admm
#python gen_mask.py mask_2d_random 2d 0.2 $cal $nx $ny
#python gen_mask.py mask_1d_random 1d 0.2 $cal $nx $ny
#python gen_mask.py mask_1d_equal 1d 2 $cal $nx $ny