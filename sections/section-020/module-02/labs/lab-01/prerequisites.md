# Prerequisites

Before starting this lab you should be able to:

- Write a `ClusterImagePolicy` with a key authority and an image glob.
- Sign an image with `cosign sign --key` and read a verification error.
- Use server-side dry runs to ask the webhook for a decision.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it, and Helm 3.22.1.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8.
- The lab registry `registry.localtest.me:5001` (TLS, lab-only certificate authority) with copies of `podinfo`.
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and the lab-only key pair in `/work/keys` (password `lab-only-password`).
- The namespaces `prod` and `dev`. Starting state: inventory-signed trusts only the old key; releases are signed with the old key, the new key and an unapproved key; the Secrets `inventory-public-key` (old) and `inventory-public-key-next` (new) exist.
- The new key pair is in `/work/next` and the unapproved one in `/work/other` in the workstation pod.

## Working rules

- Everything is graded on the **final cluster state**, with server-side dry-run
  admissions in `prod`.
- Change one thing at a time and test with a dry run after each change.
- The kind node never pulls the lab images; the dry run is how you and the
  grader ask the webhook for its decision.
