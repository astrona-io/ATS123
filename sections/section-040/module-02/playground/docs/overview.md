# Overview: Custom Attestations And Policy Languages (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8 as the release `policy-controller`, with `no-match-policy: deny`.
- `inventory-signed` trusts the lab key for `registry.localtest.me:5001/inventory/**`, and the namespace **`prod`** opts in. **`dev`** does not.
- `inventory/podinfo:6.15.0`, `6.14.1` and `6.14.0` are signed with the lab key and carry **no attestation**.
- `/work` in the workstation holds `provenance-trusted.json`, `provenance-laptop.json`, `scan-6.15.0.json`, `scan-6.14.1.json`, `review-6.15.0.json` and `review-6.14.1.json`.
- The registry `registry.localtest.me:5001` (TLS, lab-only certificate authority).
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and `openssl`, and the lab-only key pair in `/work/keys` (password `lab-only-password`).

The cluster's node never pulls the lab images. Ask for admission decisions with a server-side dry run.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod and `try_image` asks for an admission decision with a server-side dry run.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
try_image() {
  kubectl -n "$1" run "try-$RANDOM" --image="$2" --restart=Never --dry-run=server
}
```

## Practice tasks

- Attach `review-6.15.0.json` and `review-6.14.1.json` with the predicate type `https://inventory.example/review/v1`, then read them with `cosign verify-attestation`.
- Require the review with a CUE policy and check the three dry runs.
- Rewrite the same check in Rego and compare the answers.
- Make the CUE policy require a ticket that matches `^CHG-[0-9]+$`.
- Require provenance and a review in one authority, then in two policies.
