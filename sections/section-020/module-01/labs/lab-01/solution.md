# Solution: Write A Key-Based Image Policy

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `inventory-signed` enforces with the lab public key and no `static` authority, the three dry runs in `prod` give the expected answers, and the webhook's safe settings are unchanged.

## Step 1: Confirm the starting state

Check the Secret and the signatures from the workstation pod:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
kubectl -n cosign-system get secret inventory-public-key
ws cosign verify --key /work/keys/cosign.pub --insecure-ignore-tlog=true \
  --new-bundle-format=false registry.localtest.me:5001/inventory/podinfo:6.15.0
ws cosign verify --key /work/keys/cosign.pub --insecure-ignore-tlog=true \
  --new-bundle-format=false registry.localtest.me:5001/inventory/podinfo:6.14.1
```

The Secret exists. The first verification passes; the second fails, because `6.14.1` carries a signature from another key.

## Step 2: Write the policy

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

The policy has no `mode`, so it enforces. The glob includes the port `5001`, and `**` covers every repository under `inventory/`.

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
```

The first request is admitted with no warning. The other two are refused by `inventory-signed`: `6.14.1` because its signature does not verify with the lab key, `6.14.0` because it has no signature at all.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Glob `**` | The policy also covers every other image in the cluster; the grader only checks the `inventory` images, but every other workload in `prod` now needs the lab key |
| Glob `registry.localtest.me/inventory/**` | It matches nothing, so the no-match policy refuses `6.15.0` too |
| Add a second authority with the other key | `6.14.1` is admitted, because one passing authority is enough |
| `mode: warn` | Nothing is refused; the grader requires enforcement |

## Practice on your own

- Replace `secretRef` with the inline `data` of `/work/keys/cosign.pub` and check that the answers stay the same.
- Sign `6.14.0` with the lab key and watch it become admitted.
