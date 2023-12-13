#=
TODO:
- tree distance metric doesn't make sense anymore with admissible cost -- get rid of it
- handle max_expansions
    - Currently expand EVERY real belief which exponentially increases computation time each iter
    - If instead, after number of real beliefs exceeds max_expansions, we just randomly sample
        max_expansions real beliefs and just expand those. Then computation time is pretty much constant in tree size.
=#

Base.@kwdef struct WorstCaseForwardSearchSolver{RNG<:Random.AbstractRNG} <: Solver
    max_time::Float64   = Inf
    max_iter::Int       = 100
    max_depth::Int      = 10
    max_expansions::Int = 1_000
    rng::RNG            = Random.default_rng()
end

struct WorstCaseForwardSearchPlanner{P<:CPOMDP} <: Policy
    cpomdp::P
    sol::WorstCaseForwardSearchSolver
    tree::ForwardSearchTree
end

POMDPs.solve(sol::WorstCaseForwardSearchSolver, cpomdp) = WorstCaseForwardSearchPlanner(
    cpomdp, 
    sol, 
    ForwardSearchTree(cpomdp=TabularCPOMDP(cpomdp))
)
