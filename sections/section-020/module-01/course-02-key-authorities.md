# Key Authorities In A ClusterImagePolicy

A signed image is still admitted or refused for reasons that have nothing to do with its signature until a policy connects the two. This part writes the `ClusterImagePolicy` that trusts the lab key for the `inventory` images. It covers the three ways to hand Policy Controller a public key, how image patterns match, and how `warn` mode lets you try a policy without breaking deployments.

## The parts of a ClusterImagePolicy

A `ClusterImagePolicy` is a cluster-wide resource in the API group `policy.sigstore.dev`. Its `spec` has three fields you use in almost every policy:

| Field | What it does |
| --- | --- |
| `images` | A list of `glob` patterns. The policy applies to every image that matches one of them |
| `authorities` | A list of ways an image can pass. An image passes the policy when **any one** authority accepts it |
| `mode` | `enforce` (the default) refuses an image that fails; `warn` admits it and returns a warning |

A key authority holds a public key. Policy Controller accepts the image when it finds a signature for the image's digest that verifies with that key.

## Hand the public key to the cluster

Policy Controller accepts the public key in three forms. `key.data` holds the PEM text of the key inline in the policy. `key.secretRef.name` names a Secret in the namespace where Policy Controller runs, `cosign-system`, and uses the first value in that Secret. `key.kms` names a key in a key management service, such as `awskms://...` or `gcpkms://...`, and Policy Controller fetches the public key from there.

A Secret keeps the key out of the policy, so you can rotate it without editing the policy. Copy the public key out of the workstation pod and store it as a Secret:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec deploy/workstation -- cat /work/keys/cosign.pub > cosign.pub
kubectl -n cosign-system create secret generic inventory-public-key --from-file=cosign.pub=cosign.pub
```

Only the public key leaves the workstation. The private key `cosign.key` stays with the signer.

## Write the policy

Save this as `clusterimagepolicy-inventory-signed.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-signed
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: inventory-key
      key:
        secretRef:
          name: inventory-public-key
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-signed.yaml
```

The glob decides which images the policy covers. Policy Controller matches it against the image name with its digest, for example `registry.localtest.me:5001/inventory/podinfo@sha256:...`. In a glob, `*` matches any characters except `/`, and `**` matches any characters including `/`. So `inventory/**` covers every repository under `inventory/`, at any depth. The registry part must match exactly, port included: `registry.localtest.me/inventory/**` without `:5001` matches nothing in this registry.

## Prove it with dry runs

This playground signed nothing at start, so sign `6.15.0` now if you have not done so already in this playground:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
RELEASE="registry.localtest.me:5001/inventory/podinfo@$(ws regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0)"
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$RELEASE"
```

Then ask for both images in `prod`:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The first request is admitted. The second is refused, and the error names the policy `inventory-signed` and the authority `inventory-key`, and says no matching signature was found. An image signed with any other key gets the same answer, because only the public key in `inventory-public-key` counts.

## Try a policy in warn mode first

A new policy that refuses images can stop a deployment you did not expect it to touch. `mode: warn` lets you see that first: Policy Controller still checks every matching image, but it admits the ones that fail and returns a warning. `kubectl` prints the warning above its normal output, and the pod is created.

Switch the policy to warn mode and try the unsigned image again:

```sh
kubectl patch clusterimagepolicy inventory-signed --type=merge -p '{"spec":{"mode":"warn"}}'
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The dry run succeeds, and above the result `kubectl` prints a warning with the same reason the refusal gave. Switch back to enforcement before you move on:

```sh
kubectl patch clusterimagepolicy inventory-signed --type=merge -p '{"spec":{"mode":"enforce"}}'
```

You now have a policy that trusts exactly one public key for every `inventory` image and refuses everything else. The question left is what such a policy cannot express: who signed, rather than which key signed.

## Common pitfalls

> [!WARNING]
> - **A glob without the registry port.** `registry.localtest.me/inventory/**` matches nothing when images are named `registry.localtest.me:5001/...`, and the image falls through to the no-match policy.
> - **A Secret in the wrong namespace.** `secretRef` reads Secrets in the Policy Controller namespace, `cosign-system`, not in the namespace of the pod.
> - **Leaving a policy in `warn` mode.** It refuses nothing; it only prints warnings that are easy to miss.
> - **Adding a `static` authority with `action: pass` to make errors go away.** Authorities are alternatives, so one that always passes makes the key check meaningless.

## Your mission: Write A Key-Based Image Policy

You can now sign an image, trust its key in a policy and prove the result with dry runs. The graded lab gives you signed, wrongly signed and unsigned images and a Secret with the lab public key, and asks for a policy that admits only the images signed with the lab key.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-020-01
astrona start ats-123-playground-020-01
```
