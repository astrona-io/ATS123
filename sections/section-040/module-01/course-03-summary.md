# Summary

Signatures say who approved an image; attestations say how it was built and what is in it. Policy Controller can require both, and the way you switch such a policy on decides whether it is trusted or turned off.

## What you learned

An attestation is a signed in-toto statement with a `subject` (the image digest), a `predicateType` and a `predicate`. SLSA provenance, type `https://slsa.dev/provenance/v1`, names the build service under `runDetails.builder.id`. A vulnerability attestation, type `https://cosign.sigstore.dev/attestation/vuln/v1`, carries a scan result under `scanner.result`. `cosign attest` signs and attaches one; for key policies in Policy Controller v0.15.1 it uses the classic format, stored under a tag ending in `.att`.

An authority's `attestations` list requires attestations of a predicate type signed by that authority, and an optional `policy` checks their content. Policy Controller hands the verified statement to the policy. A CUE policy states the fields and values the statement must have. A Rego policy in the package `sigstore` must make `isCompliant` true, and is the better choice when the check needs logic such as counting findings.

A safe rollout runs a new policy in `warn` mode first, fixes the policy until only the images you mean to refuse produce warnings, then switches it to `enforce`, and opts in one namespace at a time. A refused request leaves no object and no event; its error message names the policy, the authority and the attestation, and the webhook's log adds detail. The key facts to remember are these:

- `--type slsaprovenance1` gives `https://slsa.dev/provenance/v1`; `--type vuln` gives `https://cosign.sigstore.dev/attestation/vuln/v1`.
- An authority with `attestations` refuses an image that has a valid signature but no matching attestation.
- A warning on a clean image means the policy is wrong; enforcing it would refuse everything.
- Keep `kube-system` and `cosign-system` out of the opt-in label.

<!-- astrona:playground:destroy -->
