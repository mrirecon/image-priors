#!/bin/bash

set -e 

export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=3
export DEBUG_DEVEL=1

if [[ -z "${WORKSPACE}" ]]; then
    WORKSPACE=/home/gluo/workspace/nlinv_prior/results/mprage/redu
else
    echo "The variable WORKSPACE exists"
fi
echo "Working in the folder $WORKSPACE"

#
acc=3
vcc=10
pics_lambda=4
nlinv_lambda=5
reg_iter=4
gs_step=11
redu=3

folder=redu_${redu}_${nlinv_lambda}_$acc
mkdir -p $WORKSPACE/$folder
cd $WORKSPACE/$folder

dat=/home/ague/archive/vol/2023-02-17_MRT5_DCRD_0015/meas_MID00020_FID75992_t1_mprage_tra_p2_iso.dat 
GRAPH1=/home/gluo/workspace/nlinv_prior/logs/exported/pixelcnn_abide
GRAPH2=/home/gluo/workspace/nlinv_prior/logs/exported/pixelcnn_abide_filtered
GRAPH3=/home/gluo/workspace/nlinv_prior/logs/exported/pixelcnn_hku


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
bart fmac mask kdat_xy kdat_xy_u

pics()
{
    bart pics -g -i80 -R TF:{$1}:$pics_lambda slice slice_coils $3_pics_$2
}

nlinv()
{
    bart nlinv -g -a660 -b44 -i$gs_step -C50 -r$redu --reg-iter=$reg_iter -R LP:{$1}:$nlinv_lambda:1 slice $3_nlinv_$2 $3_nlinv_coils_$2
}

for num in $(seq 70 150)
do
bart slice 2 $num kdat_xy_u slice
bart ecalib -r 20 -m1 -c 0.001 slice slice_coils

# pics
bart pics -g -l1 -r 0.02 slice slice_coils l1_pics_$num
bart pics -g -l2 -r 0.02 slice slice_coils l2_pics_$num
pics $GRAPH1 $num abide
pics $GRAPH2 $num abide_filtered
pics $GRAPH3 $num hku

# nlinv
bart nlinv -g -a660 -b44 -i10 -r$redu slice l2_nlinv_$num l2_nlinv_coils_$num
bart nlinv -g -a660 -b44 -i$gs_step -C50 -r$redu --reg-iter=$reg_iter -R W:3:0:0.1 slice l1_nlinv_$num l1_nlinv_coils_$num
nlinv $GRAPH1 $num abide
nlinv $GRAPH2 $num abide_filtered
nlinv $GRAPH3 $num hku
done

# expect the worst reconstruction without any prior knowledge
bart fft -i $(bart bitmask 0 1) kdat_xy_u cimgs
bart rss $(bart bitmask 3) cimgs zero_filled
bart extract 2 70 151 zero_filled czero_filled

# expect the best reconstruction from the most k-space data using pics
bart ecalib -r 20 -m1 ckdat_256 coils
bart pics -g -l1 -r 0.02 ckdat_256 coils volume
bart extract 2 70 151 volume cvolume

# expect the best reconstruction from the most k-space data using nlinv
for num in $(seq 70 150)
do
bart slice 2 $num kdat_xy slice
bart nlinv -g -a660 -b44 -i$gs_step -C50 -r$redu --reg-iter=$reg_iter -R W:3:0:0.1 slice nlinv_$num nlinv_coils_$num
done

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


concatenate abide_pics
concatenate abide_filtered_pics
concatenate hku_pics
concatenate l1_pics
concatenate l2_pics
concatenate abide_nlinv
concatenate abide_filtered_nlinv
concatenate hku_nlinv
concatenate l2_nlinv
concatenate l1_nlinv
concatenate nlinv
