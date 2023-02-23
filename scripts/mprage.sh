#!/bin/bash

set -e 

export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=3

if [[ -z "${ROOT_PATH}" ]]; then
    ROOT_PATH=/home/gluo/workspace/nlinv_prior
    echo "Using the root path set by this shell script"
else
    echo "Working in the folder $ROOT_PATH"
fi

#
acc=2
vcc=10
pics_lambda=4
nlinv_lambda=5
reg_iter=4
gs_step=11
mkdir -p $ROOT_PATH/results/mprage/$acc
cd $ROOT_PATH/results/mprage/$acc

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
    bart resize -c 1 256 kdat_ kdat_256
    bart cc -p $vcc kdat_256 ckdat_256
    bart fft -i $(bart bitmask 2) ckdat_256 kdat_xy
    rm tmp.* kdat__.* kdat_.* kdat_256.*
fi

bart upat -Y256 -Z256 -y$acc -z2 -c30 mask
bart transpose 0 1 mask mask
bart transpose 1 2 mask mask

GRAPH1=$ROOT_PATH/logs/exported/pixelcnn_abide
GRAPH2=$ROOT_PATH/logs/exported/pixelcnn_abide_filtered
GRAPH3=$ROOT_PATH/logs/exported/pixelcnn_hku

pics()
{
    bart pics -g -i80 -d4 -R TF:{$1}:$pics_lambda slice slice_coils $3_pics_$2
}

nlinv()
{
    bart nlinv -g -d4 -a660 -b44 -i$gs_step -C50 -r3 --reg-iter=$reg_iter -R LP:{$1}:$nlinv_lambda:1 slice $3_nlinv_$2 $3_nlinv_coils_$2
}

for num in $(seq 70 150)
do
bart slice 2 $num kdat_xy slice_
bart ecalib -r 20 -m1 -c 0.001 slice_ slice_coils
bart fmac mask slice_ slice

# pics
bart pics -g -l1 -r 0.02 slice slice_coils l1_pics_$num
pics $GRAPH1 $num abide
pics $GRAPH2 $num abide_filtered
pics $GRAPH3 $num hku

# nlinv
bart nlinv -g -d4 -a660 -b44 -i10 -r2.2 slice nlinv_$num nlinv_coils_$num
nlinv $GRAPH1 $num abide
nlinv $GRAPH2 $num abide_filtered
nlinv $GRAPH3 $num hku
done

bart ecalib -r 20 -m1 -c 0.001 ckdat_256 coils
bart pics -g -l1 -r 0.02 ckdat_256 coils volume

bart fft -i $(bart bitmask 0 1) kdat_xy cimgs
bart rss $(bart bitmask 3) cimgs zero_filled

# concatenate slices
concatenate()
{
s1=""
for num in $(seq 70 150)
do
    s1=$s1$1_$num" "
done
bart join 2 $s1 $1_volume
}

concatenate abide_nlinv
concatenate abide_filtered_nlinv
concatenate hku_nlinv
concatenate abide_pics
concatenate abide_filtered_pics
concatenate hku_pics
concatenate l1_pics
concatenate nlinv