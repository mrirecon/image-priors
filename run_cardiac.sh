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

make_folder()
{
    if [ ! -e $1 ] ; then
        mkdir $1
    fi
}

DATA_PATH=/home/ague/archive/vol/2020-08-05_MRT5_DCRD_0006/meas_MID00085_FID176162_UMG_Radial_14fa5e2_ADCfix_SS_C5.dat
RES_PATH=/home/gluo/workspace/nlinv_prior/cardiac
make_folder $RES_PATH

#--- config ---
RO=512
SP=5
PAR=1
FR=2600

if [ "0" == "1" ]; then
    #--- Twix --
    bart twixread -A $DATA_PATH $RES_PATH/_k

    #--- k-space ---
    bart reshape $(bart bitmask 0 1 2 10) 1 $RO 1 $(($SP * $FR)) $RES_PATH/_k $RES_PATH/k


    #--- Traj ---
    topts="-x$RO -y1 -t$(($FR * $SP)) -G -s7 -c"
    bart traj $topts $RES_PATH/t

    #--- RING ---
    bart resize 10 50 $RES_PATH/t $RES_PATH/_tGD
    bart transpose 10 2 $RES_PATH/_tGD $RES_PATH/_tGD1

    bart resize 10 50 $RES_PATH/k $RES_PATH/_kGD
    bart transpose 10 2 $RES_PATH/_kGD $RES_PATH/_kGD1
    GD=$(bart estdelay -R $RES_PATH/_tGD1 $RES_PATH/_kGD1); echo $GD

    bart traj $topts -O -q$GD $RES_PATH/tGD
    bart cc -p 13 -A $RES_PATH/k $RES_PATH/k_cc
fi


nr_used_spokes=30
start=530
nr_slices=10
GRAPH=/home/gluo/preco/prior/exported/cardiac_pixelcnn
for ((i=0; i<$nr_slices; i++)); do
    echo "Slice" $i
    bart extract 10 $start $((start + nr_used_spokes)) 1 $RES_PATH/tGD $RES_PATH/traj_
    bart transpose 10 2 $RES_PATH/traj_ $RES_PATH/traj

    bart extract 10 $start $((start + nr_used_spokes)) 1 $RES_PATH/k_cc $RES_PATH/ksp_
    bart transpose 10 2 $RES_PATH/ksp_ $RES_PATH/ksp
    
    bart nlinv -a660 -b44 -i10 -d5 -t $RES_PATH/traj $RES_PATH/ksp $RES_PATH/nlinv_recon_$i $RES_PATH/nlinv_recon_coils_$i

    bart nlinv -a880 -b44 -i9 -l1 -e 0.01 -r3.5 -y100 -d5 -t $RES_PATH/traj $RES_PATH/ksp $RES_PATH/nlinv_recon_l1_$i $RES_PATH/nlinv_recon_l1_coils_$i

    bart nlinv -a880 -b44 -i8 -R LP:{$GRAPH}:8:0.9:1:512:1 -y10 -r3.5 -C30 -d5 -t $RES_PATH/traj $RES_PATH/ksp $RES_PATH/nlinv_recon_prior_$i $RES_PATH/nlinv_recon_prior_coils_$i
    start=$((start + nr_used_spokes))
done