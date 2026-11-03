# Prerequisites

Before starting this lab you should be able to:

- Attach an attestation with `cosign attest` and read it with `cosign verify-attestation`.
- Add an `attestations` entry with a CUE or Rego policy to a key authority.
- Use server-side dry runs to ask the webhook for a decision.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it, and Helm 3.22.1.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8.
- The lab registry `registry.localtest.me:5001` (TLS, lab-only certificate authority) with copies of `podinfo`.
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and the lab-only key pair in `/work/keys` (password `lab-only-password`).
- The namespaces `prod` and `dev`. Starting state: inventory-signed only checks the lab key; all three images are signed; `6.15.0` has an approved review, `6.14.1` a rejected review and `6.14.0` none.
- The review attestations have the predicate type `https://inventory.example/review/v1` and the fields `reviewer`, `ticket` and `approved`.

## Working rules

- Everything is graded on the **final cluster state**, with server-side dry-run
  admissions in `prod`.
- Change one thing at a time and test with a dry run after each change.
- The kind node never pulls the lab images; the dry run is how you and the
  grader ask the webhook for its decision.
