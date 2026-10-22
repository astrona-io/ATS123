# Solution: Require SLSA Provenance On Inventory Images

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the attestation entry in `inventory-signed`, the three dry runs in `prod`, and the webhook's safe settings.

## Step 1: Look at the attestations

Decode the provenance of `6.15.0` and `6.14.1` in the workstation pod:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
for TAG in 6.15.0 6.14.1; do
  ws sh -c "cosign verify-attestation --key /work/keys/cosign.pub --type slsaprovenance1 \
    --insecure-ignore-tlog=true --new-bundle-format=false \
    registry.localtest.me:5001/inventory/podinfo:$TAG | jq -r .payload | base64 -d | jq -r .predicate.runDetails.builder.id"
done
```

The first prints the trusted builder ID, the second the laptop builder ID. The same command for `6.14.0` fails: it has no provenance.

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
        - name: trusted-builder
          predicateType: https://slsa.dev/provenance/v1
          policy:
            type: cue
            data: |
              predicateType: "https://slsa.dev/provenance/v1"
              predicate: runDetails: builder: id: "https://ci.inventory.example/builder@v1"
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

The first is admitted. The second is refused by the attestation `trusted-builder`, because its builder ID differs. The third is refused because it has no provenance attestation at all.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| An attestation entry without `policy` | Any provenance counts, so the laptop build of `6.14.1` is admitted |
| A second authority with the attestation | Authorities are alternatives, so the first authority still admits every signed image |
| `predicateType: slsaprovenance` | That names the older v0.2 type; no attestation matches and every image is refused |

## Practice on your own

- Write the same check in Rego and confirm that the answers stay the same.
- Add a check that `buildDefinition.externalParameters.repository` is the inventory repository.
