# Prerequisites

Before starting this lab you should be able to:

- Write a `ClusterImagePolicy` with a key authority and an image glob.
- Create a Secret from a public key file and reference it from a policy.
- Use server-side dry runs to ask the webhook for a decision.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it, and Helm 3.22.1.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8.
- The lab registry `registry.localtest.me:5001` (TLS, lab-only certificate authority) with copies of `podinfo`.
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and the lab-only key pair in `/work/keys` (password `lab-only-password`).
- The namespaces `prod` and `dev`. Starting state: the broad policy `all-images` trusts only the lab key for the whole registry; `inventory/podinfo:6.15.0` is signed with the lab key, `6.14.0` is unsigned; `tools/podinfo:6.15.0` is signed with the tools key and `tools/podinfo:6.14.1` with the lab key; the Secret `tools-public-key` in `cosign-system` holds the tools public key.
- The tools key pair is in `/work/tools` in the workstation pod.

## Working rules

- Everything is graded on the **final cluster state**, with server-side dry-run
  admissions in `prod`.
- Change one thing at a time and test with a dry run after each change.
- The kind node never pulls the lab images; the dry run is how you and the
  grader ask the webhook for its decision.
