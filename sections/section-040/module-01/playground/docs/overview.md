# Overview: Check Attestations And Roll Policies Out (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller, a key policy and two signed images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in `cosign-system`, with `no-match-policy: deny`.
- The `ClusterImagePolicy` **`inventory-signed`**: every image under `registry.localtest.me:5001/inventory/` must be signed with the lab key (Secret `inventory-public-key`). No attestation is required yet.
- The namespace **`prod`** opts in; **`dev`** does not.
- The registry `registry.localtest.me:5001` with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`, **both signed with the lab key, no attestations**.
- The `workstation` pod with `cosign` v3.1.4, `regctl` and `jq`, the lab key pair in `/work/keys` (password `lab-only-password`), and four predicate files:

  | File | Content |
  | --- | --- |
  | `/work/provenance-trusted.json` | SLSA v1 provenance from `https://ci.inventory.example/builder@v1` |
  | `/work/provenance-laptop.json` | SLSA v1 provenance from `https://laptop.inventory.example/manual-build` |
  | `/work/scan-6.15.0.json` | A vulnerability scan with one LOW finding |
  | `/work/scan-6.14.1.json` | A vulnerability scan with one CRITICAL finding |

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod, `try_image` asks for an admission decision, and `attest_image` attaches a predicate file to a tag of `inventory/podinfo` by digest.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
try_image() {
  kubectl -n "$1" run "try-$RANDOM" --image="$2" --restart=Never --dry-run=server
}
attest_image() {
  local image="registry.localtest.me:5001/inventory/podinfo@$(ws regctl image digest "registry.localtest.me:5001/inventory/podinfo:$1")"
  ws env COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
    --type "$2" --predicate "$3" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$image"
}
```

Use them like this: `attest_image 6.15.0 slsaprovenance1 /work/provenance-trusted.json`, `try_image prod registry.localtest.me:5001/inventory/podinfo:6.15.0`.

## Practice tasks

- Require provenance in `inventory-signed` before you attach any, and watch both images be refused. Then attach and try again.
- Break the CUE policy on purpose (a typo in `runDetails`) and read the error.
- Rewrite the CUE provenance check in Rego and compare the error messages.
- Apply the vulnerability policy in warn mode, attach the scans, and read the warnings in `kubectl` output and in `kubectl -n cosign-system logs deploy/policy-controller-webhook`.
- Change the Rego rule to refuse HIGH findings as well, and check which images still pass.
