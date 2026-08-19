package plrl.wb.admission

deny[{"msg": "deleting resources in the kube-system namespace is not allowed"}] if {
	input.input.namespace == "kube-system"
}
