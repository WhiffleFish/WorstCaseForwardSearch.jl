function POMDPTools.action_info(planner::WorstCaseForwardSearchPlanner, b, d)
    t0 = time()
    (;sol, cpomdp, tree) = planner
    (;max_time, max_iter) = sol
    set_root!(tree, planner.cpomdp, b, d)
    iter = 0
    while (time() - t0 < max_time) && (iter < max_iter)
        expand!(tree, sol)
        iter += 1
    end
    a_idx, Qa = best_action_and_value(tree)
    a = ordered_actions(planner.pomdp)[a_idx]
    return a, (; V=Qa, tree)
end

POMDPs.action(planner::WorstCaseForwardSearchPlanner, b, d) = first(action_info(planner, b, d))
