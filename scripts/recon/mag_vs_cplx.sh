#!/bin/bash
# compare priors that are trained on different datasets

set -e 

export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=3

if [[ -z "${ROOT_PATH}" ]]; then
    ROOT_PATH=/home/gluo/workspace/nlinv_prior
    echo "Using the root path set by this shell script"
else
    echo "Working in the folder $ROOT_PATH"
fi

# variables for sampling patter
nx=256
ny=256
cal=15
fx=3
fy=2
ratio=5

read -p 'Select undersampling pattern.
         1d is 1d pattern,
         2d is 2d pattern,
         po is poisson disc [1d]: ' PATTERN
PATTERN=${PATTERN:-1d}


DATA_PATH=$ROOT_PATH/data/kspaces/mprage

mkdir -p $ROOT_PATH/results/mag/$PATTERN
cd $ROOT_PATH/results/mag/$PATTERN

if [ $PATTERN == po ]; then
    bart poisson -Y$nx -Z$ny -y1.5 -z1.5 -v -s 1000 -C$(($cal*2)) mask
    bart transpose 0 1 mask mask
    bart transpose 1 2 mask mask
fi

if [ $PATTERN == 2d ]; then
    bart upat -Y$nx -Z $ny -y $fx -z$fy -c$cal mask
    bart transpose 0 1 mask mask
    bart transpose 1 2 mask mask
fi

if [ $PATTERN == 1d ]; then
    bart upat -Y $ny -Z 1 -y $ratio -z 1 -c$cal mask
    bart repmat 0 $nx mask mask
fi

bart fmac mask $DATA_PATH und_kspace
bart ecalib -r20 -m1 -c0.001 und_kspace coilsen
bart fft -i 3 $DATA_PATH coilimgs
bart fmac -C -s$(bart bitmask 3) coilimgs coilsen grd

bart fft -i 3 und_kspace coilimgs
bart fmac -C -s$(bart bitmask 3) coilimgs coilsen zero_filled

bart pics -g -l2 -r 0.01 und_kspace coilsen l2_pics
bart pics -g -l1 -r 0.01 und_kspace coilsen l1_pics

bart nlinv -g $DATA_PATH nlinv_grd
bart nlinv -g und_kspace zero_filled_nlinv

EXPR=/home/gluo/workspace/nlinv_prior/scripts/recon/2d_pixelcnn.py
log=/home/gluo/workspace/nlinv_prior/logs/20230522-161113
meta=pixelcnn_500
path=/home/gluo/workspace/nlinv_prior/logs/exported/test
name=pixelcnn_mag
python $EXPR $log $meta $path $name PIXELCNN none 2DMAG
bart pics -g -i100 -d5 -R TF:{$path/$name}:0.1 und_kspace coilsen prior_pics_mag
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=3 -R LP:{$path/$name}:0.5:1 und_kspace prior_nlinv_mag prior_nlinv_mag_coils

log=/home/gluo/workspace/nlinv_prior/logs/pixelcnn_hku
meta=pixelcnn_500
path=/home/gluo/workspace/nlinv_prior/logs/exported/test
name=pixelcnn_cplx
python $EXPR $log $meta $path $name PIXELCNN none 2DCPLX
bart pics -g -i100 -d5 -R TF:{$path/$name}:0.6 und_kspace coilsen prior_pics_cplx
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=3 -R LP:{$path/$name}:0.5:1 und_kspace prior_nlinv_cplx prior_nlinv_cplx_coils