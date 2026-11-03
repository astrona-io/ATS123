# Splitting Policies By Owner

One policy for the whole registry is quick to write and hard to keep correct. This part shows the failure of a broad policy, divides it into policies that each fit one team, and ends with a lab on the division.

## A broad policy fails the second team

Look at the policy of the playground:

<!-- astrona:playground:renew -->

```sh
kubectl get clusterimagepolicy all-images -o yaml
```

Its glob is `registry.localtest.me:5001/**` and its only authority trusts the lab key. The inventory team signs with the lab key, so its images pass. The tools team signs with its own key, so its images are refused even though they are signed:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/tools/podinfo:6.15.0 --dry-run=server
```

The first request is admitted. The second is refused, and the message says the signature does not verify with the key of `inventory-key`.

The tempting fix is to add the tools key as a second authority of the same policy. That works, and it also lets the tools key sign images in the inventory repository, because authorities are alternatives and apply to the whole glob. A key should only be trusted where its team works.

## Divide by repository and by key

Create one policy per team, each with the glob of the team's repositories and only the key of that team. The tools key needs a public key resource first. Create the Secret from the key in the workstation:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws cat /work/tools/cosign.pub > tools.pub
kubectl -n cosign-system create secret generic tools-public-key --from-file=cosign.pub=tools.pub
```

Then write the two policies:

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
---
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: tools-signed
spec:
  images:
    - glob: "registry.localtest.me:5001/tools/**"
  authorities:
    - name: tools-key
      key:
        secretRef:
          name: tools-public-key
```

Apply them, delete the broad policy, and run the checks again. The order matters: apply the new policies first, so no image is uncovered while you switch.

```sh
kubectl delete clusterimagepolicy all-images
```

Each repository now has exactly one rule and exactly one trusted signer. A tools image signed with the inventory key is refused, which is the point.

## Check the result from both sides

A split needs two kinds of tests. Positive tests confirm that each team's images still pass. Negative tests confirm that one team's key does not work in another team's repository. The second kind is the one that people forget, and it is the reason for the split.

## Common pitfalls

> [!WARNING]
> - **Deleting the broad policy before the new ones exist.** The images are then covered by no policy, and the no-match policy decides.
> - **Overlapping globs.** `registry.localtest.me:5001/**` and `registry.localtest.me:5001/tools/**` both match tools images, so both policies must pass.
> - **Creating the Secret in the wrong namespace.** The Secret is read from `cosign-system`.
> - **Testing only the images that should pass.**

## Your mission: Split A Broad Policy By Team

You can now divide a policy by repository and key. The graded lab starts with a broad policy that refuses the tools team's signed images, and asks you to replace it with one policy per team and to prove that the keys do not cross.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-040-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-040/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-040-03
astrona start ats-123-playground-040-03
```
