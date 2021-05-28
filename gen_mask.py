import sys
sys.path.append("/home/gluo/bart/python")
import cfl
import numpy as np

np.random.seed(1000)

def gen_mask_1D_random_skip(ratio=0.1,center=20, fe=256, ph=256):
    """
    generate undersampling mask along 1 dimension
    Args:

    ratio: sampling ratio
    center: center lines retained
    fe: frequency encoding
    ph: phase encoding lines

    Returns:
    mask
    """
    k      = int(round(ph*ratio)/2.0)
    ma     = np.zeros(ph)
    ri     = np.random.choice(int(ph/2-center/2), k, replace=False)
    ma[ri] = 1
    ri = np.random.choice(int(ph/2-center/2), k, replace=False)

    ma[ri+int(ph/2+center/2)] = 1
    ma[int(ph/2-center/2): int(ph/2+center/2)] = 1
    mask = np.tile(ma, [fe, 1])

    return mask

def gen_mask_1D_equally_skip(factor=2,center=20, fe=256, ph=256):
    """
    generate undersampling mask along 1 dimension
    Args:

    ratio: sampling ratio
    center: center lines retained
    fe: frequency encoding
    ph: phase encoding lines

    Returns:
    mask
    """
    ma           = np.zeros(ph)
    selected     = np.arange(0,ph,factor)
    ma[selected] = 1

    ma[int(ph/2-center/2): int(ph/2+center/2)] = 1
    mask = np.tile(ma, [fe, 1])

    return mask

def gen_mask_2d_equally_skip(factor_x=2, factor_y=2, center=20, fe=256, ph=256):
    """

    """
    p = np.zeros((fe, ph))
    
    grid = np.meshgrid(np.arange(0, fe, factor_x), np.arange(0, ph, factor_y))
    p[tuple(grid)] = 1

    if center > 0:
        cx = np.int(fe/2)
        cy = np.int(ph/2)

        cxr_b = round(cx-center//2)
        cxr_e = round(cx+center//2+1)
        cyr_b = round(cy-center//2)
        cyr_e = round(cy+center//2+1)

        p[cxr_b:cxr_e, cyr_b:cyr_e] = 1. #center k-space is fully sampled

    return p


def gen_mask_2d_random_skip(ratio=0.1, center=20, fe=256, ph=256):

    k      = int(round(fe*ph*ratio))                  #undersampling
    ri     = np.random.choice(fe*ph,k,replace=False) #index for undersampling
    ma     = np.zeros(fe*ph)                         #initialize an all zero vector
    ma[ri] = 1                                   #set sampled data points to 1
    mask   = ma.reshape((fe,ph))

    # center k-space index range
    if center > 0:

        cx = np.int(fe/2)
        cy = np.int(ph/2)

        cxr_b = round(cx-center//2)
        cxr_e = round(cx+center//2+1)
        cyr_b = round(cy-center//2)
        cyr_e = round(cy+center//2+1)

        mask[cxr_b:cxr_e, cyr_b:cyr_e] = 1. #center k-space is fully sampled

    return mask

def main(argv):

    path  = argv[1]
    dim   = argv[2]

    if dim == '1d':

        ratio = float(argv[3])
        if ratio < 0.999999:
            cfl.writecfl(path, gen_mask_1D_random_skip(ratio=ratio,center=int(argv[4]), fe=int(argv[5]), ph=int(argv[6])))
        else:
            cfl.writecfl(path, gen_mask_1D_equally_skip(factor=int(ratio),center=int(argv[4]), fe=int(argv[5]), ph=int(argv[6])))

    elif dim == '2d':

        if len(argv) == 7:
            ratio = float(argv[3])
            cfl.writecfl(path, gen_mask_2d_random_skip(ratio, int(argv[4]), fe=int(argv[5]), ph=int(argv[6])))
        else:
            cfl.writecfl(path, gen_mask_2d_equally_skip(factor_x=int(argv[3]), factor_y=int(argv[4]), center=int(argv[5]), fe=int(argv[6]), ph=int(argv[7])))

    else:
        raise("acceleration can only be performed in two direction")


if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("The number of args is less than expected")
    else:
        main(sys.argv)