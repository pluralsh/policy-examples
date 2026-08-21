package plrl.stack

eks_cluster(actions, before, after) := {
	"address": "module.eks.aws_eks_cluster.this[0]",
	"type": "aws_eks_cluster",
	"name": "this",
	"change": {
		"actions": actions,
		"before": before,
		"after": after,
	},
}

eks_node_group(actions, before, after) := {
	"address": "module.eks.aws_eks_node_group.this[\"default\"]",
	"type": "aws_eks_node_group",
	"name": "this",
	"change": {
		"actions": actions,
		"before": before,
		"after": after,
	},
}

iam_role(actions) := {
	"address": "aws_iam_role.cluster",
	"type": "aws_iam_role",
	"name": "cluster",
	"change": {
		"actions": actions,
		"before": {"name": "cluster"},
		"after": {"name": "cluster"},
	},
}

plan(changes) := {"plan": {"resource_changes": changes}}

cluster_before := {"name": "prod", "version": "1.31"}

node_group_before := {"cluster_name": "prod", "instance_types": ["m5.large"]}

node_group_after := {"cluster_name": "prod", "instance_types": ["m5.large"]}

test_approves_when_eks_changes_are_not_destructive if {
	approve[{"reason": "no destructive EKS cluster or node group changes and no cluster version update"}] with input as plan([
		eks_cluster(["update"], cluster_before, {"name": "prod", "version": "1.31", "tags": {"env": "prod"}}),
		eks_node_group(["update"], node_group_before, {"cluster_name": "prod", "instance_types": ["m5.xlarge"]}),
		iam_role(["update"]),
	])
}

test_approves_when_plan_has_no_eks_resources if {
	approve[{"reason": "no destructive EKS cluster or node group changes and no cluster version update"}] with input as plan([iam_role(["create"])])
}

test_approves_empty_plan if {
	approve[{"reason": "no destructive EKS cluster or node group changes and no cluster version update"}] with input as plan([])
}

test_does_not_approve_cluster_delete if {
	count(approve) == 0 with input as plan([
		eks_cluster(["delete"], cluster_before, null),
	])
}

test_does_not_approve_node_group_delete if {
	count(approve) == 0 with input as plan([
		eks_node_group(["delete"], node_group_before, null),
	])
}

test_does_not_approve_node_group_replace if {
	count(approve) == 0 with input as plan([
		eks_node_group(["delete", "create"], node_group_before, node_group_after),
	])
}

test_does_not_approve_cluster_version_update if {
	count(approve) == 0 with input as plan([
		eks_cluster(["update"], cluster_before, {"name": "prod", "version": "1.32"}),
	])
}
