# Plural policy examples

A minimal repository for testing [Rego](https://www.openpolicyagent.org/docs/policy-language)
policies and publishing them to Plural with
[Terraform](https://github.com/pluralsh/terraform-provider-plural).

The included workbench policy denies Kubernetes deletes in the `kube-system`
namespace.

## Repository layout

```text
.
├── .github/workflows/test.yaml
├── policies/
│   ├── deny_kube_system_deletes.rego
│   └── deny_kube_system_deletes_test.rego
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

The example policy is intended to be attached only to the workbench
`delete_k8s_resource` tool. When attaching it to a workbench in Plural, use the
tool match expression `^delete_k8s_resource$`. Tool matching determines when a
policy runs; the Rego file receives the tool arguments, not the tool name.

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
terraform -chdir=terraform plan -var="project_id=<plural-project-id>"
terraform -chdir=terraform apply -var="project_id=<plural-project-id>"
```

The access token needs permission to manage policies in the selected project.
For local use, the provider can alternatively read credentials from `plural cd
login` by setting `PLURAL_USE_CLI=true`.

Terraform creates and updates the project-scoped policy. Attaching that policy
to a specific workbench and its matching tools is currently configured in
Plural separately. Before using this repository with a team, configure a remote
Terraform backend so state is shared and protected.

## CI

`.github/workflows/test.yaml` runs on every pull request and on pushes to
`main`. It checks Rego formatting and runs all OPA tests.

CI does not apply Terraform and therefore needs no Plural credentials. Apply
from your normal infrastructure delivery workflow after review.

## Add another policy

1. Add `policies/<name>.rego` using the `plrl.wb.admission` package.
2. Add `policies/<name>_test.rego` with denied and allowed inputs.
3. Add another `plural_policy` resource in `terraform/main.tf` whose `policy`
   reads the new file.
4. Run the OPA and Terraform checks locally, then attach the resulting policy
   to the appropriate workbench tools in Plural.