# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Admission control

## Scenario

The release team signs every `inventory` image with the lab key, and the `ClusterImagePolicy` named `inventory-signed` already requires that signature. Yet a test shows that the namespace `prod` still accepts the unsigned image `registry.localtest.me:5001/inventory/podinfo:6.14.1`:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

## Your task

1. Make Policy Controller check every pod in the namespace `prod`.
2. Prove with server-side dry runs that `prod` refuses `inventory/podinfo:6.14.1` and admits `inventory/podinfo:6.15.0`.

## Constraints

- Leave the namespace `dev` as it is: it must keep admitting `6.14.1`.
- Do not change the webhook's failure policy, and do not allow images that match no policy.
- Do not change or delete `inventory-signed`.

## Done when

- `prod` carries the label Policy Controller selects on.
- A dry run of `6.14.1` in `prod` is refused and a dry run of `6.15.0` in `prod` is admitted.
- A dry run of `6.14.1` in `dev` is admitted, the webhook's failure policy is `Fail`, and `no-match-policy` is not `allow` or `warn`.
