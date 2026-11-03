# Custom Attestations And Policy Languages

Provenance and vulnerability scans are statements that tools already produce. Most organisations also need statements of their own: a change was reviewed, a release was approved, a test suite passed. This module shows how to attach such a statement to an image, how Policy Controller reads it, and how to choose between the two policy languages it supports.

Keep one sentence in mind: **a policy language only sees the verified statement, so every rule has to be written against the exact shape of that statement.** A rule against a field that is not there refuses every image, and a rule that is too loose admits every image.

The module has four parts. **Custom Predicates And Statements** attaches a statement of your own with a predicate type of your own. **Writing CUE Policies** covers the CUE language as Policy Controller uses it, and a graded lab follows it. **Writing Rego Policies** covers the Rego rule and when it is the better choice. **Combining Attestations** requires several statements for one image and shows where each requirement belongs.

## Learning objectives

After this module you can:

- Attach a statement with a custom predicate type using `cosign attest` and read it back with `cosign verify-attestation`.
- Explain the parts of an in-toto statement that a policy can see.
- Write a CUE policy that requires fields with exact values and fields of a given type.
- Write a Rego policy with the `sigstore` package and the `isCompliant` rule.
- Choose CUE or Rego for a given check.
- Require more than one attestation for the same image and explain how the entries combine.

## Before you start

You need to know how to attach and require provenance with an `attestations` entry, and what a key authority is. You need to know how to run a server-side dry run in `prod`.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1**. The key policy `inventory-signed` covers `registry.localtest.me:5001/inventory/**`, `prod` opts in, and the three `inventory/podinfo` images `6.15.0`, `6.14.1` and `6.14.0` are signed with the lab key. The `workstation` pod holds `cosign` v3.1.4, the lab key pair in `/work/keys` (password `lab-only-password`), and predicate files in `/work`: provenance, vulnerability scans and the review files `review-6.15.0.json` and `review-6.14.1.json`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
