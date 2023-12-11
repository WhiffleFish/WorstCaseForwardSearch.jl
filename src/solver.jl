Base.@kwdef struct WorstCaseForwardSearchSolver{RNG<:Random.AbstractRNG}
    max_time::Float64   = Inf
    max_iter::Int       = 100
    max_depth::Int      = 10
    max_belief::Int     = 10_000
    rng::RNG            = Random.default_rng()
end

struct WorstCaseForwardSearchPlanner{P<:CPOMDP}
    cpomdp::P
    sol::WorstCaseForwardSearchSolver
    tree::ForwardSearchTree
end

POMDPs.solve(sol::WorstCaseForwardSearchSolver, cpomdp) = WorstCaseForwardSearchPlanner(
    cpomdp, 
    sol, 
    ForwardSearchTree(cpomdp=TabularCPOMDP(cpomdp))
)
