# Solution: Rotate The Signing Key Without Refusing Old Releases

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the authorities of `inventory-signed`, the three dry runs in `prod`, and the webhook's safe settings.

## Step 1: Look at the starting state

```sh
kubectl get clusterimagepolicy inventory-signed -o yaml
kubectl -n cosign-system get secret inventory-public-key inventory-public-key-next
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
```

The policy has one authority, for the old key. The dry run of `6.15.0` is refused, because that release is signed with the new key.

## Step 2: Add an authority for the new key

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
    - name: inventory-key-next
      key:
        secretRef:
          name: inventory-public-key-next
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-signed.yaml
```

Authorities are alternatives, so an image passes when either key verifies its signature.

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
```

The first two are admitted. The third is refused: its signature verifies with neither key.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```
