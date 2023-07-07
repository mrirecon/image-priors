#!/bin/bash

# please set the savepath in the CONFIG file

CONFIG=../configs/phase_abide.yaml
FILELIST=/tmp/abide_mag_filelist
FILE_BATCHES=5
NUM_GPUS=2
GPU_IDS="0,1"
TMP=/tmp/tmp_list

./runner $CONFIG $FILELIST $FILE_BATCHES $NUM_GPUS $GPU_IDS $TMP inbatch
