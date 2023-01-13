from spreco.common import utils

import os
import numpy as np

result_path = '/home/gluo/workspace/nlinv_prior/results'
exprs       = ['1d', '2d', 'po']
recos       = ['zero_filled', 'l1_pics', 'l1_nlinv', 'prior_abide_pics', 
                'prior_abide_filtered_pics', 'prior_hku_pics', 'prior_abide_nlinv', 
                'prior_abide_filtered_nlinv', 'prior_hku_nlinv']

normalize = lambda x: abs(x)/np.linalg.norm(abs(x))
readcfl   = lambda dir, file: utils.readcfl(os.path.join(dir, file))


und_kspace = readcfl(os.path.join(result_path, exprs[0]), 'und_kspace')
coilsen = abs(utils.bart(1, 'ecalib -r 20 -m1', und_kspace))
mask = np.squeeze(coilsen>0.000001)[...,0]

print('pattern & ', end='')
for i, reco in enumerate(recos):
    print(reco, end='')
    if i != len(recos)-1:
        print(' & ', end='')
    else:
        print('\n', end='')

print('---------PSNR-----------')


for expr in exprs:

    cur_dir     = os.path.join(result_path, expr)
    grd         = normalize(readcfl(cur_dir, 'grd'))
    print('%s\t&\t'%expr, end='')
    for i, reco in enumerate(recos):

        img = normalize(readcfl(cur_dir, reco))
        psnr = utils.psnr(grd, img*mask)
        print("%.2f"%psnr, end='')

        if i != len(recos)-1:
            print('\t&\t', end='')
        else:
            print('\n', end='')

print('---------SSIM-----------')


for expr in exprs:

    cur_dir     = os.path.join(result_path, expr)
    grd         = normalize(readcfl(cur_dir, 'grd'))
    print('%s\t&\t'%expr, end='')
    for i, reco in enumerate(recos):
        img = normalize(readcfl(cur_dir, reco))
        ssim = utils.ssim(grd, img*mask)
        print("%.4f"%ssim, end='')

        if i != len(recos)-1:
            print('\t&\t', end='')
        else:
            print('\n', end='')
