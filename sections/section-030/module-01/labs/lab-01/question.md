# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Keyless policies

## Scenario

The platform team allows images from `ghcr.io` in `prod`, but only those built and signed by the release workflow of the repository `stefanprodan/podinfo`. That workflow is the file `.github/workflows/release.yml`, it runs on release tags, and it signs keylessly with the GitHub Actions identity token. `prod` already opts in to Policy Controller, and no policy exists yet.

## Your task

1. Find the issuer and the subject of the signature on `ghcr.io/stefanprodan/podinfo:6.10.0` with `cosign verify` in the workstation pod.
2. Create a `ClusterImagePolicy` named `podinfo-release` that covers every image from `ghcr.io` and accepts only signatures from that release workflow on any release tag.
3. Prove with server-side dry runs in `prod` that `ghcr.io/stefanprodan/podinfo:6.10.0` is admitted and `ghcr.io/fluxcd/source-controller:v1.9.6` is refused.

## Constraints

- Use keyless authorities only; no `key` and no `static` authority.
- The issuer must be exactly `https://token.actions.githubusercontent.com`.
- The subject must be anchored to the podinfo repository's release workflow; `.*`, a user-wide pattern or a pattern for any repository is not accepted.
- The policy must enforce. Do not change the webhook's failure policy or the no-match policy.

## Done when

- `podinfo-release` exists, enforces, covers `ghcr.io/**` and has only keyless authorities with the required issuer and an anchored subject for the release workflow.
- In `prod`, a dry run of the podinfo image is admitted with no warning and a dry run of the Flux image is refused.
- The webhook still fails closed and denies images no policy matches.
