from spreco.common import utils

import os
import numpy as np

readcfl   = lambda dir, file: utils.readcfl(os.path.join(dir, file))
normalize = lambda x: x/np.linalg.norm(abs(x))
win_ftr   = 0.65
saveimg   = lambda x, upper, name: utils.save_img(x, "./sub_figs/"+name, vmax=upper*win_ftr)

dir='/home/ague/data/gluo/dataset/abide_2/train'

good = normalize(np.mean(readcfl(dir, 'abide_1000635'), axis=0))
okay = normalize(np.mean(readcfl(dir, 'abide_1012858'), axis=0))
bad  = normalize(np.mean(readcfl(dir, 'abide_1004807'), axis=0))

saveimg(abs(good), np.max(abs(good)), 'good')
saveimg(abs(okay), np.max(abs(okay)), 'okay')
saveimg(abs(bad), np.max(abs(bad)), 'bad')
