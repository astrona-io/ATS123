# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Admission control

## Scenario

Last night Policy Controller crashed during a release, and pods in `prod` could not start. To get the release out, an engineer made the cluster admit everything again. Nobody wrote down what they changed. This morning, `prod` admits the unsigned image `registry.localtest.me:5001/inventory/podinfo:6.14.1` and any image from any registry.

## Your task

Undo every workaround, so Policy Controller guards `prod` the way it did before the outage.

1. Find what was changed on the webhook, its settings and the namespaces.
2. Restore a running webhook that refuses pods when it cannot be reached, and that refuses images no policy matches.
3. Make `prod` refuse `inventory/podinfo:6.14.1` and any image no policy matches, and admit `inventory/podinfo:6.15.0`.

## Constraints

- Do not uninstall and reinstall Policy Controller, and do not change `inventory-signed`.
- Leave `dev` out of enforcement: it must keep admitting `6.14.1`.

## Done when

- The webhook Deployment has an available replica, the webhook's failure policy is `Fail`, and `no-match-policy` is `deny` or not set.
- `prod` opts in, refuses `6.14.1` and `ghcr.io/stefanprodan/podinfo:6.15.0`, and admits `inventory/podinfo:6.15.0`.
- `dev` admits `6.14.1`.
