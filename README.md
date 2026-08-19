# Plural policy examples

A minimal repository for testing [Rego](https://www.openpolicyagent.org/docs/policy-language)
policies and publishing them to Plural with
[Terraform](https://github.com/pluralsh/terraform-provider-plural).

The included workbench policy denies Kubernetes deletes in the `kube-system`
namespace unless the actor belongs to the `sre` group. It also automatically
approves Kubernetes updates by SREs outside `kube-system`. A binding policy
automatically attaches these guardrails to workbenches whose names begin with
`demo-`.

## Repository layout

```text
.
├── .github/workflows/test.yaml
├── policies/
│   ├── binding/
│   │   ├── demo_workbenches.rego
│   │   └── demo_workbenches_test.rego
│   └── workbench/
│       ├── deny_kube_system_deletes.rego
│       └── deny_kube_system_deletes_test.rego
└── terraform/main.tf
```

## Policy format

Plural workbench policies use the `plrl.wb.admission` package and add decisions
to either the `deny` or `approve` set:

```rego
package plrl.wb.admission

deny[{"msg": "a useful reason for the denial"}] if {
	input.tool_name == "some_tool"
	input.tool.some_field == "some-value"
}
```

Plural provides:

- `input.tool_name`: the name of the tool being evaluated
- `input.tool`: the tool arguments
- `input.actor`: the current user, including a `groups` array when available

Any value added to `deny` blocks the tool call. Denials must contain a `msg`
string. Values added to `approve` automatically approve tools that support
approval and use the decision's `reason` in the audit trail.

The example explicitly checks `delete_k8s_resource` and
`update_k8s_resource`. The Terraform binding includes both exact tool-name
matches so the policy is evaluated for both operations.

### Binding policies

Binding policies use the `plrl.binding` package and set `bind` from the target
workbench itself:

```rego
package plrl.binding

bind if {
	startswith(input.workbench.name, "demo-")
}
```

Plural periodically evaluates this policy for workbenches in the project. A
true result attaches the associated workbench policy; a false result removes
it. The Terraform `plural_binding_policy` resource connects the workbench
policy, binding policy, and tool match expressions.

## Test policies

See [`.github/workflows/test.yaml`](.github/workflows/test.yaml) for the OPA
version, formatting check, and test command used by this repository. Tests live
beside each policy and end in `_test.rego`.

## Deploy as a Plural stack

The configuration in `terraform/main.tf` loads the Rego files and creates the
workbench policy, binding policy, and binding. The recommended deployment is an
`InfrastructureStack`, which gives the Terraform configuration managed state,
plans, approvals, and Plural credentials at runtime.

Create or reuse `GitRepository` and `Cluster` resources, then point an
`InfrastructureStack` at this repository's `terraform` directory:

```yaml
apiVersion: deployments.plural.sh/v1alpha1
kind: GitRepository
metadata:
  name: policy-examples
  namespace: infra
spec:
  url: https://github.com/your-org/policy-examples.git
---
apiVersion: deployments.plural.sh/v1alpha1
kind: InfrastructureStack
metadata:
  name: policy-examples
  namespace: infra
spec:
  name: policy-examples
  type: TERRAFORM
  approval: true
  manageState: true
  repositoryRef:
    name: policy-examples
    namespace: infra
  clusterRef:
    name: mgmt
    namespace: infra
  git:
    ref: main
    folder: terraform
```

Replace the repository URL and `clusterRef` with resources from your management
cluster. The stack runner supplies `PLURAL_CONSOLE_URL` and
`PLURAL_ACCESS_TOKEN`; do not commit them to Terraform variables or manifests.

The example looks up the Plural project named `default`. Change the
`plural_project` data source in `terraform/main.tf` if the policies belong to
another project. The binding is reconciled hourly.

## Add another policy

1. Add `policies/workbench/<name>.rego` using the `plrl.wb.admission` package.
2. Add `policies/workbench/<name>_test.rego` with denied and allowed inputs.
3. Add another `plural_policy` resource in `terraform/main.tf` whose `policy`
   reads the new file.
4. Reuse or add a policy under `policies/binding/`, then connect the two with a
   `plural_binding_policy` resource and the appropriate tool regexes.
5. Add denied, allowed, and approval cases to the policy tests; use the
   repository workflow as the source of truth.