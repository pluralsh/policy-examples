# Plural policy examples

A minimal repository for testing [Rego](https://www.openpolicyagent.org/docs/policy-language)
policies and publishing them to Plural with
[Terraform](https://github.com/pluralsh/terraform-provider-plural).

The included workbench policy denies Kubernetes deletes in the `kube-system`
namespace. A binding policy automatically attaches it to workbenches whose
names begin with `demo-`.

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
	input.input.some_field == "some-value"
}
```

Plural passes workbench tool arguments under `input.input`. It may also provide
the current user under `input.actor`. Any value added to `deny` blocks the tool
call. Denials must be objects with a `msg` string, which Plural presents as the
reason. Values added to `approve` require an approval before the tool runs.

The example policy is attached only to the workbench `delete_k8s_resource`
tool. The Terraform binding uses the tool match expression
`^delete_k8s_resource$`. Tool matching determines when a policy runs; the Rego
file receives the tool arguments, not the tool name.

### Binding policies

Binding policies use the `plrl.binding` package and set `bind` from the target
workbench itself:

```rego
package plrl.binding

bind if {
	startswith(input.name, "demo-")
}
```

Plural periodically evaluates this policy for workbenches in the project. A
true result attaches the associated workbench policy; a false result removes
it. The Terraform `plural_binding_policy` resource connects the workbench
policy, binding policy, and tool match expressions.

## Test policies locally

Install the [OPA CLI](https://www.openpolicyagent.org/docs/latest/#running-opa)
and run:

```sh
opa fmt --fail policies
opa test --verbose policies
```

Tests live beside each policy and end in `_test.rego`. Add both denied and
allowed cases whenever a policy changes.

## Publish policies with Terraform

The configuration in `terraform/main.tf` uses the `plural_policy` resource and
loads the Rego source directly from `policies/`. Authenticate with environment
variables so credentials do not enter Terraform source or variable files:

```sh
export PLURAL_CONSOLE_URL="https://console.example.com"
export PLURAL_ACCESS_TOKEN="..."

terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

The access token needs permission to manage policies in the selected project.
For local use, the provider can alternatively read credentials from `plural cd
login` by setting `PLURAL_USE_CLI=true`.

The example looks up the Plural project named `default`. Change the
`plural_project` data source if policies belong to another project. Terraform
creates both policies and reconciles the workbench attachments hourly. Before
using this repository with a team, configure a remote Terraform backend so
state is shared and protected.

## CI

`.github/workflows/test.yaml` runs on every pull request and on pushes to
`main`. It checks Rego formatting and runs all OPA tests.

CI does not apply Terraform and therefore needs no Plural credentials. Apply
from your normal infrastructure delivery workflow after review.

## Add another policy

1. Add `policies/workbench/<name>.rego` using the `plrl.wb.admission` package.
2. Add `policies/workbench/<name>_test.rego` with denied and allowed inputs.
3. Add another `plural_policy` resource in `terraform/main.tf` whose `policy`
   reads the new file.
4. Reuse or add a policy under `policies/binding/`, then connect the two with a
   `plural_binding_policy` resource and the appropriate tool regexes.
5. Run the OPA and Terraform checks locally.