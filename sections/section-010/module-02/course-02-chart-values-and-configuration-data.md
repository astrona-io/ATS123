# Chart Values And Configuration Data

Helm turns values into the objects it installs, so every Policy Controller setting that you want to keep has a value behind it. This part reads the values of the release, shows how the `configData` value becomes the ConfigMap, and changes a setting the safe way. It ends with a lab on exactly that change.

## Values that this course sets

A **values** file is YAML that overrides a chart's defaults. Read what was set on the release, not the chart's full defaults:

<!-- astrona:playground:renew -->

```sh
helm get values policy-controller -n cosign-system
```

Four settings appear under `webhook`. `image` pins the webhook image by digest, which is newer than the chart's default. `registryCaBundle` names a ConfigMap and a key with a certificate authority that the webhook trusts. `failurePolicy: Fail` tells the API server to refuse requests when the webhook cannot answer. `configData` holds the keys that become `config-policy-controller`.

Check that the ConfigMap matches the values:

```sh
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data}{"\n"}'
```

The keys `no-match-policy` and `enable-oci11` appear with the values from `configData`. The first sets what happens to images no policy matches, and the second turns on discovery of signatures stored with the OCI 1.1 referrers layout.

## Change a setting in the release

To change a value, run `helm upgrade` with `--reuse-values` so the other values stay, and set the key. Use `--set-string` for values that must stay text:

```sh
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 -n cosign-system \
  --reuse-values --set-string webhook.configData.no-match-policy=warn --wait
```

The release revision rises by one, the ConfigMap changes, and the webhook rolls to pick up the new value. Read the ConfigMap again and then put the safe value back the same way:

```sh
kubectl -n cosign-system get configmap config-policy-controller -o jsonpath='{.data.no-match-policy}{"\n"}'
helm upgrade policy-controller sigstore/policy-controller --version 0.10.8 -n cosign-system \
  --reuse-values --set-string webhook.configData.no-match-policy=deny --wait
```

Without `--reuse-values`, Helm would reset every value you did not repeat to the chart default. That would silently remove the pinned image and the certificate bundle.

## Why not edit the ConfigMap

`kubectl edit configmap config-policy-controller` changes the object at once. It does not change the release, so the next `helm upgrade` replaces the ConfigMap with the release's values and the edit is lost, often at the worst moment. A change in the release also leaves a record: `helm history policy-controller -n cosign-system` lists each revision with its time and status.

You can now find where a setting lives and change it so that it stays. The mission asks you to apply this to an installation where someone changed a setting in the wrong place.

## Common pitfalls

> [!WARNING]
> - **Running `helm upgrade` without `--reuse-values` or a values file.** Helm resets every unset value to the chart default.
> - **Using `--set` for a value like `true` or `deny`.** Use `--set-string` when the value must stay text.
> - **Changing the ConfigMap by hand during an incident.** Do it in the release, or the next upgrade removes the fix.
> - **Not waiting for the rollout.** The webhook reads the ConfigMap on start, so check with `kubectl -n cosign-system rollout status deployment/policy-controller-webhook`.

## Your mission: Make A Setting Stick In The Helm Release

You can now read the values of a release and change one without losing the others. The graded lab starts with an installation where someone relaxed the no-match policy for a test, and the cluster admits images that no policy covers. The task is to restore the safe setting so that it survives an upgrade.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-010-02
astrona start ats-123-playground-010-02
```
