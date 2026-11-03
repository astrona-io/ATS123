# Limiting A Policy To Some Resources

An image pattern picks images. Sometimes you also want to pick the workloads that run them: only pods with a label, or only one kind of resource. The `match` field of a `ClusterImagePolicy` does that. This part explains how it selects, and what happens to the resources it leaves out.

## The match field

`spec.match` is a list. Each entry names a resource with `group`, `version` and `resource`, for example `version: v1` and `resource: pods`, and may add a `selector` with `matchLabels`, the labels of the object. A policy with `match` applies only to objects that satisfy at least one entry. Without `match`, it applies to all the kinds Policy Controller checks.

An object that no entry selects is not judged by that policy. If no other policy matches its images either, the no-match policy decides. This makes `match` a way to scope a rule, and not a way to make it stricter.

## Try a policy that selects by label

First sign `6.15.0` with the lab key so that one image is valid:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$REPO@$(ws regctl image digest $REPO:6.15.0)"
```

Save this as `clusterimagepolicy-inventory-tier.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-tier
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  match:
    - version: v1
      resource: pods
      selector:
        matchLabels:
          tier: production
  authorities:
    - name: inventory-key
      key:
        secretRef:
          name: inventory-public-key
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-tier.yaml
```

Then ask for the unsigned `6.14.1` twice, once with the label and once without:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --labels=tier=production --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The pod with the label is refused by `inventory-tier`. The pod without it matches no entry of `match`, so the policy does not judge it, and the answer comes from the no-match policy, which is `deny` in this playground. Change nothing: the point is that the second refusal has a different reason, and the message names no policy.

## When to use it

Use `match` when a rule belongs to a kind of workload, such as pods of a tier, and not to an image location. Do not use it to scope by namespace, because opting namespaces in with the label is clearer and covers every policy at once. Keep in mind that a label is set by the person who writes the workload, so a label match is not a security boundary against that person.

You now have the four tools of policy design: patterns, authorities, signature sources and `match`.

## Common pitfalls

> [!WARNING]
> - **Treating `match` as stricter.** It narrows where the policy applies, so fewer objects are judged by it.
> - **Selecting by a label the workload author controls.** An author can leave the label off.
> - **Writing `resource: pod`.** The field takes the plural resource name, `pods`.
> - **Forgetting that unselected objects fall to the no-match policy.**
