# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Key policies

## Scenario

The namespace `prod` opts in to Policy Controller, but no `ClusterImagePolicy` exists, so it refuses every image. The registry `registry.localtest.me:5001` holds three images of `inventory/podinfo`:

| Tag | Signature |
| --- | --- |
| `6.15.0` | Signed with the lab key (`/work/keys/cosign.key` in the workstation pod) |
| `6.14.1` | Signed with a different key that nobody approved |
| `6.14.0` | Not signed |

The lab public key is already stored in the Secret `inventory-public-key` in the namespace `cosign-system`, and in `/work/keys/cosign.pub` in the workstation pod.

## Your task

1. Create a `ClusterImagePolicy` named `inventory-signed` that covers every image under `registry.localtest.me:5001/inventory/` and accepts only signatures made with the lab key.
2. Prove with server-side dry runs in `prod` that `6.15.0` is admitted and `6.14.1` and `6.14.0` are refused.

## Constraints

- The policy must enforce (no `warn` mode) and must not contain a `static` authority.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- `inventory-signed` exists, enforces, and one of its key authorities holds exactly the lab public key, inline or through a Secret.
- In `prod`, a dry run of `6.15.0` is admitted with no warning, and dry runs of `6.14.1` and `6.14.0` are refused.
- The webhook still fails closed and denies images no policy matches.
