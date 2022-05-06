from pprint import pprint
from sklearn.tree._criterion import MSE
from sklearn.tree._splitter import BestSplitter

from splitter_test import test_splitter
from hypertree.tree._nd_splitter import make_2d_splitter
from hypertree.tree._nd_criterion import MSE_Wrapper2D
from hypertree.tree._semisupervised import SSBestSplitter as SSBestSplitter
from hypertree.tree._semisupervised import SSCompositeCriterion


import numpy as np
#from sklearn.tree._tree import DTYPE_t, DOUBLE_t
DTYPE_t, DOUBLE_t = np.float32, np.float64

from pathlib import Path
import sys
from time import time

path_pbct_test = Path('../../scripts/predictors/PBCT/tests/')
sys.path.insert(0, str(path_pbct_test))
from make_examples import make_interaction_data

SEED = 2

## Generate mock data
np.random.seed(SEED)
t0 = time()
shape, nattrs = (200, 100), (100, 1)
# XX, Y, strfunc = make_interaction_data(
#     shape, nattrs, nrules=1, random_state=SEED)
# Y = np.ascontiguousarray(Y, dtype=DOUBLE_t)
# Y += np.random.rand(*Y.shape)  # add some noise
# XX = [X.astype(DTYPE_t) for X in XX]
XX = [np.random.rand(nattrs[0], shape[0]).astype(DTYPE_t)]
Y = np.random.rand(shape[0], 1).astype(DOUBLE_t)*.1
Y[XX[0][5] < .5, :] = 1
print('Time:', time()-t0)

## Instantiate sklearn objects
criterion = MSE(n_outputs=shape[1], n_samples=shape[0])

splitter = BestSplitter(
    criterion=criterion,
    max_features=XX[0].shape[1],
    min_samples_leaf=1,
    min_weight_leaf=0,
    random_state=np.random.RandomState(0),
)

ss_splitter = SSBestSplitter(
    criterion=SSCompositeCriterion(
            unsupervised_criterion=MSE(
                n_samples=XX[0].shape[0],
                n_outputs=XX[0].shape[1],
            ),
            supervised_criterion=MSE(
                n_samples=shape[0],
                n_outputs=shape[1],
            ),
            supervision=1,
    ),
    max_features=XX[0].shape[1],
    min_samples_leaf=1,
    min_weight_leaf=0,
    random_state=np.random.RandomState(0),
)

# splitter2d = make_2d_splitter(
#             splitter_class=SSBestSplitter,
#             criterion_class=[
#                 SSCompositeCriterion(
#                     unsupervised_criterion=MSE(
#                         n_samples=XX[0].shape[0],
#                         n_outputs=XX[0].shape[1],
#                     ),
#                     supervised_criterion=MSE(
#                         n_samples=Y.shape[0],
#                         n_outputs=1,
#                     ),
#                     supervision=1,
#                 ),
#                 SSCompositeCriterion(
#                     unsupervised_criterion=MSE(
#                         n_samples=XX[1].shape[0],
#                         n_outputs=XX[1].shape[1],
#                     ),
#                     supervised_criterion=MSE(
#                         n_samples=Y.shape[1],
#                         n_outputs=1,
#                     ),
#                     supervision=1,
#                 ),
#             ],
#             n_outputs=1,
#             max_features=[X.shape[1] for X in XX],
#             min_samples_leaf=1,
#             min_weight_leaf=0.0,
#             ax_min_samples_leaf=1,
#             ax_min_weight_leaf=0.0,
#             random_state=None,
#             criterion_wrapper_class=MSE_Wrapper2D,
#         ),


## Run test
t0 = time()
print(f'Testing {splitter.__class__.__name__}...')
result = test_splitter(splitter, XX[0], Y, Y.shape)
print('Best split found:')
pprint(result)
print('Time:', time()-t0)

t0 = time()
print(f'Testing {ss_splitter.__class__.__name__}...')
result = test_splitter(ss_splitter, XX[0], Y, Y.shape)
print('Best split found:')
pprint(result)
print('Time:', time()-t0)