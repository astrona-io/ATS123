# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Keyless identities

## Scenario

The `ClusterImagePolicy` `podinfo-release` covers `ghcr.io/stefanprodan/podinfo**` and accepts a keyless signature from the issuer `https://token.actions.githubusercontent.com`. Its identity is a loose pattern, `^https://github\.com/stefanprodan/.*$`, so it trusts every workflow of every repository of that owner, on every branch.

The image `ghcr.io/stefanprodan/podinfo:6.10.0` was signed by the release workflow of the `podinfo` repository on a release tag. Its certificate subject is:

```
https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.10.0
```

## Your task

1. Narrow the identity so that it accepts only the workflow `release.yml` of the repository `stefanprodan/podinfo`, run from a tag (`refs/tags/`).
2. Prove with a server-side dry run in `prod` that `ghcr.io/stefanprodan/podinfo:6.10.0` is still admitted.

## Constraints

- Keep the policy name `podinfo-release` and its image glob. The policy must enforce and must not contain a `static` authority.
- Keep the issuer `https://token.actions.githubusercontent.com`.
- Use a `subject` or a `subjectRegExp`. Do not widen the policy in any other way.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- The identity accepts the release subject of `6.10.0` and other tags of the same workflow, and rejects a test workflow, a release workflow on a branch, a different repository of the same owner, and a repository of another owner.
- In `prod`, a dry run of `ghcr.io/stefanprodan/podinfo:6.10.0` is admitted with no warning.
- The webhook still fails closed and denies images no policy matches.
