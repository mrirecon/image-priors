#!/bin/bash
# compare priors that are trained on different datasets

set -e 

export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=3

if [[ -z "${ROOT_PATH}" ]]; then
    ROOT_PATH=$(pwd)/../..
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


DATA_PATH=$ROOT_PATH/misc/kspace/mprage

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
bart pics -g -l2 -r 0.01 -S $DATA_PATH coilsen grd

bart fft -i 3 und_kspace coilimgs
bart fmac -C -s$(bart bitmask 3) coilimgs coilsen zero_filled

bart pics -g -S -l2 -r 0.01 und_kspace coilsen l2_pics
bart pics -g -S -l1 -r 0.01 und_kspace coilsen l1_pics

bart nlinv -g -S $DATA_PATH nlinv_grd
bart nlinv -g -S und_kspace zero_filled_nlinv
bart nlinv -g -S -a660 -b44 -i12 -C50 --reg-iter=3 -R W:3:0:0.1 und_kspace l1_nlinv

# where you store the priors
models_folder=$ROOT_PATH/MRI-Image-Priors
mkdir -p $models_folder
cd $models_folder
wget -nc https://zenodo.org/record/8083750/files/PixelCNN.zip
wget -nc https://zenodo.org/record/8083750/files/Diffusion.zip
unzip PixelCNN.zip
unzip Diffusion.zip
cd -
EXPR=$ROOT_PATH/scripts/recon/2d_graph.py

declare -a priors=("cplx_large"  "cplx_small"  "mag_large"  "mag_small")


for prior in "${priors[@]}"
do
    log=$models_folder/PixelCNN/$prior
    meta=pixelcnn
    path=$models_folder/PixelCNN/exported
    name=$prior
    python $EXPR $log $meta $path $name PixelCNN none $prior
    if [ "$prior" = "cplx_large" ] || [ "$prior" = "cplx_small" ]; then
    bart pics -g -S -i100 -d5 -R TF:{$path/$name}:0.6 und_kspace coilsen pics_$prior
    else
    bart pics -g -S -i100 -d5 -R TF:{$path/$name}:0.1 und_kspace coilsen pics_$prior
    fi
    bart nlinv -g -S -d4 -a660 -b44 -i14 -C50 --reg-iter=3 -R TF:{$path/$name}:0.5:1 und_kspace nlinv_$prior nlinv_${prior}_coils
done


prior=SMLD
log=$models_folder/Diffusion/$prior
meta=smld
path=$models_folder/Diffusion/exported
name=$prior
python $EXPR $log $meta $path $name SMLD log $prior
bart pics -g -S -i100 -d5 -R DP:{$path/$name}:0.6:100 und_kspace coilsen pics_$prior
bart nlinv -g -S -d4 -a660 -b44 -i14 -C50 --reg-iter=3 -R DP:{$path/$name}:1:50 und_kspace nlinv_$prior nlinv_${prior}_coils