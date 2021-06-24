module IntervalLinearAlgebra

using StaticArrays, Requires, Reexport

import CommonSolve: solve
import IntervalArithmetic: mid

function  __init__()
    @require IntervalConstraintProgramming = "138f1668-1576-5ad7-91b9-7425abbf3153" include("solvers/oettli.jl")
    @require LazySets = "b4f0291d-fe17-52bc-9479-3d1a343d9043" include("solvers/oettli_linear.jl")
end

@reexport using LinearAlgebra, IntervalArithmetic

export
    LinearKrawczyk, Jacobi, GaussSeidel, GaussianElimination, HansenBliekRohn, NonLinearOettliPrager, LinearOettliPrager,
    NoPrecondition, InverseMidpoint, InverseDiagonalMidpoint,
    solve, enclose, epsilon_inflation,
    comparison_matrix, interval_norm, interval_isapprox, list_orthants,
    is_H_matrix, is_strongly_regular, is_strictly_diagonally_dominant, is_Z_matrix, is_M_matrix,
    rref


include("solvers/hull.jl")
include("solvers/precondition.jl")
include("solvers/solve.jl")
include("solvers/verify.jl")

include("utils.jl")
include("classify.jl")
include("rref.jl")
end
