package plrl.binding

test_binds_demo_workbench if {
	bind with input as {
		"name": "demo-production-operations",
	}
}

test_does_not_bind_other_workbench if {
	not bind with input as {
		"name": "production-operations",
	}
}

test_requires_demo_prefix if {
	not bind with input as {
		"name": "my-demo-workbench",
	}
}
