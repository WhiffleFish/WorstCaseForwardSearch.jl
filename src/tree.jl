Base.@kwdef struct ForwardSearchTree
    b::Vector{SparseVector{Float64,Int}}        = SparseVector{Float64,Int}[]
    admissible_cost::Vector{Vector{Float64}}    = Vector{Float64}[]
    b_children::Vector{UnitRange{Int}}          = UnitRange{Int}[]
    ba_children::Vector{UnitRange{Int}}         = UnitRange{Int}[]
    Qba::Vector{Float64}                        = Float64[]
    is_terminal::BitVector                      = BitVector()
    real::Vector{Int}                           = Int[]
    cpomdp::TabularCPOMDP
end

const NO_CHILDREN = 1:0

@inline is_real(tree, b_idx) = b_idx ∈ tree.real

# ---!!! only works for single cost !!!---
function worst_case_cost(cpomdp::TabularCPOMDP, b::SparseVector, a::Int)
    max_cost = 0.0
    for s ∈ SparseArrays.nonzeroinds(b)
        max_cost = max(max_cost, cpomdp.C[s,a,1])
    end
    return max_cost
end

function expand!(tree::ForwardSearchTree, sol)
    (;cpomdp) = tree
    (;rng) = sol
    A = actions(pomdp)
    O = observations(pomdp)
    for b ∈ enumerate(tree.b)
        
    end
end
