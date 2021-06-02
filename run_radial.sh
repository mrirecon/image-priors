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

DATA_PATH=/home/ague/transfer/2021-05-31_MRT5_MyT1_0068/meas_MID00361_FID229502_mpi61_FOV192_1x1x4_FLASH_TE16_TR770.dat

make_folder()
{
    if [ ! -e $1 ] ; then
        mkdir $1
    fi
}

nlinv()
{
    bart nlinv -a660 -b44 -i$2 -d5 -t $1/traj_256 $1/ksp_256 $1/nlinv_recon $1/nlinv_recon_coils
}

l1_nlinv()
{
    bart nlinv -a660 -b44 -i$2  -l1 -e $4 -r2.5 -d5 -y$3 -C40 -t $1/traj_256 $1/ksp_256 $1/l1_nlinv $1/l1_nlinv_coils
}

prior_nlinv()
{
    bart nlinv -a660 -b44 -i$2 -R LP:{$4}:$5:$6:1:256 -r3.5 -d5 -y$3 -C30 -t $1/traj_256 $1/ksp_256 $1/prior_nlinv $1/prior_nlinv_coils
}

RES_PATH=/home/gluo/nlinv_prior
EXPER=radial
RES_PATH=$RES_PATH/$EXPER
make_folder $RES_PATH

nr_readout=512
nr_spokes=401
nr_coils=16
nx=256
bart twixread -x $nr_readout -r$nr_spokes -c$nr_coils -n1 $DATA_PATH $RES_PATH/raw
nr_used_spokes=50

traj_opt="-r -y$nr_spokes -D -c -s7 -G"
bart traj $traj_opt -x $nr_readout $RES_PATH/traj

bart resize 2 90 traj $RES_PATH/traj_
bart resize 2 90 raw $RES_PATH/raw_
GD=$(bart estdelay -R traj_ raw_)

bart traj $traj_opt -x $nx -O -q$GD $RES_PATH/traj

bart extract 1 0 512 2 $RES_PATH/raw ksp
bart extract 2 0 $nr_used_spokes 1 $RES_PATH/raw $RES_PATH/ksp_tmp
bart extract 1 0 512 2 $RES_PATH/ksp_tmp $RES_PATH/ksp_
bart cc -p8 $RES_PATH/ksp_ $RES_PATH/ksp_256
bart extract 2 0 $nr_used_spokes 1 $RES_PATH/traj $RES_PATH/traj_256

ITER=10
#nlinv $RES_PATH $ITER

ITER=10
SCALAR=100

#l1_nlinv $RES_PATH $ITER $SCALAR 0.005

GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
STEP_SIZE=2
PCT=0.7
ITER=12
SCALAR=10

prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT