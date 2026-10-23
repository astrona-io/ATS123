# Solution: Fix A Keyless Policy That Trusts Too Much

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the shape of `podinfo-release`, the two dry runs in `prod`, and the webhook's safe settings.

## Step 1: Reproduce the problem

```sh
kubectl -n prod run check --image=ghcr.io/fluxcd/source-controller:v1.9.6 --dry-run=server
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
```

Both are admitted. The Flux image comes with no warning at all, and the podinfo image may come with a warning from the policy.

## Step 2: Read the policy and the settings

```sh
kubectl get clusterimagepolicy podinfo-release -o yaml
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data.no-match-policy}{"\n"}'
```

There are four faults. The identity uses `issuerRegExp: .*` and `subjectRegExp: .*`, so any keyless signature counts. The glob is `ghcr.io/stefanprodan/**`, so the Flux image is not covered by the policy at all. The policy has `mode: warn`. And `no-match-policy` is `allow`, so the uncovered Flux image was admitted silently.

## Step 3: Fix the policy

Save this as `clusterimagepolicy-podinfo-release.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: podinfo-release
spec:
  images:
    - glob: "ghcr.io/**"
  authorities:
    - name: podinfo-release-workflow
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-podinfo-release.yaml
```

## Step 4: Fix the no-match policy

```sh
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 \
  --namespace cosign-system --reuse-values \
  --set-string webhook.configData.no-match-policy=deny --wait
```

If the chart repository is missing on your machine, add it first with `helm repo add sigstore https://sigstore.github.io/helm-charts`.

## Step 5: Prove the result

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
kubectl -n prod run check --image=ghcr.io/fluxcd/source-controller:v1.9.6 --dry-run=server
```

The podinfo image is admitted with no warning, and the Flux image is refused by `podinfo-release`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the identity | The Flux image is still outside the glob and the no-match policy still allows it |
| Fix only the glob | The `.*` identity accepts the Flux signature |
| Add a `static` `fail` authority for `ghcr.io/fluxcd/**` | It blocks one project and lets every other one in; the grader requires keyless authorities only |

## Practice on your own

- Add a second policy for `ghcr.io/fluxcd/**` that trusts the Flux workflows, and read the Flux image's subject with `cosign verify` first.
- Set `no-match-policy` to `warn` and see how the warning reads for an image no policy covers.
