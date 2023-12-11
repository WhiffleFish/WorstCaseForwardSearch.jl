function backup!(tree)
    A = actions(tree)
    for b_idx ∈ tree.real
        b_children = tree.b_children[b_idx]
        for a ∈ A
            ba_idx = b_children[a]
            ba_children = tree.ba_children[ba_idx]
        end
    end
    tree
end
