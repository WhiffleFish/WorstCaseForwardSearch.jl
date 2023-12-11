begin
    using Pkg
    Pkg.activate(dirname(@__DIR__))
    using WorstCaseForwardSearch
    using ConstrainedPOMDPs
    using POMDPs
    Pkg.activate(@__DIR__)
    using POMDPModels
end

cpomdp = constrain(TigerPOMDP(),[5.0]) do s,a
    isone(a) ? [1.0] : [0.0]
end

sol = WorstCaseForwardSearchSolver()
planner = solve(sol, cpomdp)
tree = planner.tree
b0 = initialstate(cpomdp)
d = 1.0
WorstCaseForwardSearch.set_root!(tree, cpomdp, b0, d)
WorstCaseForwardSearch.expand!()
