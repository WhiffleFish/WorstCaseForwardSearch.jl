function best_action_and_value(tree)
    max_a = 0
    maxQ = -Inf
    for (a_idx, ba_idx) ∈ enumerate(tree.b_children[1])
        Qba = action_value(tree, ba_idx)
        if Qba > maxQ
            max_a = a_idx
            maxQ = Qba
        end
    end
    return max_a, maxQ
end

function belief_value(tree, b_idx)
    maxQ = -Inf
    tree.b_pruned[b_idx] && return -Inf
    for ba_idx ∈ tree.b_children[b_idx]
        Qba = action_value(tree, ba_idx)
        maxQ = max(maxQ, Qba)
    end
    return maxQ
end

function action_value(tree, ba_idx)
    (;cpomdp) = tree
    tree.ba_pruned[ba_idx] && return -Inf
    γ = discount(cpomdp)
    Q = tree.rba[ba_idx]
    for (poba, bp_idx) ∈ zip(tree.poba[ba_idx],tree.ba_children[ba_idx])
        d′ = tree.admissible_cost[bp_idx]
        if d′ < 0.0
            return -Inf
        elseif !isempty(tree.b_children[bp_idx])
            Q += γ * poba*belief_value(tree, bp_idx)
        end # otherwise there are no children and therefore no future value
    end
    return Q
end
