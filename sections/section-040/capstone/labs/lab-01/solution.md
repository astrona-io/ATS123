# Solution: Roll Out A Vulnerability Policy Safely

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the shape and mode of `inventory-vulns`, the two dry runs in `prod`, `dev` being out of enforcement, and the webhook's safe settings.

## Step 1: Read the warning on the clean image

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
```

The dry run succeeds with a warning from `inventory-vulns` about its attestation `no-critical-findings`. Read the reason closely: the policy did not find a critical finding in `6.15.0`; it did not find a matching attestation at all.

## Step 2: Compare the policy with the attestation

```sh
kubectl get clusterimagepolicy inventory-vulns -o jsonpath='{.spec.authorities[0].attestations[0].predicateType}{"\n"}'
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws sh -c "cosign verify-attestation --key /work/keys/cosign.pub --type vuln --insecure-ignore-tlog=true \
  --new-bundle-format=false registry.localtest.me:5001/inventory/podinfo:6.15.0 | jq -r .payload | base64 -d | jq -r .predicateType"
```

The policy asks for `https://cosign.sigstore.dev/attestation/v1`, the type of a `custom` attestation, while the images carry `https://cosign.sigstore.dev/attestation/vuln/v1`. No attestation ever matched, so every image failed and, in warn mode, every image got a warning.

## Step 3: Fix and enforce the policy

Save this as `clusterimagepolicy-inventory-vulns.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-vulns
spec:
  mode: enforce
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: inventory-key
      key:
        secretRef:
          name: inventory-public-key
      attestations:
        - name: no-critical-findings
          predicateType: https://cosign.sigstore.dev/attestation/vuln/v1
          policy:
            type: rego
            data: |
              package sigstore
              default isCompliant = false
              isCompliant {
                input.predicateType == "https://cosign.sigstore.dev/attestation/vuln/v1"
                count(criticals) == 0
              }
              criticals[id] {
                finding := input.predicate.scanner.result.Results[_].Vulnerabilities[_]
                finding.Severity == "CRITICAL"
                id := finding.VulnerabilityID
              }
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-vulns.yaml
```

## Step 4: Take dev out

```sh
kubectl label namespace dev policy.sigstore.dev/include-
```

## Step 5: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n dev run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

`6.15.0` is admitted in `prod` with no warning, `6.14.1` is refused there by `no-critical-findings`, and `dev` admits it.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Enforce without fixing the predicate type | Every image is refused, the clean release included |
| Delete the Rego policy | Any vulnerability attestation counts, so `6.14.1` is admitted |
| Delete the policy to clear the warnings | Nothing checks the scans any more, and the grader requires `inventory-vulns` |

## Practice on your own

- Before enforcing, run the fixed policy in warn mode and confirm that only `6.14.1` produces a warning.
- Extend the Rego rule with an exception list of reviewed CVE IDs.
