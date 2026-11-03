# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Policy design

## Scenario

One policy, `all-images`, covers the whole registry `registry.localtest.me:5001` and trusts only the lab key. The inventory team signs with the lab key. The tools team signs with its own key, whose public key is in the Secret `tools-public-key` in `cosign-system`. `prod` opts in.

| Image | Signature |
| --- | --- |
| `inventory/podinfo:6.15.0` | Lab key |
| `inventory/podinfo:6.14.0` | None |
| `tools/podinfo:6.15.0` | Tools key |
| `tools/podinfo:6.14.1` | Lab key, which the tools team does not accept |

Today the tools team's `6.15.0` is refused, although it is signed correctly.

## Your task

1. Replace `all-images` with two policies: `inventory-signed` for `registry.localtest.me:5001/inventory/**` trusting only the lab key, and `tools-signed` for `registry.localtest.me:5001/tools/**` trusting only the tools key.
2. Prove with server-side dry runs in `prod` that `inventory/podinfo:6.15.0` and `tools/podinfo:6.15.0` are admitted and that `inventory/podinfo:6.14.0` and `tools/podinfo:6.14.1` are refused.

## Constraints

- No policy may match both repositories, and no policy may trust more than one key.
- Both policies must enforce and must not contain a `static` authority.
- Do not change the webhook's failure policy or the no-match policy.

## Done when

- `inventory-signed` and `tools-signed` exist as described, and `all-images`, or any other policy that covers both repositories, does not.
- In `prod`, the two correctly signed images are admitted with no warning, and the unsigned inventory image and the tools image signed with the lab key are refused.
- The webhook still fails closed and denies images no policy matches.
