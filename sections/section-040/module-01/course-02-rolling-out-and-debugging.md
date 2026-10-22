# Rolling Out Policies And Reading Denials

A policy that refuses the wrong image on its first day stops a deployment, and the usual reaction is to switch Policy Controller off. This part shows a safer order: run a new policy in warn mode, read what it would refuse, fix the policy or the images, and only then enforce it. It also shows where to look when the webhook refuses something.

## Warn first, then enforce

A `ClusterImagePolicy` with `mode: warn` checks every matching image exactly as an enforcing policy would, but admits the ones that fail. The API server passes the webhook's warning back to the client, so `kubectl` prints it, and CI logs that capture `kubectl` output show it too. Nothing is refused while you learn what the policy would do.

This part tests a new policy on its own, so `inventory-signed` should only check the lab key. If you added an `attestations` list to it, remove the list first; the command reports an error and changes nothing if there is none:

<!-- astrona:playground:renew -->

```sh
kubectl patch clusterimagepolicy inventory-signed --type=json \
  -p '[{"op":"remove","path":"/spec/authorities/0/attestations"}]'
```

The playground has two vulnerability predicates in `/work`: `scan-6.15.0.json` with one low finding, and `scan-6.14.1.json` with one critical finding. Attach them as `vuln` attestations:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
REPO=registry.localtest.me:5001/inventory/podinfo
for TAG in 6.15.0 6.14.1; do
  ws env COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
    --type vuln --predicate "/work/scan-$TAG.json" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes \
    "$REPO@$(ws regctl image digest "$REPO:$TAG")"
done
```

`--type vuln` sets the predicate type `https://cosign.sigstore.dev/attestation/vuln/v1`. The predicate file must already be in cosign's vulnerability format: `invocation`, `scanner` (with the scan result under `scanner.result`) and `metadata`.

Now add a second policy that refuses critical findings, in warn mode. Save this as `clusterimagepolicy-inventory-vulns.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-vulns
spec:
  mode: warn
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

The Rego policy collects the IDs of all critical findings in the set `criticals` and is compliant only when the set is empty. Then check the result:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

Both are admitted, but the second prints a warning above the result: `inventory-vulns` would have refused `6.14.1` because of the attestation `no-critical-findings`. If a clean image gets a warning too, the policy is wrong, not the image; that is exactly what warn mode is for.

## The order of a rollout

A rollout that does not surprise anyone moves in small steps, and each step is reversible:

1. Apply the new policy with `mode: warn`, in the namespaces that already opt in.
2. Watch the warnings for a while, in CI output and in the webhook's log, and fix the policy until only the images you mean to refuse produce warnings.
3. Fix or rebuild the images that should pass but do not.
4. Switch the policy to `mode: enforce`.
5. Opt the next namespace in with `policy.sigstore.dev/include=true`, one at a time, starting with the most important ones.

The no-match policy can follow the same path: `warn` while teams write their policies, `deny` once every image in the opted-in namespaces is covered. Keep system namespaces such as `kube-system` and `cosign-system` out of the opt-in label; a policy there can stop the cluster's own components or Policy Controller itself.

When the warnings show only what you expect, enforce the policy:

```sh
kubectl patch clusterimagepolicy inventory-vulns --type=merge -p '{"spec":{"mode":"enforce"}}'
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

Now `6.14.1` is refused.

## Reading a denial

A refused request leaves no pod behind, so there is nothing to `kubectl describe`. The first source is the error message itself: it names the webhook, the image by digest, the policy, the authority and, for attestations, the attestation entry, followed by the reason from the check. The second source is the webhook's log, which records each failed check with more detail:

```sh
kubectl -n cosign-system logs deploy/policy-controller-webhook --since=5m | grep -i -E 'error|fail|warn'
```

The log lines are JSON. Look for the image digest and the policy name from the error message. Policy Controller checks higher-level resources such as `Deployment` and `StatefulSet` too, by their pod template, so a `Deployment` with a failing image is refused when you apply it, not later when its pods are created.

> [!TIP]
> Keep a one-line dry-run check for every policy in your CI pipeline: `kubectl -n <namespace> run check --image=<image> --dry-run=server`. It asks the real webhook before the deployment does, and a warning in its output is your early sign that a policy change is coming.

You now know how to bring a policy into a live cluster without surprises, and where to read why it refused something. That closes the loop: sign, attest, require, roll out, and debug.

## Common pitfalls

> [!WARNING]
> - **Leaving a policy in warn mode for good.** Warnings are easy to ignore; set a date to switch to enforce.
> - **Ignoring a warning on a clean image.** It means the policy does not match its attestations, for example a wrong `predicateType`; enforcing it would refuse every image.
> - **Opting in `kube-system` or `cosign-system`.** A failed check there can stop the cluster's own components or the webhook itself.
> - **Looking for events after a refusal.** The request was never stored; read the error message and the webhook's log instead.
