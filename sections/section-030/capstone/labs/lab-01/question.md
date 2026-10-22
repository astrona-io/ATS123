# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Keyless policies

## Scenario

A teammate wrote the keyless policy `podinfo-release` so that `prod` runs only images signed by the release workflow of `stefanprodan/podinfo` (`.github/workflows/release.yml`, on release tags, issuer `https://token.actions.githubusercontent.com`). An audit found `ghcr.io/fluxcd/source-controller:v1.9.6` running in a test, admitted without a complaint. That image is validly signed, but by a workflow of the Flux project.

## Your task

1. Find every reason why `prod` admits an image signed by another project.
2. Fix the policy and Policy Controller's settings so that every `ghcr.io` image in `prod` must come from the podinfo release workflow, and images that match no policy are refused.

## Constraints

- Keep the policy name `podinfo-release` and use keyless authorities only.
- The issuer must be exactly `https://token.actions.githubusercontent.com`, and the subject must be anchored to the podinfo release workflow on any release tag.
- Do not change the webhook's failure policy, and do not uninstall Policy Controller.

## Done when

- `podinfo-release` enforces, covers `ghcr.io/**`, and has only the narrow keyless identity.
- In `prod`, a dry run of `ghcr.io/stefanprodan/podinfo:6.15.0` is admitted with no warning, and a dry run of `ghcr.io/fluxcd/source-controller:v1.9.6` is refused.
- `no-match-policy` is `deny` or not set, and the webhook's failure policy is `Fail`.
