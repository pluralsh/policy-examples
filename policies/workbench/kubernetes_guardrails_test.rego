package plrl.wb.admission

test_denies_delete_in_kube_system if {
	deny[{"msg": "deleting resources in the kube-system namespace is not allowed"}] with input as {
		"tool_name": "delete_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "coredns",
			"namespace": "kube-system",
		},
		"actor": {
			"groups": ["developers"],
		},
	}
}

test_allows_sre_delete_in_kube_system if {
	count(deny) == 0 with input as {
		"tool_name": "delete_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "coredns",
			"namespace": "kube-system",
		},
		"actor": {
			"groups": ["developers", "sre"],
		},
	}
}

test_denies_sre_delete_in_plrl_console if {
	deny[{"msg": "deleting resources in protected Plural namespaces is not allowed"}] with input as {
		"tool_name": "delete_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "console",
			"namespace": "plrl-console",
		},
		"actor": {
			"groups": ["developers", "sre"],
		},
	}
}

test_denies_sre_delete_in_plrl_deploy_operator if {
	deny[{"msg": "deleting resources in protected Plural namespaces is not allowed"}] with input as {
		"tool_name": "delete_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "deploy-operator",
			"namespace": "plrl-deploy-operator",
		},
		"actor": {
			"groups": ["developers", "sre"],
		},
	}
}

test_allows_delete_outside_kube_system if {
	count(deny) == 0 with input as {
		"tool_name": "delete_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "api",
			"namespace": "default",
		},
		"actor": {
			"groups": ["developers"],
		},
	}
}

test_does_not_deny_other_tools if {
	count(deny) == 0 with input as {
		"tool_name": "get_k8s_resource",
		"tool": {
			"namespace": "kube-system",
		},
		"actor": {
			"groups": ["developers"],
		},
	}
}

test_approves_sre_update_outside_kube_system if {
	approve[{"reason": "SREs may update resources outside the kube-system namespace"}] with input as {
		"tool_name": "update_k8s_resource",
		"tool": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "api",
			"namespace": "default",
		},
		"actor": {
			"groups": ["developers", "sre"],
		},
	}
}

test_does_not_approve_non_sre_update if {
	count(approve) == 0 with input as {
		"tool_name": "update_k8s_resource",
		"tool": {
			"namespace": "default",
		},
		"actor": {
			"groups": ["developers"],
		},
	}
}

test_does_not_approve_sre_update_in_kube_system if {
	count(approve) == 0 with input as {
		"tool_name": "update_k8s_resource",
		"tool": {
			"namespace": "kube-system",
		},
		"actor": {
			"groups": ["sre"],
		},
	}
}
