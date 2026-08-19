terraform {
  required_version = ">= 1.5.0"

  required_providers {
    plural = {
      source  = "pluralsh/plural"
      version = "~> 0.2.39"
    }
  }
}

provider "plural" {}

data "plural_project" "project" {
  name = "default"
}

resource "plural_policy" "kubernetes_guardrails" {
  name        = "kubernetes-guardrails"
  type        = "WORKBENCH"
  description = "Guards Kubernetes deletes and automatically approves safe SRE updates."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/policies/workbench/kubernetes_guardrails.rego")
}

resource "plural_policy" "demo_workbenches" {
  name        = "demo-workbenches"
  type        = "BINDING"
  description = "Selects workbenches whose names begin with demo-."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/policies/binding/demo_workbenches.rego")
}

resource "plural_binding_policy" "kubernetes_guardrails_for_demos" {
  policy_id      = plural_policy.kubernetes_guardrails.id
  bind_policy_id = plural_policy.demo_workbenches.id
  type           = "WORKBENCH"
  interval       = "6h"
}
