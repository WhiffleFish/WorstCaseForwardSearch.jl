Base.@kwdef struct ForwardSearchTree
    b::Vector{SparseVector{Float64,Int}}        = SparseVector{Float64,Int}[]
    admissible_cost::Vector{Float64}            = Float64[] # scalar cost
    b_children::Vector{UnitRange{Int}}          = UnitRange{Int}[]
    ba_children::Vector{UnitRange{Int}}         = UnitRange{Int}[]
    Qba::Vector{Float64}                        = Float64[]
    poba::Vector{Vector{Float64}}               = Vector{Float64}[]
    is_terminal::BitVector                      = BitVector()
    real::Vector{Int}                           = Int[1]
    depth::Vector{Int}                          = Int[0]
    b_pruned::BitVector                         = BitVector()
    ba_pruned::BitVector                        = BitVector()
    rba::Vector{Float64}                        = Float64[] 
    cba::Vector{Vector{Float64}}                = Vector{Float64}[]
    cpomdp::TabularCPOMDP
end

# TODO: make sure we're emptying everything
function Base.empty!(tree::ForwardSearchTree)
    empty!(tree.b)
    empty!(tree.admissible_cost)
    empty!(tree.b_children)
    empty!(tree.ba_children)
    empty!(tree.Qba)
    empty!(tree.poba)
    empty!(tree.is_terminal)
    resize!(tree.real, 1)
    resize!(tree.depth, 1)
    empty!(tree.b_pruned)
    empty!(tree.ba_pruned)
    empty!(tree.rba)
    empty!(tree.cba)
    tree
end

function _initialize_belief(pomdp, dist::Any=initialstate(pomdp))
    ns = length(states(pomdp))
    b = zeros(ns)
    for s in support(dist)
        sidx = stateindex(pomdp, s)
        b[sidx] = pdf(dist, s)
    end
    return sparse(b)
end

const NO_CHILDREN = 1:0

function set_root!(tree, pomdp, b, d::Float64)
    (;cpomdp) = tree
    γ = discount(cpomdp)
    A = actions(cpomdp)
    O = observations(cpomdp)
    n_ba = 0

    empty!(tree)
    b = _initialize_belief(pomdp, b)
    push!(tree.admissible_cost, d)
    push!(tree.b, b)
    push!(tree.is_terminal, false)
    push!(tree.b_pruned, d < 0.0)
    push!(tree.b_children, (n_ba+1) : (n_ba + length(A)))
    
    d_idx = 0
    
    for a ∈ A
        n_b = length(tree.b)
        push!(tree.ba_children, (n_b+1) : (n_b+length(O)) )
        pred = dropzeros!(cpomdp.T[a]*b)
        any_pruned = false
        pobas = zeros(length(O))
        worst_cost = worst_case_cost(tree, b, a)
        d′ = (1/γ)*(d - worst_cost)
        for o ∈ O
            bp = corrector(cpomdp, pred, a, o)
            po = sum(bp)
            po > 0. && (bp.nzval ./= po)
            pobas[o] = po
            terminal = iszero(po) || is_terminal_belief(cpomdp, bp)
            push!(tree.b, bp)
            push!(tree.admissible_cost, d′)
            pruned = d′ < 0.0
            push!(tree.b_pruned, pruned)
            any_pruned = any_pruned || pruned
            push!(tree.depth, d_idx+1)
            push!(tree.is_terminal, terminal)
            push!(tree.b_children, NO_CHILDREN)
        end
        push!(tree.ba_pruned, any_pruned)
        push!(tree.poba, pobas)
        push!(tree.rba, belief_reward(cpomdp, b, a))
    end
end

@inline is_real(tree, b_idx) = b_idx ∈ tree.real

# ---!!! only works for single cost !!!---
function worst_case_cost(cpomdp::TabularCPOMDP, b::SparseVector, a::Int)
    (;C) = cpomdp
    @assert isone(size(C, 3)) # scalar cost only
    max_cost = 0.0
    for s ∈ SparseArrays.nonzeroinds(b)
        max_cost = max(max_cost, C[s,a,1])
    end
    return max_cost
end

function belief_reward(cpomdp::TabularCPOMDP, b::SparseVector, a::Int)
    return dot(@view(cpomdp.R[:,a]), b)
end

worst_case_cost(tree::ForwardSearchTree, b, a) = worst_case_cost(tree.cpomdp, b, a)
