# Solution: Repair A Key Policy That Lets Everything Through

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `inventory-signed` enforces with the lab public key and no `static` authority, the three dry runs in `prod` give the expected answers with no warning on the release, and the webhook's safe settings are restored.

## Step 1: Read the warnings

Ask for the release image and read what `kubectl` prints above the result:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
```

The dry run succeeds with a warning that the image matches no policy. That is the first clue: the policy does not cover the image at all, and the no-match policy only warns.

## Step 2: Read the policy and the settings

```sh
kubectl get clusterimagepolicy inventory-signed -o yaml
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data.no-match-policy}{"\n"}'
```

There are four faults. The glob reads `inventry/**`, so it matches nothing. The authority reads the Secret `old-signing-key`, which holds the key that signed `6.14.1`, not the lab key. The policy has `mode: warn`. And `no-match-policy` is `warn`, so the unmatched release image was admitted with a warning instead of being refused.

## Step 3: Fix the policy

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

`kubectl apply` replaces the whole spec, so `mode: warn` is gone and the policy enforces.

## Step 4: Fix the no-match policy

The ConfigMap comes from the Helm values, so change it through Helm:

```sh
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 \
  --namespace cosign-system --reuse-values \
  --set-string webhook.configData.no-match-policy=deny --wait
```

If the chart repository is missing on your machine, add it first with `helm repo add sigstore https://sigstore.github.io/helm-charts`.

## Step 5: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
```

The release is admitted with no warning, and the other two are refused by `inventory-signed`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the glob | The policy now checks the old key and only warns, so every image is still admitted |
| Copy the lab key into `old-signing-key` | It works, but the Secret's name now lies about its content; the grader accepts it, a reviewer would not |
| Leave `no-match-policy` at `warn` | Images outside every policy keep entering `prod` with a warning |

## Practice on your own

- Set the glob to `registry.localtest.me:5001/inventory/*` and check whether `podinfo` still matches.
- Rotate the key: make a new pair, sign `6.15.0` with it, update `inventory-public-key`, and watch the old signature stop counting.
