# Solution: Split A Broad Policy By Team

Work the task yourself first. Running `astrona submit -c sections/section-040/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the policies and their keys, the four dry runs in `prod`, and the webhook's safe settings.

## Step 1: Look at the starting state

```sh
kubectl get clusterimagepolicy
kubectl -n cosign-system get secret inventory-public-key tools-public-key
kubectl -n prod run check --image=registry.localtest.me:5001/tools/podinfo:6.15.0 --dry-run=server
```

There is one policy, `all-images`. The tools image is refused because its signature does not verify with the lab key.

## Step 2: Apply the two policies

Save this as `clusterimagepolicies.yaml`:

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

Apply them, then delete the broad policy:

```sh
kubectl apply -f clusterimagepolicies.yaml
kubectl delete clusterimagepolicy all-images
```

The new policies come first, so no image is uncovered at any moment.

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/tools/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/tools/podinfo:6.14.1 --dry-run=server
```

The first and third are admitted. The second has no signature. The fourth is signed with the lab key, which the tools policy does not trust.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```
