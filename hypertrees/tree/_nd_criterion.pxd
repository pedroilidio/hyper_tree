import numpy as np
cimport numpy as np

from sklearn.tree._tree cimport DTYPE_t          # Type of X
from sklearn.tree._tree cimport DOUBLE_t         # Type of y, sample_weight
from sklearn.tree._tree cimport SIZE_t           # Type for indices and counters

from sklearn.tree._splitter cimport Splitter
from sklearn.tree._criterion cimport Criterion, RegressionCriterion


cdef class CriterionWrapper2D:
    """Abstract base class."""
    cdef Splitter splitter_rows
    cdef Splitter splitter_cols

    cdef const DOUBLE_t[:, ::1] X_rows
    cdef const DOUBLE_t[:, ::1] X_cols
    cdef const DOUBLE_t[:, ::1] y_2D

    cdef DOUBLE_t* row_sample_weight
    cdef DOUBLE_t* col_sample_weight
    cdef SIZE_t[::1] row_samples
    cdef SIZE_t[::1] col_samples
    cdef SIZE_t[2] start
    cdef SIZE_t[2] end
    cdef SIZE_t n_outputs
    cdef SIZE_t n_rows
    cdef SIZE_t n_cols
    cdef double sq_sum_total
    cdef double[::1] sum_total
    cdef double weighted_n_samples

    cdef double weighted_n_node_samples
    cdef double weighted_n_node_rows
    cdef double weighted_n_node_cols

    cdef int init(
        self, const DOUBLE_t[:, ::1] y_2D,
        DOUBLE_t* row_sample_weight,
        DOUBLE_t* col_sample_weight,
        double weighted_n_samples,
        SIZE_t[2] start, SIZE_t[2] end,
    ) nogil except -1

    cdef int _node_reset_child_splitter(
            self,
            Splitter child_splitter,
            const DOUBLE_t[:, ::1] y,
            DOUBLE_t* sample_weight,
            SIZE_t start,
            SIZE_t end,
            DOUBLE_t* weighted_n_node_samples,
    ) nogil except -1

    cdef void node_value(self, double* dest) nogil

    cdef double node_impurity(self) nogil

    cdef void children_impurity(
            self,
            double* impurity_left,
            double* impurity_right,
            SIZE_t axis,
    )

    cdef double impurity_improvement(
            self, double impurity_parent, double
            impurity_left, double impurity_right,
            SIZE_t axis,
    ) nogil


cdef class RegressionCriterionWrapper2D(CriterionWrapper2D):
    # FIXME: We need X here because BaseDenseSplitter.X is not accessible.
    cdef DOUBLE_t[:, ::1] y_row_sums
    cdef DOUBLE_t[:, ::1] y_col_sums

    cdef DOUBLE_t* total_row_sample_weight
    cdef DOUBLE_t* total_col_sample_weight


cdef class PBCTCriterionWrapper(CriterionWrapper2D):
    """Applies Predictive Bi-Clustering Trees method.

    See [Pliakos _et al._, 2018](https://doi.org/10.1007/s10994-018-5700-x).
    """
    cdef double* _node_value_aux  # Temporary storage to use in node_value()
    cdef SIZE_t _aux_len
    cdef SIZE_t last_split_axis
    cdef DOUBLE_t[:, ::1] y_2D_rows
    cdef DOUBLE_t[:, ::1] y_2D_cols
    cdef AxisRegressionCriterion criterion_rows
    cdef AxisRegressionCriterion criterion_cols

    cdef AxisRegressionCriterion _get_criterion(self, SIZE_t axis)
    cdef Splitter _get_splitter(self, SIZE_t axis)


cdef class MSE_Wrapper2D(RegressionCriterionWrapper2D):
    cdef Criterion _get_criterion(self, SIZE_t axis)


cdef class AxisRegressionCriterion(RegressionCriterion):
    cdef SIZE_t col_start
    cdef SIZE_t col_end
    cdef SIZE_t n_node_cols
    cdef DOUBLE_t weighted_n_node_cols
    cdef SIZE_t* col_samples
    cdef DOUBLE_t* col_sample_weight
    cdef const DOUBLE_t[:, ::1] _original_y

    # Set to True when set_columns is called and to false in call to init.
    # Used to ensure set_columns are always called before init.
    # TODO: consider alternatives if scikit-learn/pull/24678 is merged.
    cdef bint _columns_are_set

    cdef void set_columns(
        self,
        SIZE_t col_start,
        SIZE_t col_end,
        SIZE_t* col_samples,
        DOUBLE_t* col_sample_weight,
    ) nogil