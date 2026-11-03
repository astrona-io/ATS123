# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Helm configuration

## Scenario

Policy Controller is installed with the Helm release `policy-controller` in `cosign-system`. During a test, someone upgraded the release with `webhook.configData.no-match-policy` set to `allow`, so images that no `ClusterImagePolicy` matches are admitted in `prod`. No policy exists yet, so every image is currently admitted.

## Your task

1. Restore the safe setting: images that match no policy must be denied.
2. Make the change in the Helm release, so that a later `helm upgrade` keeps it.
3. Prove with a server-side dry run in `prod` that an unmatched image is refused.

## Constraints

- Keep the chart version 0.10.8 and every other value of the release: the pinned webhook image, the registry CA bundle, the failure policy and `enable-oci11`.
- Do not edit the ConfigMap by hand as the only change.
- Do not create a policy to make the dry run pass.

## Done when

- `helm get values policy-controller -n cosign-system` shows `webhook.configData.no-match-policy` as `deny`, and the other values are still there.
- The ConfigMap `config-policy-controller` holds `no-match-policy: deny`.
- A dry run of `registry.localtest.me:5001/inventory/podinfo:6.15.0` in `prod` is refused.
