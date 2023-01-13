set -e
export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=0

GRAPH=/home/gluo/workspace/nlinv/logs/exported/pixelcnn_abide
#GRAPH=/home/gluo/workspace/nlinv/logs/exported/pixelcnn_hku
#GRAPH=/home/gluo/workspace/nlinv/logs/exported/pixelcnn_abide_filtered
#DATA_PATH=/home/gluo/workspace/nlinv/scripts/data/kspace
DATA_PATH=/home/gluo/workspace/nlinv/scripts/data/mprage

mkdir -p tmp

cd tmp

PATTERN=2d

nx=256
ny=256
cal=15
fx=3
fy=2
ratio=5

#
if [ $PATTERN == poisson ]; then
bart poisson -Y$nx -Z$ny -y1.5 -z1.5 -v -s 1000 -C$cal mask
bart transpose 0 1 mask mask
bart transpose 1 2 mask mask
fi

if [ $PATTERN == 1d ]; then
python ../gen_mask.py mask $PATTERN $ratio $cal $nx $ny
fi

if [ $PATTERN == 2d ]; then
python ../gen_mask.py mask $PATTERN $fx $fy $cal $nx $ny
fi

bart fmac mask $DATA_PATH und_kspace

bart nlinv -g -d4 -a660 -b44 -i14 -C50 und_kspace nlinv_recon nlinv_recon_coils
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=5 -R W:3:0:0.08 und_kspace l1_nlinv_recon l1_nlinv_recon_coils
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=5 -R T:3:0:0.05 und_kspace tv_nlinv_recon tv_nlinv_recon_coils
bart nlinv -g -d4 -a660 -b44 -i14 -C50 --reg-iter=5 -R LP:{$GRAPH}:1:1:1 und_kspace prior_nlinv_recon_ prior_nlinv_recon_coils
#bart nlinv -g -d4 -a660 -b44 -i15 -A -C100 --reg-iter=5 -R T:3:0:1 und_kspace prior_l1_nlinv_recon_admm prior_l1_nlinv_recon_coils_admm

bart ecalib -r20 -m1 -c0.001 und_kspace coilsen_esp
#bart pics -g -l1 -r 0.01 und_kspace coilsen_esp  l1_pics
#bart pics -g -i100 -d4 -R TF:{$GRAPH}:0.8 und_kspace coilsen_esp prior_pics

bart fft -i 3 $DATA_PATH coilimgs
bart rss 8 coilimgs rss

bart fft -i 3 und_kspace coilimgs
bart rss 8 coilimgs zero_filled

view nlinv_recon \
    rss \
    zero_filled\
    l1_nlinv_recon \
    prior_nlinv_recon \
    tv_nlinv_recon\
    l1_pics\
    prior_pics
    #prior_l1_nlinv_recon_admm \
    #nlinv_recon_coils \
    #prior_nlinv_recon_coils \
    #l1_nlinv_recon_coils \
    #prior_l1_nlinv_recon_coils_admm

