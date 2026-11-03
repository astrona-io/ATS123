# Solution: Require An Approved Review

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the attestation entry in `inventory-signed`, the three dry runs in `prod`, and the webhook's safe settings.

## Step 1: Look at the attestations

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
for TAG in 6.15.0 6.14.1; do
  ws sh -c "cosign verify-attestation --key /work/keys/cosign.pub --type https://inventory.example/review/v1 \
    --insecure-ignore-tlog=true --new-bundle-format=false \
    registry.localtest.me:5001/inventory/podinfo:$TAG | jq -r .payload | base64 -d | jq .predicate"
done
```

The first prints `approved: true`, the second `approved: false`. The same command for `6.14.0` fails: it has no review.

## Step 2: Extend the policy

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
      attestations:
        - name: reviewed
          predicateType: https://inventory.example/review/v1
          policy:
            type: cue
            data: |
              predicateType: "https://inventory.example/review/v1"
              predicate: approved: true
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-signed.yaml
```

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
```

`6.15.0` is admitted. `6.14.1` is refused because `approved` is `false`, and the message names the attestation `reviewed`. `6.14.0` is refused because it has no review attestation.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```
