abstract type LinearSolver end

abstract type DirectSolver <: LinearSolver end

abstract type IterativeSolver <: LinearSolver end

"""
    HansenBliekRohn()

Returns a Hansen-Bliek-Rohn solver for the interval linear system Ax=b.
"""
struct HansenBliekRohn <: DirectSolver end

function (hbr::HansenBliekRohn)(A, b)
    n = length(b)
    compA = comparison_matrix(A)
    compA_inv = inv(compA)
    u = compA_inv*mag.(b)
    d = diag(compA_inv)
    α = diag(compA) .- 1 ./d
    α = Interval.(-α, α) #TODO: probably directed rounded is needed here, need to check
    β = @. u/d - mag(b)
    β = Interval.(-β, β)
    x = (b .+ β)./(diag(A) .+ α)

end

"""
    GaussElimination <: LinearSolver

Returns a Gaussian elimination solver for the interval linear system Ax=b.
"""
struct GaussElimination <: DirectSolver end

function (ge::GaussElimination)(A, b)
    n = length(b)
    Abrref = rref([A b])

    # backsubstitution
    x = similar(b)
    x[end] = Abrref[n, n+1]/Abrref[n, n]
    @inbounds for i = n-1:-1:1
        x[i] = (Abrref[i, n+1] - sum(Abrref[i, j]*x[j] for j in i+1:n))/Abrref[i, i]
    end
    return x
end


## JACOBI
"""
    Jacobi(max_iterations, atol)

Returns a Jacobi solver for the interval linear system Ax=b.

PARAMETERS:

max_iterations: maximum number of iterations (default 20)

atol: absolute tolerance (default 0), if at some point `|xₖ - xₖ₊₁| < atol` (elementwise), then stop and return xₖ₊₁.
    If atol=0, then `min(diam(A))*1e-5` is used.
"""
struct Jacobi <: IterativeSolver
    max_iterations::Int
    atol::Float64
end

Jacobi() = Jacobi(20, 0.0)

function (jac::Jacobi)(x, A, b)

    n = length(b)
    atol = iszero(jac.atol) ? minimum(diam.(A))*1e-5 : jac.atol

    for _ in 1:jac.max_iterations
        xold = copy(x)
        @inbounds @simd for i in 1:n
            x[i] = b[i]
            for j in 1:n
                (i == j) || (x[i] -= A[i, j] * xold[j])
            end
            x[i] = (x[i]/A[i, i]) ∩ xold[i]
        end
        all(interval_isapprox.(x, xold; atol=atol)) && break
    end
    nothing
end

## GAUSS SEIDEL
"""
    GaussSeidel(max_iterations, atol)

Returns a Gauss-Seidel solver for the interval linear system Ax=b.

PARAMETERS:

max_iterations: maximum number of iterations (default 20)

atol: absolute tolerance (default 0), if at some point `|xₖ - xₖ₊₁| < atol` (elementwise), then stop and return xₖ₊₁.
    If atol=0, then `min(diam(A))*1e-5` is used.
"""
struct GaussSeidel <: IterativeSolver
    max_iterations::Int
    atol::Float64
end

GaussSeidel() = GaussSeidel(20, 0.0)

function (gs::GaussSeidel)(x, A, b)
    n = length(b)

    atol = iszero(gs.atol) ? minimum(diam.(A))*1e-5 : gs.atol
    @inbounds for _ in 1:gs.max_iterations
        xold = copy(x)
        @inbounds for i in 1:n
            x[i] = b[i]
            @inbounds for j in 1:n
                (i == j) || (x[i] -= A[i, j] * x[j])
            end
            x[i] = (x[i]/A[i, i]) .∩ xold[i]
        end
        all(interval_isapprox.(x, xold; atol=atol)) && break
    end
    nothing
end

## KRAWCZYK
"""
    Krawczyk(max_iterations, atol)

Returns a Krawczyk solver for the interval linear system Ax=b.

PARAMETERS:

max_iterations: maximum number of iterations (default 20)

atol: absolute tolerance (default 0), if at some point `|xₖ - xₖ₊₁| < atol` (elementwise), then stop and return xₖ₊₁.
    If atol=0, then `min(diam(A))*1e-5` is used.
"""
struct Krawczyk <: IterativeSolver
    max_iterations::Int
    atol::Float64
end

Krawczyk() = Krawczyk(20, 0.0)

function (kra::Krawczyk)(x, A, b)

    atol = iszero(kra.atol) ? minimum(diam.(A))*1e-5 : kra.atol

    C = inv(mid.(A))
    for i = 1:kra.max_iterations
        xnew  = (C*b  - C*(A*x) + x) .∩ x
        all(interval_isapprox.(x, xnew; atol=atol)) && return xnew
        x = xnew
    end
    return x
end

# custom printing for solvers
function Base.string(s::LinearSolver)

    str="""$(typeof(s)) linear solver
    """

    fields = fieldnames(typeof(s))
    for field in fields
        str *= """$field = $(getfield(s, field))
        """
    end
    return str
end

Base.show(io::IO, s::LinearSolver) = print(io, string(s))