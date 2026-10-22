# Overview: Require Images Signed With Your Key (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, opts the namespace `prod` in, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, with `no-match-policy: deny` and **no `ClusterImagePolicy` yet**. Every image you try in `prod` is refused until a policy matches it.
- The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not.
- The registry `registry.localtest.me:5001` (TLS, lab-only certificate authority) with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`, **both unsigned**.
- The `workstation` pod with `cosign` v3.1.4, `regctl`, `jq` and `openssl`, and the lab-only key pair in `/work/keys` (password `lab-only-password`).

The cluster's node never pulls the lab images. Ask for admission decisions with a server-side dry run.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod, `try_image` asks for an admission decision, and `sign_image` signs a tag of `inventory/podinfo` by its digest with a key file in the workstation.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
try_image() {
  kubectl -n "$1" run "try-$RANDOM" --image="$2" --restart=Never --dry-run=server
}
sign_image() {
  local image="registry.localtest.me:5001/inventory/podinfo@$(ws regctl image digest "registry.localtest.me:5001/inventory/podinfo:$2")"
  ws env COSIGN_PASSWORD=lab-only-password cosign sign --key "$1" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$image"
}
```

Use them like this: `sign_image /work/keys/cosign.key 6.15.0`, `try_image prod registry.localtest.me:5001/inventory/podinfo:6.15.0`.

## Practice tasks

- Make a second key pair with `ws sh -c 'mkdir -p /work/other && cd /work/other && COSIGN_PASSWORD=lab-only-password cosign generate-key-pair'`, sign `6.14.1` with it, and confirm that `inventory-signed` still refuses it.
- Change the glob to `registry.localtest.me/inventory/**` (no port) and read why `6.15.0` is now refused in `prod`.
- Put the public key inline with `key.data` instead of `secretRef`, and compare.
- Switch the policy to `mode: warn` and look for the warning on a dry run of `6.14.1`.
- Add a second authority with `static: {action: pass}` and watch it make the key check pointless.
