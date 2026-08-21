resource "plural_policy" "eks_guardrails" {
  name        = "eks-guardrails"
  type        = "STACK"
  description = "Auto-approves cluster stacks that do not destroy EKS clusters or node groups and do not change the cluster version."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/policies/stack/eks_guardrails.rego")
}

resource "plural_policy" "cluster_stacks" {
  name        = "cluster-stacks"
  type        = "BINDING"
  description = "Selects stacks whose names begin with cluster-."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/policies/binding/cluster_stacks.rego")
}

resource "plural_binding_policy" "eks_guardrails_for_clusters" {
  policy_id      = plural_policy.eks_guardrails.id
  bind_policy_id = plural_policy.cluster_stacks.id
  type           = "STACK"
  interval       = "6h"
}
