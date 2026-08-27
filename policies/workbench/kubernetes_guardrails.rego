package plrl.wb.admission

actor_is_sre if {
	input.actor.groups[_] == "sre"
}

deny[{"msg": "deleting resources in the kube-system namespace is not allowed"}] if {
	input.tool_name == "delete_k8s_resource"
	input.tool.namespace == "kube-system"
	not actor_is_sre
}

deny[{"msg": "deleting resources in protected Plural namespaces is not allowed"}] if {
	input.tool_name == "delete_k8s_resource"
	input.tool.namespace in {"plrl-console", "plrl-deploy-operator"}
}

approve[{"reason": "SREs may update resources outside the kube-system namespace"}] if {
	input.tool_name == "update_k8s_resource"
	input.tool.namespace != "kube-system"
	actor_is_sre
}
