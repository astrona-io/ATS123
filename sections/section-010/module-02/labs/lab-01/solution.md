# Solution: Make A Setting Stick In The Helm Release

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the values of the Helm release, the ConfigMap that the release produces, and a dry run in `prod`.

## Step 1: Read the release

```sh
helm get values policy-controller -n cosign-system
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data}'
helm history policy-controller -n cosign-system
```

The values show `no-match-policy` as `allow`, together with the pinned image, the CA bundle, the failure policy and `enable-oci11`. The history shows the upgrade that changed it.

## Step 2: Upgrade the release

Reuse the existing values and change only the one setting:

```sh
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 -n cosign-system \
  --reuse-values --set-string webhook.configData.no-match-policy=deny --wait
```

`--reuse-values` keeps every other value. `--set-string` keeps `deny` as text.

## Step 3: Prove the result

```sh
helm get values policy-controller -n cosign-system
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
```

The values show `deny` and the other settings unchanged. The dry run is refused because no policy matches the image and the no-match policy is `deny`. A new row appears in `helm history`.

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```
