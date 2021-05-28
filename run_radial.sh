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

DATA_PATH=/home/gluo/ISMRM/2021

make_folder()
{
    if [ ! -e $1 ] ; then
        mkdir $1
    fi
}

nlinv()
{
    bart nlinv -a660 -b44 -i$2 -d5 -t $1/traj_256_c $1/ksp_256_c $1/nlinv_recon $1/nlinv_recon_coils
}

l1_nlinv()
{
    bart nlinv -a660 -b44 -i$2  -l1 -e 0.01 -r2.5 -d5 -y$3 -C40 -t $1/traj_256_c $1/ksp_256_c $1/l1_nlinv $1/l1_nlinv_coils
}

prior_nlinv()
{
    bart nlinv -a660 -b44 -i$2 -R LP:{$4}:$5:$6:1:256 -r3.5 -d5 -y$3 -C30 -t $1/traj_256_c $1/ksp_256_c $1/prior_nlinv $1/prior_nlinv_coils
}

RES_PATH=/home/gluo/nlinv_prior
EXPER=radial
RES_PATH=$RES_PATH/$EXPER
make_folder $RES_PATH

spokes=60
python gen_weights.py $RES_PATH/weights $spokes 256

bart extract 2 0 $spokes $DATA_PATH/ksp_256 $RES_PATH/ksp_256_c
bart extract 2 0 $spokes $DATA_PATH/traj_256 $RES_PATH/traj_256_c

ITER=10
#nlinv $RES_PATH $ITER

ITER=10
SCALAR=100

#l1_nlinv $RES_PATH $ITER $SCALAR

GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
STEP_SIZE=1.5
PCT=0.7
ITER=12
SCALAR=10

prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT

bart resize -c 0 256 1 256 $RES_PATH/prior_nlinv_coils $RES_PATH/prior_nlinv_coils_256
bart pics -l1 -r 0.001 -i50 -e -t $RES_PATH/traj_256_c $RES_PATH/ksp_256_c  $RES_PATH/prior_nlinv_coils_256 $RES_PATH/pics_recon
bart pics -e -i50 -R LP:{$GRAPH}:10:0.7:1:256 -d5 -t $RES_PATH/traj_256_c $RES_PATH/ksp_256_c  $RES_PATH/prior_nlinv_coils_256 $RES_PATH/pics_recon_prior