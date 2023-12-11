function expand!(tree::ForwardSearchTree, sol)
    (;cpomdp) = tree
    (;rng) = sol
    A = actions(cpomdp)
    O = observations(cpomdp)
    for b_idx ∈ tree.real
        tree.is_terminal[b_idx] && continue
        tree.b_pruned[b_idx] && continue
        b_children = tree.b_children[b_idx]
        # if all(tree.ba_pruned[ba_idx])
            # tree.b_pruned[b_idx] = true
            # continue
        # end
        d_max = 0.0
        bp_idx_max = 0
        for a ∈ A
            ba_idx = b_children[a]
            tree.ba_pruned[ba_idx] && continue
            o = rand(rng, O) # TODO: make this belief dependent
            bp_idx = tree.ba_children[ba_idx][o]
            bp = tree.b[bp_idx]
            # TODO: check if bp already expanded -- then we don't need to query distance
            d = distance_to_tree(tree, bp)
            if d > d_max
                d_max = d
                bp_idx_max = bp_idx
            end
        end
        d_max > 0. && expand!(tree, sol, bp_idx_max)
    end
end

function expand!(tree, sol, b_idx::Int)
    if !is_real(tree, b_idx)
        push!(tree.real, b_idx)
        if !tree.is_terminal[b_idx]
            expand_belief!(tree, sol, b_idx)
        end
    end
end

function expand_belief!(tree, sol, b_idx::Int)
    (;cpomdp) = tree
    γ = discount(cpomdp)
    b = tree.b[b_idx]
    A = actions(cpomdp)
    O = observations(cpomdp)
    n_ba = length(tree.ba_children)
    tree.b_children[b_idx] = (n_ba+1) : (n_ba + length(A))
    d_idx = tree.depth[b_idx]
    for a ∈ A
        length(tree.b) >= sol.max_belief && break
        n_b = length(tree.b)
        push!(tree.ba_children, (n_b+1) : (n_b+length(O)) )
        pred = dropzeros!(cpomdp.T[a]*b)
        any_pruned = false
        pobas = zeros(length(O))
        worst_cost = worst_case_cost(tree, b, a)
        d′ = (1/γ)*(tree.admissible_cost[b_idx] - worst_cost)
        for o ∈ O
            length(tree.b) >= sol.max_belief && break
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

function distance_to_tree(tree, b′)
    d_min = Inf
    for b_idx in tree.real
        b = tree.b[b_idx]
        d = sparse_vec_norm_diff(b, b′)
        d < d_min && (d_min = d)
    end
    return d_min
end

function sparse_vec_norm_diff(x::SparseVector, y::SparseVector)
    xnzind = SparseArrays.nonzeroinds(x)
    xnzval = SparseArrays.nonzeros(x)
    ynzind = SparseArrays.nonzeroinds(y)
    ynzval = SparseArrays.nonzeros(y)
    mx = length(xnzind)
    my = length(ynzind)

    return _sparse_vec_norm_diff(mx, my, xnzind, xnzval, ynzind, ynzval)
end

function _sparse_vec_norm_diff(mx::Int, my::Int,
                            xnzind, xnzval::AbstractVector{Tx},
                            ynzind, ynzval::AbstractVector{Ty}) where {Tx,Ty}
    # f(nz, nz) -> z/nz, f(z, nz) -> nz, f(nz, z) -> nz
    cum_v = 0.0
    ix = 1; iy = 1
    @inbounds while ix <= mx && iy <= my
        jx = xnzind[ix]
        jy = ynzind[iy]
        if jx == jy
            cum_v += abs2(xnzval[ix] - ynzval[iy])
            ix += 1; iy += 1
        elseif jx < jy
            cum_v += abs2(xnzval[ix] - zero(Ty))
            ix += 1
        else
            cum_v += abs2(zero(Tx) - ynzval[iy])
            iy += 1
        end
    end
    @inbounds while ix <= mx
        cum_v += abs2(xnzval[ix] - zero(Ty))
        ix += 1
    end
    @inbounds while iy <= my
        cum_v += abs2(zero(Tx) - ynzval[iy])
        iy += 1
    end
    return cum_v
end
