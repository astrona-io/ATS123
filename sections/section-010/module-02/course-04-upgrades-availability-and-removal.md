# Upgrades, Availability And Removal

A webhook with `failurePolicy: Fail` sits in the path of every new pod in the opted-in namespaces. That makes the webhook's own availability a cluster concern. This part covers how to upgrade without a gap, how to keep the webhook available, and what removing it does.

## What a webhook outage does

The failure policy decides what the API server does when the webhook cannot answer. With `Fail`, requests for opted-in namespaces are refused until the webhook is back. With `Ignore`, they are admitted without any check. The course keeps `Fail`, so the webhook must stay up. A rolling upgrade of a single replica leaves a short time with no replica, and requests in that moment are refused.

Look at the replica count and the update strategy that the release uses:

<!-- astrona:playground:renew -->

```sh
kubectl -n cosign-system get deployment policy-controller-webhook -o jsonpath='{.spec.replicas}{" "}{.spec.strategy.type}{"\n"}'
helm show values sigstore/policy-controller --version 0.10.8 | grep -n -i -E 'replica|affinity|resources'
```

The first command prints the replica count and the strategy. The second lists the chart values that control replicas and scheduling, so you can see the exact names for this chart version before you set any. Set more than one replica for a cluster where an upgrade must not refuse deployments.

## Upgrading safely

Plan an upgrade in this order. Read the notes of the new chart and the new application version. Compare the CRD schema, because the new version may add fields; check the served versions with `kubectl get crd clusterimagepolicies.policy.sigstore.dev -o jsonpath='{.spec.versions[*].name}'` before and after. Upgrade with `--reuse-values` or with the same values file. Wait for the rollout, and run the dry-run checks of your most important policies: one image that must pass and one that must fail.

If something goes wrong, `helm rollback policy-controller <revision> -n cosign-system` returns to an earlier revision. List the revisions with `helm history policy-controller -n cosign-system`.

## Removing Policy Controller

`helm uninstall policy-controller -n cosign-system` removes the Deployment and the webhook configurations. Once the webhook configurations are gone, the API server stops calling the webhook, and every image is admitted again, signed or not. Removal is therefore a change in the security of the whole cluster, and it needs the same review as an upgrade.

Whether the CRDs and the policies remain depends on how the chart ships them. Check after any removal with `kubectl get crd | grep sigstore` and `kubectl get clusterimagepolicy`. A policy that remains does nothing without a webhook.

You now know how to keep the webhook available, how to upgrade it in a controlled way, and what removing it means for the cluster. That closes the installation and configuration of Policy Controller.

## Common pitfalls

> [!WARNING]
> - **Upgrading a single-replica webhook during working hours.** Requests in the gap are refused under `Fail`.
> - **Switching to `Ignore` to make an upgrade easier.** It stays in place unless you change it back.
> - **Running `helm uninstall` as a clean-up step.** It removes enforcement for the whole cluster.
> - **Upgrading without a pass and a fail test afterwards.** A silent change in behaviour is found only by testing both.
