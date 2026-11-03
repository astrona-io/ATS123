# Writing CUE Policies

CUE is a language for describing which values are allowed. In an attestation entry, a CUE policy describes the statement that must exist. This part states what CUE checks, writes a policy for the review statement, and ends with a lab on exactly that policy.

## How CUE checks a statement

The CUE text of a policy is unified with the statement. Unification succeeds when the statement has every field that the CUE text sets, with a value that fits. Fields of the statement that the CUE text does not mention are ignored. The check is therefore a list of requirements, and extra fields do no harm.

Three forms cover most needs:

| CUE text | Requirement |
| --- | --- |
| `predicate: approved: true` | The field exists and equals `true` |
| `predicate: reviewer: string` | The field exists and is text, with any value |
| `predicate: ticket: =~"^CHG-[0-9]+$"` | The field matches a regular expression |

A CUE policy for the review statement combines them:

<!-- astrona:playground:renew -->

```yaml
policy:
  type: cue
  data: |
    predicateType: "https://inventory.example/review/v1"
    predicate: {
      approved: true
      reviewer: string
      ticket: =~"^CHG-[0-9]+$"
    }
```

## Put it in a policy

Add an attestation entry to the key authority of `inventory-signed`. Save this as `clusterimagepolicy-inventory-signed.yaml`:

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

Apply it and ask for the three decisions:

```sh
kubectl apply -f clusterimagepolicy-inventory-signed.yaml
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.0 --dry-run=server
```

`6.15.0` is admitted when its review is approved. `6.14.1` has a review statement with `approved` set to `false`, so the CUE value conflicts and the image is refused. `6.14.0` has no review statement and is refused because the entry requires one.

## Reading a CUE failure

A refusal names the policy, the authority and the attestation entry. The reason is a CUE conflict, such as a field that has the value `false` where the policy says `true`. Compare the field in the message with the decoded statement from the previous part.

## Common pitfalls

> [!WARNING]
> - **Writing `approved: "true"`.** The quotes make it text, and the statement holds a boolean.
> - **A regular expression without anchors.** `=~"CHG-[0-9]+"` accepts `XCHG-1Y`.
> - **Leaving out `predicateType` in the CUE text.** The entry's `predicateType` selects the attestations, but the CUE text is what ties the check to the type.
> - **Treating unknown fields as a failure.** CUE ignores them; require a value if you need it.

## Your mission: Require An Approved Review

You can now require fields of a custom statement. The graded lab gives you three signed images, with an approved review, a rejected review and no review, and asks you to make `inventory-signed` admit only the first.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-040-02
astrona start ats-123-playground-040-02
```
