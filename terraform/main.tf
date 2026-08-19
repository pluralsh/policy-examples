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

resource "plural_policy" "deny_kube_system_deletes" {
  name        = "deny-kube-system-deletes"
  type        = "WORKBENCH"
  description = "Guards Kubernetes deletes and automatically approves safe SRE updates."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/../policies/workbench/deny_kube_system_deletes.rego")
}

resource "plural_policy" "demo_workbenches" {
  name        = "demo-workbenches"
  type        = "BINDING"
  description = "Selects workbenches whose names begin with demo-."
  project_id  = data.plural_project.project.id
  policy      = file("${path.module}/../policies/binding/demo_workbenches.rego")
}

resource "plural_binding_policy" "deny_kube_system_deletes_for_demos" {
  policy_id      = plural_policy.deny_kube_system_deletes.id
  bind_policy_id = plural_policy.demo_workbenches.id
  type           = "WORKBENCH"
  interval       = "1h"

  matches = {
    workbench = {
      regexes = [
        "^delete_k8s_resource$",
        "^update_k8s_resource$",
      ]
    }
  }
}

output "deny_kube_system_deletes_policy_id" {
  description = "ID of the policy created in Plural."
  value       = plural_policy.deny_kube_system_deletes.id
}

output "binding_policy_id" {
  description = "ID of the binding that attaches the policy to demo workbenches."
  value       = plural_binding_policy.deny_kube_system_deletes_for_demos.id
}
