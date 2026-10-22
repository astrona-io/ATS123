# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Attestation policies

## Scenario

The `ClusterImagePolicy` `inventory-signed` requires the lab key for every image under `registry.localtest.me:5001/inventory/`, and `prod` opts in. All three images are signed with the lab key, so all three are admitted. Only one of them was built by the trusted build service:

| Tag | SLSA v1 provenance attestation (signed with the lab key) |
| --- | --- |
| `6.15.0` | `runDetails.builder.id` is `https://ci.inventory.example/builder@v1` |
| `6.14.1` | `runDetails.builder.id` is `https://laptop.inventory.example/manual-build` |
| `6.14.0` | None |

## Your task

1. Extend the key authority of `inventory-signed` so it also requires a SLSA v1 provenance attestation (`https://slsa.dev/provenance/v1`) whose builder ID is `https://ci.inventory.example/builder@v1`.
2. Prove with server-side dry runs in `prod` that `6.15.0` is admitted and `6.14.1` and `6.14.0` are refused.

## Constraints

- Keep the policy name `inventory-signed`, its glob and its key authority. The policy must enforce.
- Check the builder ID with a CUE or Rego policy in the attestation entry.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- A key authority of `inventory-signed` lists an attestation with predicate type `https://slsa.dev/provenance/v1` and a policy that requires the builder `https://ci.inventory.example/builder@v1`.
- In `prod`, a dry run of `6.15.0` is admitted with no warning, and dry runs of `6.14.1` and `6.14.0` are refused.
- The webhook still fails closed and denies images no policy matches.
