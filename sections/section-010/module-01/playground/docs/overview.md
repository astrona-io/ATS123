# Overview: Gate Images At Admission With Policy Controller (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Policy Controller and a small image registry, signs one image, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`: the Deployment `policy-controller-webhook` and the ConfigMap `config-policy-controller` with `no-match-policy: deny`. Its webhooks only see namespaces labelled `policy.sigstore.dev/include=true`.
- The registry `registry.localtest.me:5001`, with TLS from a lab-only certificate authority. It holds:

  | Image | State |
  | --- | --- |
  | `inventory/podinfo:6.15.0` | Signed with the lab key |
  | `inventory/podinfo:6.14.1` | Not signed |

- The `ClusterImagePolicy` **`inventory-signed`**: every image under `registry.localtest.me:5001/inventory/` must be signed with the lab key, read from the Secret `inventory-public-key` in `cosign-system`.
- The `workstation` pod with `cosign`, `regctl`, `jq` and `openssl`. The lab-only key pair is in `/work/keys` (password `lab-only-password`).
- The namespaces **`prod`** and **`dev`**. Neither opts in at the start.

The cluster's node never pulls the lab images. Ask for admission decisions with a server-side dry run.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `try_image` asks the API server to admit a pod with an image in a namespace, without storing it.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
try_image() {
  kubectl -n "$1" run "try-$RANDOM" --image="$2" --restart=Never --dry-run=server
}
```

Use them like this: `try_image prod registry.localtest.me:5001/inventory/podinfo:6.14.1`, `ws regctl tag ls registry.localtest.me:5001/inventory/podinfo`.

## Practice tasks

- Try the unsigned image in `prod` before and after you add the label `policy.sigstore.dev/include=true`, and in `dev` after.
- Add `-o jsonpath='{.spec.containers[0].image}'` to a dry run of `6.15.0` in an opted-in namespace and compare the image with `ws regctl image digest` of the tag.
- Try `ghcr.io/stefanprodan/podinfo:6.15.0` in an opted-in namespace and read why it is refused. Then read `kubectl -n cosign-system get configmap config-policy-controller -o yaml`.
- List the tags in the registry with `ws regctl tag ls registry.localtest.me:5001/inventory/podinfo` and find the signature tag that belongs to `6.15.0`: it starts with `sha256-` and ends with `.sig`.
- Scale the webhook to zero with `kubectl -n cosign-system scale deployment policy-controller-webhook --replicas=0`, try a pod in an opted-in namespace, and read the error. Scale it back to one.
