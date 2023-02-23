# This script is to preprocess the images from Autism Brain Imaging Data Exchange

from spreco.common import utils
import nibabel as nib
from nibabel.processing import conform
import os
import numpy as np
import tqdm
import argparse

def load_file(path, x=256, y=256):
    try:
        nib_img   = nib.load(path)
        z_f = nib_img.header.get_zooms()[-1]
        shape=nib_img.shape
        out_shape = [x, y, int(shape[-1]*z_f)]
        resampled_img = conform(nib_img, out_shape, cval=9999)
        arr = resampled_img.get_fdata()
        return arr, out_shape
    except:
        return None, None

def mk_slice(arr, idx, save_name):

    slice = abs(arr[:,:,idx])
    maxi = np.max(slice)

    position2 = np.where( slice==9999 )
    position3 = np.where( slice<15 )

    vals2 = np.random.normal(loc=0.003*maxi, scale=5, size=(len(position2[0])))
    vals3 = np.random.normal(loc=0.003*maxi, scale=5, size=(len(position3[0])))

    slice[position2[0], position2[1]]  = abs(vals2)
    slice[position3[0], position3[1]]  = abs(vals3)

    n_slice = utils.normalize_with_max(slice, data_chns='MAG')
    # detect if an image  FIXME: this approach is not perfect
    region = n_slice[:30, :30]
    #print("std: %.4f mean: %.4f"%(np.std(region), np.mean(region)))
    if np.std(region)<0.0061 and np.mean(region) < 0.04:
        utils.save_img(n_slice, save_name)
        mag = n_slice
        np.savez(save_name, mag=mag)
        return True
    else:
        return False
    

def process_nii(file_path, counter, folder=None):

    if folder is None:
        folder = os.path.split(file_path)

    arr, out_shape = load_file(file_path)
    if arr is not None:
        mid = int((out_shape[-1])/2)
    else:
        print("The skipped file %s could be corrupted"%file_path)
        return counter

    for i in range(mid, out_shape[-1]):
        save_name = os.path.join(folder, 'abide' + '_' + str(counter))
        if mk_slice(arr, i, save_name):
            counter = counter + 1

    return counter

# get all the nii files from the given folder
def main(folder , savepath):
    files       = utils.check_out("find %s -type f -name \"*.nii\" "%folder)
    counter = 1000000
    for file in tqdm.tqdm(files):
        counter = process_nii(file, counter, savepath)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--folder', metavar='path', default='/home/ague/data/gluo/ABIDE', help='')
    parser.add_argument('--savepath', metavar='path', default='/home/ague/data/gluo/dataset/abide_2/magnitude', help='')
    args = parser.parse_args()
    main(args.folder, args.savepath)