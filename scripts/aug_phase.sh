#!/bin/bash

# please set the savepath in the CONFIG file

CONFIG=/home/gluo/workspace/nlinv_prior/scripts/configs/phase_abide.yaml
FILELIST=/home/gluo/workspace/nlinv_prior/data/abide/abide_filelist
FILE_BATCHES=5
NUM_GPUS=3
GPU_IDS="0,1,2"
TMP=/home/gluo/workspace/nlinv_prior/data/tmp_list

./runner $CONFIG $FILELIST $FILE_BATCHES $NUM_GPUS $GPU_IDS $TMP inbatch