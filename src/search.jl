function POMDPTools.action_info(planner::WorstCaseForwardSearchPlanner, b, d::Real)
    t0 = time()
    (;sol, cpomdp, tree) = planner
    (;max_time, max_iter) = sol
    set_root!(tree, cpomdp, b, d)
    iter = 0
    while (time() - t0 < max_time) && (iter < max_iter)
        expand!(tree, sol)
        iter += 1
    end
    a_idx, Qa = best_action_and_value(tree)
    a = ordered_actions(cpomdp)[a_idx]
    return a, (; V=Qa, tree)
end

POMDPs.action(planner::WorstCaseForwardSearchPlanner, b, d::Real) = first(action_info(planner, b, d))
POMDPs.action(planner::WorstCaseForwardSearchPlanner, b, d::AbstractVector) = first(action_info(planner, b, only(d)))
