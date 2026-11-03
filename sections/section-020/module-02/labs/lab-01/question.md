# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Several authorities

## Scenario

The team is rotating its signing key. The `ClusterImagePolicy` `inventory-signed` still trusts only the old key. `prod` opts in. The registry `registry.localtest.me:5001` holds three images of `inventory/podinfo`:

| Tag | Signature |
| --- | --- |
| `6.14.1` | Signed with the old key (`/work/keys/cosign.key`) |
| `6.15.0` | Signed with the new key (`/work/next/cosign.key`) |
| `6.14.0` | Signed with a key nobody approved (`/work/other/cosign.key`) |

The public keys are in the Secrets `inventory-public-key` (old) and `inventory-public-key-next` (new) in `cosign-system`.

## Your task

1. Change `inventory-signed` so it accepts images signed with the old key or the new key.
2. Prove with server-side dry runs in `prod` that `6.14.1` and `6.15.0` are admitted and `6.14.0` is refused.

## Constraints

- Keep the policy name `inventory-signed` and its glob. The policy must enforce and must not contain a `static` authority.
- Do not trust any key other than the old and the new one.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- `inventory-signed` has key authorities for exactly the old and the new public key, and no other authority.
- In `prod`, dry runs of `6.14.1` and `6.15.0` are admitted with no warning, and a dry run of `6.14.0` is refused.
- The webhook still fails closed and denies images no policy matches.
