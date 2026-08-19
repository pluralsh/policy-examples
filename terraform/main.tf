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

variable "project_id" {
  description = "ID of the Plural project that owns the policies."
  type        = string
}

resource "plural_policy" "deny_kube_system_deletes" {
  name        = "deny-kube-system-deletes"
  type        = "WORKBENCH"
  description = "Prevents workbench agents from deleting Kubernetes resources in kube-system."
  project_id  = var.project_id
  policy      = file("${path.module}/../policies/deny_kube_system_deletes.rego")
}

output "deny_kube_system_deletes_policy_id" {
  description = "ID of the policy created in Plural."
  value       = plural_policy.deny_kube_system_deletes.id
}
