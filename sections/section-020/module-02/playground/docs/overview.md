# Overview: Design Key Policies For A Real Registry (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8 as the release `policy-controller`, with `no-match-policy: deny`.
- The Secret `inventory-public-key` in `cosign-system` holds the lab public key. The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not. There is **no `ClusterImagePolicy`**.
- The lab registry holds `inventory/podinfo:6.15.0`, `6.14.1` and `6.14.0`, **all unsigned**.
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

- Make a second key pair with `ws sh -c 'mkdir -p /work/next && cd /work/next && COSIGN_PASSWORD=lab-only-password cosign generate-key-pair'` and store its public key in a second Secret.
- Sign `6.14.1` with the first key and `6.15.0` with the second, then write one policy with two authorities and check both are admitted.
- Change the image glob to `registry.localtest.me:5001/inventory/podinfo` and read which tags it covers.
- Write two policies with overlapping globs and sign an image for only one of them.
- Add a `resources` or namespace condition and check the result with a dry run in `dev` and in `prod`.
