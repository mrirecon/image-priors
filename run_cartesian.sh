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

DATA_PATH=/home/ague/data/gluo/dataset/brain_mat/test/hku_100000

#
make_folder()
{
    if [ ! -e $1 ] ; then
        mkdir $1
    fi
}

zero_filled()
{
    echo "zero filled start"
    bart fft -i $(bart bitmask 0 1) $1/und_kspace $1/zero_filled_coils
    bart rss $(bart bitmask 3) $1/zero_filled_coils $1/zero_filled
    echo "zero filled end"
}

#
l1_espirit()
{
    echo "l1-ESPIRiT reconstruction start"
    bart ecalib -r$cal -m1 -c0.0001 $1/und_kspace $1/coilsen
    bart pics -d5 -l1 -r $2 $1/und_kspace $1/coilsen $1/l1_recon
    echo "l1-ESPIRiT reconstruction end"
}

#
nlinv()
{
    echo "l2 nlinv reconstruction start"
    bart nlinv -i$2 -d5 $1/und_kspace $1/nlinv_recon $1/nlinv_recon_coils
    echo "l2 nlinv reconstruction end"
}

#
l1_nlinv()
{
    echo "l1 nlinv reconstruction start"
    bart nlinv -a 660 -b44 -i$2 -l1 -e $4 -r3.5 -d5 -C50 -y$3 $1/und_kspace $1/l1_nlinv_recon_fista $1/l1_nlinv_recon_coils_fista
    echo "l1 nlinv reconstruction end"
}

#
prior_nlinv()
{
    echo "prior nlinv reconstruction start"
    bart nlinv -i$2 -R LP:{$4}:$5:$6:1:256 -r3.5 -d5 -C30 -y$3 $1/und_kspace $1/prior_recon $1/prior_recon_coils
    echo "prior nlinv reconstruction end"
}

post_computation()
{
    # normalized ground truth
    bart normalize $(bart bitmask 0 1) $1/coils $1/coils_normalized
    bart normalize $(bart bitmask 0 1) $1/rss $1/rss_normalized

    echo "--Evaluate nlinv--"
    bart normalize $(bart bitmask 0 1) $1/prior_recon_coils $1/prior_recon_coils_normalized
    bart fmac $1/prior_recon_coils_normalized $1/prior_recon $1/prior_recon_projection
    bart normalize $(bart bitmask 0 1) $1/prior_recon_projection $1/prior_recon_projection_normalized
    
    bart saxpy -- -1 $1/prior_recon_projection_normalized $1/coils_normalized $1/prior_recon_projection_residual

    bart rss $(bart bitmask 3) $1/prior_recon_projection_residual $1/prior_recon_projection_residual_rss

    echo "coils' residual"
    bart nrmse -s $1/coils_normalized $1/prior_recon_projection_normalized

    echo "recon's residual"
    bart normalize $(bart bitmask 0 1) $1/prior_recon $1/prior_recon_normalized
    bart cabs $1/prior_recon_normalized $1/prior_recon_normalized_abs
    bart saxpy -- -1 $1/prior_recon_normalized_abs $1/rss_normalized $1/prior_recon_residual
    bart nrmse $1/rss_normalized $1/prior_recon_normalized_abs


    echo "--Evaluate pics-espirit--"
    bart fmac $1/coilsen $1/l1_recon $1/l1_recon_projection    
    bart normalize $(bart bitmask 0 1) $1/l1_recon_projection $1/l1_recon_projection_normalized

    bart saxpy -- -1 $1/l1_recon_projection_normalized $1/coils_normalized $1/l1_recon_projection_residual

    bart rss $(bart bitmask 3) $1/l1_recon_projection_residual $1/l1_recon_projection_residual_rss

    echo "coils' residual"
    bart nrmse -s $1/coils_normalized $1/l1_recon_projection_normalized

    echo "recon's residual"
    bart normalize $(bart bitmask 0 1) $1/l1_recon $1/l1_recon_normalized
    bart cabs $1/l1_recon_normalized $1/l1_recon_normalized_abs
    bart saxpy -- -1 $1/l1_recon_normalized_abs $1/rss_normalized $1/l1_recon_residual
    bart nrmse $1/rss_normalized $1/l1_recon_normalized_abs
}

run_recon=1

if [ "0" == "1" ]; then

    echo "##EXPERIMENT 1##"
    
    # settings
    RES_PATH=/home/gluo/nlinv_prior
    EXPER=1d_random
    PATTERN=1d
    RATIO=0.15
    nx=256
    ny=256
    cal=20

    RES_PATH=$RES_PATH/$EXPER
    make_folder $RES_PATH

    if [ "$run_recon" == "1" ]; then
        
        echo "Recon begins"

        python gen_mask.py $RES_PATH/mask $PATTERN $RATIO $cal $nx $ny
        bart fmac $RES_PATH/mask $DATA_PATH $RES_PATH/und_kspace

        bart fft -i $(bart bitmask 0 1) $DATA_PATH $RES_PATH/coils
        bart rss $(bart bitmask 3) $RES_PATH/coils $RES_PATH/rss

        zero_filled $RES_PATH

        l1_espirit $RES_PATH 0.01

        nlinv $RES_PATH 8

        SCALAR=1
        ITER=10
        l1_nlinv $RES_PATH $ITER $SCALAR 0.01

        SCALAR=0.35
        ITER=10
        GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
        STEP_SIZE=8
        PCT=0.85
        prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT
        echo -e "Recon ends\n"
    fi
    echo "Post-computation"
    post_computation $RES_PATH

fi

