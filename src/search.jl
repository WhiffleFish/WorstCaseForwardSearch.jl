function POMDPTools.action_info(planner::WorstCaseForwardSearchPlanner, b, d)
    (;sol, cpomdp) = planner
    (;max_time, max_iter) = sol
    t0 = time()
    iter = 0
    while (time() - t0 < max_time) && (iter < max_iter)

        iter += 1
    end
    return 1
end

POMDPs.action(planner::WorstCaseForwardSearchPlanner, b, d) = first(action_info(planner, b, d))
