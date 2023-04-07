#!/bin/bash
set -e 

export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_CPP_MIN_LOG_LEVEL=3
export TF_NUM_INTEROP_THREADS=10
export TF_NUM_INTRAOP_THREADS=10
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=2
export DEBUG_DEVEL=1

if [[ -z "${WORKSPACE}" ]]; then
    WORKSPACE=/scratch_radon/gluo/umg
    mkdir -p $WORKSPACE
else
    echo "The variable WORKSPACE exists"
    mkdir -p $WORKSPACE
fi

echo "Working in the folder $WORKSPACE"
cd $WORKSPACE

## load and prepare k-space
dat=/storage/MRT4/BIGDATA/BIGDATA#SMRT4#F39037#M45#D170323#T103009#UE01_t1_tfl3d_ns_sag_TI900_FA9_.dat
vcc=64

if [ ! -f kdat.cfl ] ; then
    : '
    bart twixread -A $dat kdat
    bart reshape $(bart bitmask 0 4) 2 256 kdat tmp
    bart avg $(bart bitmask 0) tmp kdat__
    bart transpose 0 4 kdat__ kdat_
    '
    #bart cc -p $vcc kdat_ ckdat
    #bart cc -p $vcc kdat_u ckdat_u
    bart fft -i $(bart bitmask 0 1 2) kdat_ coil_imgs
    bart rss $(bart bitmask 3) coil_imgs rss

    bart poisson -Y256 -Z176 -v -y1.2 -z1.2 -C25 mask
    bart fmac mask kdat_ kdat_u
    bart ecalib -r 25 -c 0.00001 -m1 kdat_u coils
    bart fmac -C -s $(bart bitmask 3) coil_imgs coils coil_comb
    bart pics -g -d4 -l1 -r0.01 -i100 kdat_u coils l1_pics
  
fi

EXPR=/home/gluo/workspace/nlinv_prior/scripts/recon/create_graph.py
total=256
batches=4
batch_size=64
log=/home/gluo/workspace/nlinv_prior/logs/20230331-145248
meta=sde_abide_50
path=/home/gluo/workspace/nlinv_prior/logs/exported/test

export_graph()
{
python $EXPR $total $batches $batch_size $log $meta $path $1 $2 $1 TFL3D
}

#declare -a types=("log" "quad" "linear" "sqrt" "exp")
declare -a types=("log" "quad" "linear")

for type in "${types[@]}"
do
    export_graph  $type SDE
    GRAPH=$path/$type
    bart pics -g -d4 -R DP:{$GRAPH}:0.4:60 -i60 kdat_u coils dp_pics_$type
done