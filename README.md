# Plural policy examples

A minimal repository for testing [Rego](https://www.openpolicyagent.org/docs/policy-language)
policies and publishing them to Plural with
[Terraform](https://github.com/pluralsh/terraform-provider-plural).

## Repository layout

```text
.
├── .github/workflows/test.yaml
├── policies/
│   ├── binding/
│   │   ├── cluster_stacks.rego
│   │   ├── cluster_stacks_test.rego
│   │   ├── demo_workbenches.rego
│   │   └── demo_workbenches_test.rego
│   ├── stack/
│   │   ├── eks_guardrails.rego
│   │   └── eks_guardrails_test.rego
│   └── workbench/
│       ├── kubernetes_guardrails.rego
│       └── kubernetes_guardrails_test.rego
└── terraform/
    ├── main.tf
    ├── stack.tf
    ├── workbench.tf
    └── policies -> ../policies
```

This is a pretty straightforward policy set just for demo purposes.  Workbench policies enforce workbench tool access, stack policies automate infrastructure-stack approvals, and binding policies attach those policies to Plural objects like workbenches or stacks. In all it should provide a scalable foundation for authorizing tool use and even automating approvals throughout your use of Plural's agentic solutions.

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

### Stack policies

Plural stack policies use the `plrl.stack.approval` package. They receive a
reduced Terraform plan plus stack and actor metadata:

- `input.plan.resource_changes`: address, type, name, provider, and `change.{actions, before, after}`
- `input.run_type`: `plan`, `apply`, or `destroy`
- `input.stack`: stack name, project, and git metadata
- `input.actor`: the current user, including a `groups` array when available

The EKS example auto-approves when the plan does not destroy or replace
`aws_eks_cluster` / `aws_eks_node_group` resources and does not change the
cluster Kubernetes version. It does not deny or defer otherwise, so unsafe
plans fall through to human or AI approval. The binding policy attaches it
only to stacks whose names begin with `cluster-`.

## Test policies

See [`.github/workflows/test.yaml`](.github/workflows/test.yaml) for the OPA
version, formatting check, and test command used by this repository. Tests live
beside each policy and end in `_test.rego`.

## Deploy as a Plural stack

The Terraform configuration creates the policies and binding. Deploy it as an
`InfrastructureStack` so Plural can manage it.  Note we symlink policies into the `terraform` directory since plural only delivers the `spec.git.folder` subdir to terraform to use.

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
  actor: console@plural.sh  # leverages built in plural provider auth
  cluster: mgmt
  git:
	url: https://github.com/your-org/policy-examples.git
    ref: main
    folder: terraform
```

## Add another policy

1. Add `policies/workbench/<name>.rego` using the `plrl.wb.admission` package,
   or `policies/stack/<name>.rego` using `plrl.stack.approval`.
2. Add a matching `*_test.rego` with denied, allowed, and approval cases.
3. Add another `plural_policy` resource in `terraform/workbench.tf` or
   `terraform/stack.tf` whose `policy` reads the new file (`WORKBENCH` or `STACK`).
4. Reuse or add a policy under `policies/binding/`, then connect the two with a
   `plural_binding_policy` resource (`WORKBENCH` or `STACK`) and any workbench
   tool match expressions.
5. Use the repository workflow as the source of truth for formatting and tests.