# Summary

An attestation policy can only see the verified statement, so it must be written against the exact shape of that statement. A rule for a field that is not there refuses every image.

## What you learned

A custom statement is attached with `cosign attest --type <URI>` and a predicate file. The URI names the kind of statement and should be one that your organisation controls and versions. `cosign verify-attestation` decodes the statement, and the decoded document is what the policy receives, with `predicateType` and `predicate` at the top level.

CUE describes the values that must be present, and fields it does not mention are ignored. Rego computes: counting, comparing and keeping lists of allowed values. A Rego policy for Policy Controller uses the package `sigstore` and the rule `isCompliant`, and `cosign verify-attestation --policy` uses the package `signature` and the rule `allow`.

Entries of one authority all must pass. Authorities of one policy are alternatives. Policies that match one image all must pass. The key facts to remember are these:

- A custom predicate type is a URI that you own and version.
- CUE states requirements, Rego computes.
- Entries combine as AND, authorities as OR, policies as AND.
- Name each entry for the fact it checks.

<!-- astrona:playground:destroy -->
