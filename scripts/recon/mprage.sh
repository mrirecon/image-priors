#!/bin/bash
set -e 

export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_CPP_MIN_LOG_LEVEL=3
export TF_NUM_INTEROP_THREADS=10
export TF_NUM_INTRAOP_THREADS=10
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=3
export DEBUG_DEVEL=1


WORKSPACE=$(pwd)/../../results
echo "Working in the folder $WORKSPACE"
ROOT_PATH=$(pwd)

mkdir -p $WORKSPACE/3D
cd $WORKSPACE/3D

dat=/home/ague/archive/vol/2023-02-17_MRT5_DCRD_0015/meas_MID00020_FID75992_t1_mprage_tra_p2_iso.dat 

# read dat file
# and restore the normal grid and remove oversampling
if [ ! -f kdat.cfl ]; then
    
    bart twixread -A $dat kdat
    bart zeros 4 108 282 224 16 tmp
    bart join 0 tmp kdat kdat_
    bart reshape $(bart bitmask 0 4) 2 256 kdat_ tmp
    bart avg $(bart bitmask 0) tmp kdat__
    bart transpose 0 4 kdat__ kdat_

    bart poisson -Y282 -Z224 -y1.2 -z1.2 -v -C25 mask
    bart fmac mask kdat_ kdat_u

    bart ecalib -r 25 -c 0.00001 -m1 kdat_u coils

    bart fft -i $(bart bitmask 0 1 2) kdat_ coil_imgs
    bart rss $(bart bitmask 3) coil_imgs rss
    bart fmac -C -s $(bart bitmask 3) coil_imgs coils coil_comb
    bart pics -g -d4 -l1 -r0.01 -i100 kdat_u coils l1_pics
    bart pics -g -d4 -l1 -r0.01 -i100 kdat_ coils l1_pics_all
fi

models_folder=$ROOT_PATH/MRI-Image-Priors/Diffusion
EXPR=$ROOT_PATH/3d_graph.py
total=224
batches=1
batch_size=224
log=$models_folder/SMLD
meta=smld
path=$models_folder/exported

export_graph()
{
python $EXPR $total $batches $batch_size $log $meta $path $1 $2 $1 MPRAGE
}

declare -a types=("log" "linear")
for type in "${types[@]}"
do
    export_graph $type SDE
    GRAPH=$path/$type
    bart pics -g -d4 -R DP:{$GRAPH}:0.15:50 -i50 kdat_u coils dp_pics_$type
done