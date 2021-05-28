import sys
sys.path.append("/home/gluo/bart/python")
import cfl

import numpy as np
from numpy.matlib import repmat

def gen_weights(nSpokes, N):
    """
    generate radial compensation weight
    """
    rho = np.linspace(-0.5,0.5,N).astype('float32')
    w = abs(rho)/0.5
    w = np.transpose(repmat(w, nSpokes, 1), [1, 0])
    w = np.reshape(w, [1, N, nSpokes])
    return np.sqrt(w)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("The number of args is less than expected")
    else:
        cfl.writecfl(sys.argv[1], gen_weights(int(sys.argv[2]), int(sys.argv[3])))