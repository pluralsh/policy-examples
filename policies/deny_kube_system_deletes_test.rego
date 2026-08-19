package plrl.wb.admission

test_denies_delete_in_kube_system if {
	deny[{"msg": "deleting resources in the kube-system namespace is not allowed"}] with input as {
		"input": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "coredns",
			"namespace": "kube-system",
		},
	}
}

test_allows_delete_outside_kube_system if {
	count(deny) == 0 with input as {
		"input": {
			"cluster": "production",
			"kind": "Deployment",
			"name": "api",
			"namespace": "default",
		},
	}
}

test_allows_cluster_scoped_delete if {
	count(deny) == 0 with input as {
		"input": {
			"cluster": "production",
			"kind": "Namespace",
			"name": "staging",
		},
	}
}
