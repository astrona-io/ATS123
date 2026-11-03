# Writing Rego Policies

Rego is the policy language of Open Policy Agent. It is a query language with rules, sets and loops. This part shows the shape Policy Controller expects, writes the review check in Rego, and states when to prefer Rego over CUE.

## The shape Policy Controller expects

A Rego policy for an attestation entry uses the package `sigstore` and defines the rule `isCompliant`. The statement is available as `input`. The image is admitted for this entry when `isCompliant` is true:

```yaml
policy:
  type: rego
  data: |
    package sigstore
    default isCompliant = false
    isCompliant {
      input.predicateType == "https://inventory.example/review/v1"
      input.predicate.approved == true
      startswith(input.predicate.ticket, "CHG-")
    }
```

All lines of the rule body must be true. The `default` line makes the rule false when the body does not hold, so a missing field refuses the image.

> [!NOTE]
> Do not copy the Rego of `cosign verify-attestation --policy`. That command uses `package signature` and the rule `allow`. Policy Controller uses `package sigstore` and `isCompliant`.

## Where Rego is stronger

CUE states what must be present. Rego can compute. The vulnerability check in the previous module counts critical findings in a list, and CUE has no short way to say that. Use Rego when the check needs one of these:

- Counting, filtering or comparing items in a list.
- A rule that depends on two fields together, such as an expiry date after a start date.
- A set of allowed values kept in one place.

<!-- astrona:playground:renew -->

A rule that accepts an approved review from any of three named reviewers:

```yaml
policy:
  type: rego
  data: |
    package sigstore
    default isCompliant = false
    reviewers := {"alice", "bob", "carol"}
    isCompliant {
      input.predicate.approved == true
      reviewers[input.predicate.reviewer]
    }
```

Replace the `attestations` entry of `inventory-signed` with this policy, apply it, and run the three dry runs. The result is the same as with CUE for the images of the playground, because the check is the same.

## Test a policy before you apply it

The command `cosign verify-attestation` accepts `--policy` with a Rego or CUE file, which makes it possible to test a rule against a real statement without the cluster. Remember that it uses its own Rego package:

```sh
ws sh -c 'cat > /work/review-check.rego' <<'REGO'
package signature
default allow = false
allow {
  input.predicate.approved == true
}
REGO
ws sh -c 'cosign verify-attestation --key /work/keys/cosign.pub --type https://inventory.example/review/v1 \
  --insecure-ignore-tlog=true --new-bundle-format=false --policy /work/review-check.rego \
  registry.localtest.me:5001/inventory/podinfo:6.15.0 >/dev/null && echo POLICY-OK'
```

The check passes for `6.15.0`. Run it for `6.14.1` and the policy fails. The cluster uses a different package name, so move the rule body to the cluster form when it works.

## Common pitfalls

> [!WARNING]
> - **No `default isCompliant = false`.** A statement that makes the body undefined may behave differently from false; set the default.
> - **Using `package signature` in a cluster policy.** The rule is never found and every image is refused.
> - **Comparing a boolean with the text `"true"`.** The types differ and the comparison is false.
> - **A long Rego policy inside the YAML.** Keep it short, or move it to a ConfigMap and reference it.
