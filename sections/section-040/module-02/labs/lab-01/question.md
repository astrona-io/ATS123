# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Custom attestations

## Scenario

The `ClusterImagePolicy` `inventory-signed` requires the lab key for every image under `registry.localtest.me:5001/inventory/`, and `prod` opts in. All three images are signed with the lab key, so all three are admitted. Each release is meant to carry a review statement, an attestation with the predicate type `https://inventory.example/review/v1`, signed with the lab key:

| Tag | Review attestation |
| --- | --- |
| `6.15.0` | `approved` is `true` (reviewer `alice`, ticket `CHG-1042`) |
| `6.14.1` | `approved` is `false` (reviewer `bob`, ticket `CHG-1007`) |
| `6.14.0` | None |

## Your task

1. Extend the key authority of `inventory-signed` so it also requires a review attestation of the type above whose `approved` field is `true`.
2. Prove with server-side dry runs in `prod` that `6.15.0` is admitted and `6.14.1` and `6.14.0` are refused.

## Constraints

- Keep the policy name `inventory-signed`, its glob and its key authority. The policy must enforce.
- Check the field with a CUE or Rego policy in the attestation entry.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- A key authority of `inventory-signed` lists an attestation with the predicate type `https://inventory.example/review/v1` and a policy that requires `approved` to be `true`.
- In `prod`, a dry run of `6.15.0` is admitted with no warning, and dry runs of `6.14.1` and `6.14.0` are refused.
- The webhook still fails closed and denies images no policy matches.
