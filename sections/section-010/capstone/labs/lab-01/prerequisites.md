# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read and apply resources and to label a namespace.
- Read a `ClusterImagePolicy` and say what its images, authorities and mode do.
- Run commands in the workstation pod with `kubectl -n workstation exec`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it, and Helm 3.22.1.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8.
- The lab registry `registry.localtest.me:5001` (TLS, lab-only certificate authority) with copies of `podinfo`.
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and the lab-only key pair in `/work/keys` (password `lab-only-password`).
- The namespaces `prod` and `dev`. Starting state: During an outage someone scaled the webhook to zero, set its failure policy to Ignore, set no-match-policy to allow and removed the label from prod.

`jq` on your own machine helps when you read the JSON of a policy.

## Working rules

- Everything is graded on the **final cluster state**, with server-side dry-run
  admissions in `prod` and `dev`.
- Change one thing at a time and test with a dry run after each change.
- The kind node never pulls the lab images; the dry run is how you and the
  grader ask the webhook for its decision.
