package plrl.binding

test_binds_cluster_stack if {
	bind with input as {
		"stack": {
			"name": "cluster-prod",
		},
	}
}

test_does_not_bind_other_stack if {
	not bind with input as {
		"stack": {
			"name": "prod-network",
		},
	}
}

test_requires_cluster_prefix if {
	not bind with input as {
		"stack": {
			"name": "my-cluster-stack",
		},
	}
}
