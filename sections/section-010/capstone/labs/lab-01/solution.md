# Solution: Restore Enforcement After An Outage

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the webhook runs and fails closed with `no-match-policy` at `deny`, `prod` opts in, `prod` refuses the unsigned and the unknown image and admits the signed one, and `dev` still admits the unsigned image.

## Step 1: Inventory the workarounds

Look at every place that frames Policy Controller:

```sh
kubectl -n cosign-system get deployment policy-controller-webhook
kubectl get validatingwebhookconfiguration policy.sigstore.dev -o jsonpath='{.webhooks[*].failurePolicy}{"\n"}'
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data.no-match-policy}{"\n"}'
kubectl get namespace prod --show-labels
helm -n cosign-system get values policy-controller
```

There are four findings. The Deployment has zero replicas, the failure policy is `Ignore`, `no-match-policy` is `allow`, and `prod` lost its opt-in label. The Helm values show that the first three were changed through `helm upgrade` (`webhook.replicaCount`, `webhook.failurePolicy` and `webhook.configData`), so they must be fixed the same way, or the next upgrade brings them back.

## Step 2: Restore the Helm values

Change the three values back in one upgrade, keeping every other value:

```sh
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 \
  --namespace cosign-system --reuse-values \
  --set webhook.replicaCount=1 --set webhook.failurePolicy=Fail \
  --set-string webhook.configData.no-match-policy=deny --wait
```

If the chart repository is missing on your machine, add it first with `helm repo add sigstore https://sigstore.github.io/helm-charts`. Then check that the webhook pod is running:

```sh
kubectl -n cosign-system rollout status deployment/policy-controller-webhook
```

## Step 3: Opt prod in again

```sh
kubectl label namespace prod policy.sigstore.dev/include=true
```

## Step 4: Prove the result

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n dev run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The first two requests are refused: the first by `inventory-signed`, the second because no policy matches it. The last two succeed.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `kubectl scale` the Deployment and `kubectl edit` the webhook configuration | It works until the next `helm upgrade`, which writes the outage values back |
| Leave `no-match-policy` at `warn` | Unknown images are still admitted, only with a warning |
| Label `dev` too | `dev` was never part of enforcement, and the grader requires it to stay open |

## Practice on your own

- With the webhook at zero replicas and the failure policy at `Fail`, try a pod in `prod` and read the error that names the webhook.
- Run `helm -n cosign-system history policy-controller` and find the upgrade that introduced the workarounds.
