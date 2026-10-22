# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Rollout

## Scenario

Every `inventory` image carries a vulnerability attestation (`cosign attest --type vuln`) signed with the lab key: `6.15.0` has one LOW finding, `6.14.1` has one CRITICAL finding. The policy `inventory-vulns` was meant to refuse images with a critical finding in `prod`. It has run in warn mode for a week, and it warned on **every** image, the clean `6.15.0` included, so nobody acts on its warnings. Someone also opted the namespace `dev` in while testing.

## Your task

1. Find out why `inventory-vulns` warns on a clean image.
2. Fix the policy and enforce it, so `prod` refuses `6.14.1` and admits `6.15.0`.
3. Take `dev` out of enforcement again.

## Constraints

- Keep the policy name `inventory-vulns`, its key authority and its Rego check for CRITICAL findings.
- Do not change `inventory-signed`, the webhook's failure policy or the no-match policy.

## Done when

- `inventory-vulns` enforces, and its attestation entry requires `https://cosign.sigstore.dev/attestation/vuln/v1` with the Rego policy that refuses CRITICAL findings.
- In `prod`, a dry run of `6.15.0` is admitted with no warning, and a dry run of `6.14.1` is refused.
- `dev` does not opt in and admits `6.14.1`.
