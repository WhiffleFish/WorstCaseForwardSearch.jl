function is_terminal_belief(pomdp::TabularCPOMDP, b)
    return dot(pomdp.isterminal, b) ≈ 1.0
end

function predictor(pomdp::TabularCPOMDP, b::SparseVector, a::Int)
    return predictor!(similar(b), pomdp, b, a)
end

function predictor!(cache, pomdp::TabularCPOMDP, b::SparseVector, a::Int)
    return mul!(cache, pomdp.T[a], b)
end

function corrector(pomdp::TabularCPOMDP, pred::AbstractVector, a, o::Int)
    return _sparse_col_mul(pred, pomdp.O[a], o)
end

"""
Faster x .* @view(A[:,col])
where `x::SparseVector` and `A::SparseMatrixCSC`
"""
function _sparse_col_mul(x::SparseVector{T}, A::SparseMatrixCSC{T}, col::Int) where T
    n = length(x)
    xnzind = SparseArrays.nonzeroinds(x)
    xnzval = SparseArrays.nonzeros(x)

    Anzr = nzrange(A, col)
    Anzval = @view nonzeros(A)[Anzr]
    Anzind = @view rowvals(A)[Anzr]

    mx = length(xnzind)
    mA = length(Anzr)

    cap = min(mx,mA)
    rind = zeros(Int, cap)
    rval = zeros(T, cap)
    ir = 0
    ix = 1
    iy = 1

    ir = SparseArrays._binarymap_mode_0!(*, mx, mA, xnzind, xnzval, Anzind, Anzval, rind, rval)
    resize!(rind, ir)
    resize!(rval, ir)
    return SparseVector(n, rind, rval)
end
