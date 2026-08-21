package plrl.stack

# Auto-approves when the plan neither destroys/replaces the EKS cluster or node
# groups nor changes aws_eks_cluster.version. Unsafe plans are left undecided:
# this policy never denies or defers.

eks_types := {"aws_eks_cluster", "aws_eks_node_group"}

destructive_actions := {"delete", "replace"}

destructive_eks_change if {
	some rc in input.plan.resource_changes
	eks_types[rc.type]
	some action in rc.change.actions
	destructive_actions[action]
}

cluster_version_update if {
	some rc in input.plan.resource_changes
	rc.type == "aws_eks_cluster"
	is_object(rc.change.before)
	is_object(rc.change.after)
	rc.change.before.version != rc.change.after.version
}

approve[{"reason": "no destructive EKS cluster or node group changes and no cluster version update"}] if {
	not destructive_eks_change
	not cluster_version_update
}