if [ "0" == "1" ]; then

    echo "##EXPERIMENT 2##"
    # settings
    RES_PATH=/home/gluo/nlinv_prior
    EXPER=1d_equal
    PATTERN=1d
    RATIO=5
    nx=256
    ny=256
    cal=20

    RES_PATH=$RES_PATH/$EXPER
    make_folder $RES_PATH

    if [ "$run_recon" == "1" ]; then

        echo "Recon begins"

        python gen_mask.py $RES_PATH/mask $PATTERN $RATIO $cal $nx $ny
        bart fmac $RES_PATH/mask $DATA_PATH $RES_PATH/und_kspace

        bart fft -i $(bart bitmask 0 1) $DATA_PATH $RES_PATH/coils
        bart rss $(bart bitmask 3) $RES_PATH/coils $RES_PATH/rss

        zero_filled $RES_PATH

        l1_espirit $RES_PATH 0.01

        nlinv $RES_PATH 8

        SCALAR=0.2
        ITER=10
        l1_nlinv $RES_PATH $ITER $SCALAR 0.01

        SCALAR=0.2
        ITER=10
        GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
        STEP_SIZE=5
        PCT=0.75
        prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT
        echo -e "Recon ends\n"
    fi

    echo "Post-computation"
    post_computation $RES_PATH

fi

if [ "0" == "1" ]; then
    
    echo "##EXPERIMENT 3##" 
    # settings
    RES_PATH=/home/gluo/nlinv_prior
    EXPER=2d_random
    PATTERN=2d
    RATIO=0.10
    nx=256
    ny=256
    cal=20

    RES_PATH=$RES_PATH/$EXPER
    make_folder $RES_PATH

    if [ "$run_recon" == "1" ]; then

        echo "Recon begins"
        
        python gen_mask.py $RES_PATH/mask $PATTERN $RATIO $cal $nx $ny
        bart fmac $RES_PATH/mask $DATA_PATH $RES_PATH/und_kspace

        bart fft -i $(bart bitmask 0 1) $DATA_PATH $RES_PATH/coils
        bart rss $(bart bitmask 3) $RES_PATH/coils $RES_PATH/rss

        zero_filled $RES_PATH

        l1_espirit $RES_PATH 0.01

        nlinv $RES_PATH 8

        SCALAR=1
        ITER=10
        l1_nlinv $RES_PATH $ITER $SCALAR 0.01

        SCALAR=1
        ITER=10
        GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
        STEP_SIZE=7
        PCT=0.8
        prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT
        echo -e "Recon ends\n"

    fi

    echo "Post-computation"
    post_computation $RES_PATH

fi

if [ "0" == "1" ]; then

    echo "##EXPERIMENT 4##"

    RES_PATH=/home/gluo/nlinv_prior
    EXPER=2d_equal
    PATTERN=2d
    RATIO=3
    RATIO_2=3
    nx=256
    ny=256
    cal=20

    RES_PATH=$RES_PATH/$EXPER
    make_folder $RES_PATH

    if [ "$run_recon" == "1" ]; then

        echo "Recon begins"
        
        python gen_mask.py $RES_PATH/mask $PATTERN $RATIO $RATIO_2 $cal $nx $ny
        bart fmac $RES_PATH/mask $DATA_PATH $RES_PATH/und_kspace

        bart fft -i $(bart bitmask 0 1) $DATA_PATH $RES_PATH/coils
        bart rss $(bart bitmask 3) $RES_PATH/coils $RES_PATH/rss

        zero_filled $RES_PATH

        l1_espirit $RES_PATH 0.01

        nlinv $RES_PATH 8

        SCALAR=1
        ITER=10
        l1_nlinv $RES_PATH $ITER $SCALAR 0.01

        SCALAR=1
        ITER=10
        GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
        STEP_SIZE=7
        PCT=0.8
        prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT
        echo -e "Recon ends\n"
    fi

    echo "Post-computation"
    post_computation $RES_PATH

fi

if [ "0" == "0" ]; then

    echo "##EXPERIMENT 5##"

    RES_PATH=/home/gluo/nlinv_prior
    EXPER=poisson
    PATTERN=2d
    RATIO=3
    RATIO_2=3
    nx=256
    ny=256
    cal=20

    RES_PATH=$RES_PATH/$EXPER
    make_folder $RES_PATH

    if [ "$run_recon" == "1" ]; then

        echo "Recon begins"
        
        bart poisson -Y$nx -Z$ny -y$RATIO -z$RATIO_2 -C$cal $RES_PATH/mask
        bart transpose 0 1 $RES_PATH/mask $RES_PATH/mask
        bart transpose 1 2 $RES_PATH/mask $RES_PATH/mask

        bart fmac $RES_PATH/mask $DATA_PATH $RES_PATH/und_kspace

        bart fft -i $(bart bitmask 0 1) $DATA_PATH $RES_PATH/coils
        bart rss $(bart bitmask 3) $RES_PATH/coils $RES_PATH/rss

        zero_filled $RES_PATH

        l1_espirit $RES_PATH 0.01

        nlinv $RES_PATH 8

        SCALAR=1
        ITER=10
        l1_nlinv $RES_PATH $ITER $SCALAR 0.01

        SCALAR=1
        ITER=9
        GRAPH=/home/gluo/preco/prior/exported/pixel_cnn
        STEP_SIZE=7
        PCT=0.8
        prior_nlinv $RES_PATH $ITER $SCALAR $GRAPH $STEP_SIZE $PCT
        echo -e "Recon ends\n"
    fi

    echo "Post-computation"
    post_computation $RES_PATH


fi