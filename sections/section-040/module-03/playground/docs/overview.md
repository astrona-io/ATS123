# Overview: Rolling Policies Out And Operating Them (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller and a small image registry, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, installed with the Helm chart 0.10.8 as the release `policy-controller`, with `no-match-policy: deny`.
- The broad policy `all-images` covers `registry.localtest.me:5001/**` and trusts the lab key. The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not.
- `inventory/podinfo:6.15.0` and `6.14.1` are signed with the lab key. `tools/podinfo:6.15.0` and `6.14.1` are signed with a separate tools key in `/work/tools` in the workstation, and no Secret holds that public key yet.
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

- Check an inventory image and a tools image against `all-images` and read the refusal for the tools image.
- Create the Secret `tools-public-key` and split the policy into `inventory-signed` and `tools-signed`.
- Sign `tools/podinfo:6.14.1` with the lab key and confirm the tools policy refuses it.
- Create a namespace, opt it in, and move a policy from warn to enforce there.
- Read the webhook log with `kubectl -n cosign-system logs deploy/policy-controller-webhook --since=15m` after a refusal.
