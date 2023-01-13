#!/bin/bash

set -e 

export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_VISIBLE_DEVICES=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=0

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

GRAPH=$ROOT_PATH/logs/exported/pixelcnn_abide
DATA_PATH=$ROOT_PATH/data/kspaces/mprage
#GRAPH=/home/gluo/workspace/nlinv/logs/exported/pixelcnn_hku
#GRAPH=/home/gluo/workspace/nlinv/logs/exported/pixelcnn_abide_filtered
#DATA_PATH=/home/gluo/workspace/nlinv/scripts/data/kspace

mkdir -p $ROOT_PATH/results/$PATTERN
cd $ROOT_PATH/results/$PATTERN

if [ $PATTERN == po ]; then
    bart poisson -Y$nx -Z$ny -y1.5 -z1.5 -v -s 1000 -C$cal mask
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

bart pics -g -l1 -r 0.01 und_kspace coilsen l1_pics
bart pics -g -i100 -d4 -R TF:{$GRAPH}:0.8 und_kspace coilsen prior_pics

bart nlinv -g -d4 -a660 -b44 -i14 -C50 und_kspace nlinv nlinv_coils
bart nlinv -g -d4 -a660 -b44 -i15 -C50 --reg-iter=5 -R W:3:0:0.1 und_kspace l1_nlinv l1_nlinv_coils
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=5 -R LP:{$GRAPH}:0.8:1:1 und_kspace prior_nlinv prior_nlinv_coils