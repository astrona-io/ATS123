# Overview: Install And Configure Policy Controller (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8 as the release `policy-controller`, with `no-match-policy: deny`.
- The Helm release `policy-controller` (chart 0.10.8) is installed; read it with `helm get values policy-controller -n cosign-system` and `helm history policy-controller -n cosign-system`.
- The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not. There is **no `ClusterImagePolicy`**.
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

- Read the values of the release and find the ConfigMap `config-policy-controller` that `webhook.configData` produces.
- Run `helm upgrade --reuse-values --set-string webhook.configData.no-match-policy=warn` and watch a dry run in `prod` change.
- Edit the ConfigMap with `kubectl edit`, run a `helm upgrade`, and see the edit disappear.
- Run `helm upgrade` without `--reuse-values` and compare `helm get values` before and after.
- Scale the webhook to two replicas and watch the rollout.
