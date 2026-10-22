# Solution: Enforce Signatures In The prod Namespace

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `prod` opts in, `prod` refuses `6.14.1` and admits `6.15.0`, `dev` still admits `6.14.1`, and the webhook still fails closed.

## Step 1: Reproduce the problem

Ask for the unsigned image in `prod`, and look at the labels of the namespace:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl get namespace prod --show-labels
```

The dry run succeeds, and `prod` has no `policy.sigstore.dev/include` label. The policy exists, but the API server never calls Policy Controller for this namespace.

## Step 2: Opt prod in

Add the label the webhooks select on:

```sh
kubectl label namespace prod policy.sigstore.dev/include=true
```

## Step 3: Prove the result

Ask for both images in `prod`, and the unsigned one in `dev`:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n dev run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The first request is refused with an error from the webhook `policy.sigstore.dev` that names `inventory-signed`. The second and third succeed. Then confirm that the safe settings are unchanged:

```sh
kubectl get validatingwebhookconfiguration policy.sigstore.dev -o jsonpath='{.webhooks[*].failurePolicy}{"\n"}'
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data.no-match-policy}{"\n"}'
```

The failure policy is `Fail` and `no-match-policy` is `deny`.

## Step 4: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Label `dev` as well | `dev` refuses unsigned images too, and the grader requires `dev` to stay open |
| Label with `enabled` or `yes` | The selector asks for exactly `true`, so nothing changes |
| Set `no-match-policy: allow` | Every image without a policy is admitted silently in `prod` |
| Edit `inventory-signed` | The policy was never the problem |

## Practice on your own

- Remove the label again with `kubectl label namespace prod policy.sigstore.dev/include-` and watch `6.14.1` pass.
- Ask for `ghcr.io/stefanprodan/podinfo:6.15.0` in `prod` and read why it is refused.
