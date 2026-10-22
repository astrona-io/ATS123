# Overview: Trust Signing Identities Instead Of Keys (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Policy Controller, opts the namespace `prod` in, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and Helm 3.22.1 is installed.
- **Policy Controller v0.15.1** in the namespace `cosign-system`, with **no `ClusterImagePolicy`** and `no-match-policy: warn`, so images that match no policy are admitted with a warning while you experiment.
- The namespace **`prod`** opts in with `policy.sigstore.dev/include=true`; **`dev`** does not.
- The `workstation` pod with `cosign` v3.1.4, `regctl` and `jq`.
- Two public images on `ghcr.io`, both signed keylessly in GitHub Actions:

  | Image | Signed by |
  | --- | --- |
  | `ghcr.io/stefanprodan/podinfo:6.15.0` | The `release.yml` workflow of `stefanprodan/podinfo`, on the tag `6.15.0` |
  | `ghcr.io/fluxcd/source-controller:v1.9.6` | A workflow of the Flux project |

The workstation pod and Policy Controller need outbound internet for these examples. The lab registry from the other modules runs here too, but this module does not use it.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod, and `try_image` asks for an admission decision.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
try_image() {
  kubectl -n "$1" run "try-$RANDOM" --image="$2" --restart=Never --dry-run=server
}
```

Use them like this: `try_image prod ghcr.io/stefanprodan/podinfo:6.15.0`, `ws cosign verify ghcr.io/stefanprodan/podinfo:6.15.0 --certificate-identity-regexp '.*' --certificate-oidc-issuer-regexp '.*'`.

## Practice tasks

- Verify the podinfo image with `--certificate-identity-regexp '.*'` and `--certificate-oidc-issuer-regexp '.*'`, and read the identity cosign reports. Then verify it with the exact identity.
- Try the Flux image with the podinfo identity and read why it fails.
- Apply a policy for `ghcr.io/**` with `issuerRegExp: .*` and `subjectRegExp: .*` and watch both images pass. Narrow it step by step.
- Remove `signatureFormat: bundle` from a working keyless policy and read why the podinfo image is now refused.
- Change the policy's glob to `ghcr.io/stefanprodan/**` and see what happens to the Flux image under `no-match-policy: warn`.
