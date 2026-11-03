# Overview: Keyless Identity Rules And Trust Roots (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8 as the release `policy-controller`, with `no-match-policy: deny`.
- The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not. There is **no `ClusterImagePolicy`**. Keyless checks reach the public Sigstore services, so the cluster needs internet access.
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

- Apply a keyless policy with a wide `subjectRegExp` for `ghcr.io/stefanprodan/**` and test sample subjects with `grep -E`.
- Narrow the pattern to the release workflow on tags and test the same subjects again.
- Add a second identity and read how an image signed by neither is refused.
- Run `kubectl get trustroot` and `kubectl explain trustroot.spec --api-version=policy.sigstore.dev/v1alpha1`.
- Run `cosign tree ghcr.io/stefanprodan/podinfo:6.10.0` in the workstation and read which signature objects exist.
