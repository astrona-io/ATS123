# How Attestation Checks Are Evaluated

An `attestations` list reads like a simple filter, but a few rules decide whether an image passes. This part states those rules, shows how to test a CUE policy with cosign before it reaches the cluster, and points out the one place where cosign and Policy Controller disagree about Rego.

## The rules

An attestation entry belongs to an authority. For each entry, Policy Controller looks for attestations of the entry's `predicateType` on the image digest, and verifies their signatures with the same key or identity as the authority. If there is no such attestation, the entry fails. If there is one, the entry's `policy` runs against the statement, and the entry passes when the policy accepts it. An entry without a `policy` passes when a verified attestation of that type exists.

All entries of an authority must pass, and an image must satisfy a policy through at least one authority. Two entries therefore mean two requirements, for example provenance from the trusted builder and a vulnerability scan without critical findings. Writing the two as two entries is clearer than one large policy, and the error message names the entry that failed.

The statement that the policy sees has `predicateType` and `predicate` at the top level, as in the in-toto format. A policy can check both fields. The policy text sits in `data`, and for longer text it can be loaded from a ConfigMap with `configMapRef`.

## Test the CUE policy with cosign first

Cosign can apply the same kind of CUE policy to a verified attestation, which lets you test the logic on a real image before you touch the cluster. The commands below need a provenance attestation signed with the lab key on `6.15.0`. Attach it if you have not yet:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
  --type slsaprovenance1 --predicate /work/provenance-trusted.json \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes \
  "$REPO@$(ws regctl image digest $REPO:6.15.0)"
```

Write the policy file in the pod. Its content is the same CUE you would put in `data`:

```sh
ws sh -c 'printf "predicateType: \"https://slsa.dev/provenance/v1\"\npredicate: runDetails: builder: id: \"https://ci.inventory.example/builder@v1\"\n" > /work/builder.cue'
```

Verify the attestation against the policy:

```sh
ws cosign verify-attestation --key /work/keys/cosign.pub --type slsaprovenance1 \
  --policy /work/builder.cue --insecure-ignore-tlog=true --new-bundle-format=false "$REPO:6.15.0" > /dev/null && echo policy passed
```

The command prints `policy passed` when the CUE value unifies with the statement. Change the builder in `/work/builder.cue` to a different address and run the verification again: it fails, which is the same decision the webhook would make.

## Where Rego differs

Cosign and Policy Controller use different Rego conventions. A Rego policy for Policy Controller declares `package sigstore` and a rule named `isCompliant`. A Rego policy for `cosign verify-attestation --policy` declares `package signature` and a rule named `allow`. If you copy a policy from one tool to the other without changing both, it always fails. For that reason, test the logic of a Rego policy in a way that matches the tool: use a dry run against a real policy in the cluster, or use the CUE form of the check when it is simple enough.

You now know the evaluation rules and how to test a CUE policy before applying it. The next question is how to switch such policies on in a running cluster.

## Common pitfalls

> [!WARNING]
> - **Putting two requirements into one entry.** Use two entries so the error names the one that failed.
> - **Copying Rego between cosign and Policy Controller.** The package and the rule name differ.
> - **Testing the CUE policy against the wrong predicate type.** Use the `--type` that matches the entry.
> - **Assuming a failed entry can be skipped by another authority.** Authorities are alternatives, but the entries inside one authority are all required.
