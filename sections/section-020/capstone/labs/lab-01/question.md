# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Key policies

## Scenario

A colleague wrote the `ClusterImagePolicy` `inventory-signed` for the `inventory` images and tested it in `prod`. Nothing was ever refused, so they declared it working. You notice that `kubectl` prints warnings on almost every pod in `prod`, including on the release image.

The registry `registry.localtest.me:5001` holds `inventory/podinfo:6.15.0` (signed with the lab key), `6.14.1` (signed with another key) and `6.14.0` (not signed). The lab public key is in the Secret `inventory-public-key` in `cosign-system`. Other Secrets in that namespace hold keys that are no longer trusted.

## Your task

1. Find every reason why `inventory-signed` refuses nothing, and why images that match no policy are admitted in `prod`.
2. Fix the policy and Policy Controller's settings so that `prod` admits only `inventory` images signed with the lab key.

## Constraints

- Keep the policy name `inventory-signed`. It must enforce, and must not contain a `static` authority.
- Do not change the webhook's failure policy, and do not uninstall Policy Controller.

## Done when

- `inventory-signed` enforces, covers every image under `registry.localtest.me:5001/inventory/`, and trusts exactly the lab public key.
- In `prod`, a dry run of `6.15.0` is admitted with no warning, and dry runs of `6.14.1` and `6.14.0` are refused.
- `no-match-policy` is `deny` or not set, and the webhook's failure policy is `Fail`.
