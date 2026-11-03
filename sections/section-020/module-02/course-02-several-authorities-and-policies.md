# Several Authorities And Several Policies

Real signing setups change: a key is rotated, a second team signs the same images, or an old release was signed by a retired key. Policy Controller handles this with two rules that look alike and work in opposite ways. This part states both rules, shows them in a rotation, and gives you a lab to practise.

## Authorities are alternatives

An image passes a policy when any one of the policy's authorities accepts it. If a policy has a key authority for the old key and another for the new key, an image signed by either key passes. If neither accepts it, the image fails and the error lists each authority and why it failed.

This is the basis of a safe rotation. You create the new key, add its public key as a second authority, and begin signing new releases with it. Old releases keep passing through the old authority. When no image you still run depends on the old key, you delete the old authority.

## Policies are all required

An image can match more than one policy, for example `inventory/**` and `registry.localtest.me:5001/**`. Then the image must pass every one of them. This is the reverse of the first rule: adding a policy can only make admission stricter.

| Where | Rule | Effect of adding one |
| --- | --- | --- |
| Authorities in one policy | Any one must accept | More images pass |
| Policies that match one image | All must pass | Fewer images pass |

## A rotation, step by step

Create the second key pair and a Secret with its public key, then add it as a second authority. First the key and the Secret:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws sh -c 'mkdir -p /work/next && cd /work/next && COSIGN_PASSWORD=lab-only-password cosign generate-key-pair >/dev/null'
ws cat /work/next/cosign.pub > next.pub
kubectl -n cosign-system create secret generic inventory-public-key-next --from-file=cosign.pub=next.pub
```

Sign `6.14.1` with the new key and `6.15.0` with the old one:

```sh
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/next/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$REPO@$(ws regctl image digest $REPO:6.14.1)"
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$REPO@$(ws regctl image digest $REPO:6.15.0)"
```

Save this as `clusterimagepolicy-inventory-rotation.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-rotation
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: old-key
      key:
        secretRef:
          name: inventory-public-key
    - name: new-key
      key:
        secretRef:
          name: inventory-public-key-next
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-rotation.yaml
```

Then check both images:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

Both are admitted, one through each authority. An image signed with a third key, or with none, is still refused, because neither authority accepts it. Remove the old authority from the YAML and apply it again, and the image signed with the old key is refused: that is the last step of a rotation.

You now know the two rules and the rotation they make safe. The mission applies them to a policy that trusts only the old key.

## Common pitfalls

> [!WARNING]
> - **Removing the old authority too early.** Releases signed with the old key stop running at the next pod start.
> - **Adding a `static` pass authority as a quick fix.** Alternatives mean it admits every image.
> - **Expecting a second policy to widen what the first allows.** All matching policies must pass.
> - **Forgetting to leave the rotation.** An old key kept as an authority for years is still a trusted key.

## Your mission: Rotate The Signing Key Without Refusing Old Releases

You can now add an authority for a new key and know why the old one must stay for a while. The graded lab gives you a policy that trusts only the old key, two releases signed with different keys, and an image signed with a key nobody approved. The task is to make the policy accept the two approved keys and nothing else.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-020-02
astrona start ats-123-playground-020-02
```
