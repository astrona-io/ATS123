# Opting Namespaces In And Failing Closed

A policy only protects the pods that reach it. Three settings decide which pods those are, and they matter more than any single policy: the label that opts a namespace in, the no-match policy for images no policy covers, and the failure policy the API server follows when the webhook cannot answer. This part sets each one and shows what it changes.

## Opting a namespace in

Policy Controller checks nothing by default. Its webhooks only see pods in namespaces with the label `policy.sigstore.dev/include=true`, so you choose which namespaces it guards. Teams usually start with one production namespace and leave development namespaces out.

The namespace `prod` in the playground does not carry the label yet. Ask for a pod with the unsigned image there:

<!-- astrona:playground:renew -->

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The dry run succeeds: `kubectl` reports that the pod was created in a server dry run. The policy `inventory-signed` exists and the image is not signed, but the API server never asked Policy Controller. Now opt `prod` in and ask again:

```sh
kubectl label namespace prod policy.sigstore.dev/include=true
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

This time the request fails with an error from the webhook `policy.sigstore.dev` that names `inventory-signed`. The same request in `dev` still succeeds, because `dev` has no label. One label turned enforcement on for one namespace and nowhere else.

## Images that no policy matches

The policy `inventory-signed` only matches images under `registry.localtest.me:5001/inventory/`. Every other image in an opted-in namespace matches no policy at all. What happens to such an image is set by the **no-match policy**, a setting with three values: `deny` refuses the image, `warn` admits it with a warning, and `allow` admits it silently. When the setting is missing, Policy Controller denies.

The setting lives in the ConfigMap `config-policy-controller` in the namespace `cosign-system`, under the key `no-match-policy`. Read it:

```sh
kubectl -n cosign-system get configmap config-policy-controller -o yaml
```

The data holds `no-match-policy: deny` and a second key, `enable-oci11`, which the course turns on so the webhook can find signatures stored with the newer OCI referrers layout. The Helm chart writes this ConfigMap from its `webhook.configData` value, so a lasting change goes through `helm upgrade`, not `kubectl edit`.

Ask for a public image that no policy matches in `prod`:

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

The webhook refuses it, and the message says the image matches no policy. This is the safe default for a production namespace: an image nobody thought about is an image nobody approved. Teams that are still writing their policies often set `warn` for a while, so they can see which images would fail without breaking deployments.

## When the webhook cannot answer

The API server calls the webhook over the network. If the webhook pods are down, overloaded or unreachable, the API server must still decide what to do with the pod. The **failure policy** of the webhook configuration decides: `Fail` refuses the request, and `Ignore` admits it as if the webhook had said yes.

Print the failure policy of the validating webhook:

```sh
kubectl get validatingwebhookconfiguration policy.sigstore.dev \
  -o jsonpath='{.webhooks[*].failurePolicy}{"\n"}'
```

It prints `Fail`, the chart's default (`webhook.failurePolicy`). With `Fail`, an outage of Policy Controller stops new pods in opted-in namespaces, which is loud but safe. With `Ignore`, the same outage silently admits every image, signed or not. An attacker who can overload the webhook then has a way around every policy.

> [!TIP]
> When a namespace suddenly refuses every pod, check the webhook pods first with `kubectl -n cosign-system get pods`. A failure policy of `Fail` turns a webhook outage into refused pods, and the error message names the webhook it could not reach.

You now control the frame around every policy: which namespaces are checked, what happens to images no policy covers, and what happens when the webhook is down. A namespace that opts in, a no-match policy of `deny` and a failure policy of `Fail` together make Policy Controller fail closed.

## Common pitfalls

> [!WARNING]
> - **Labelling the wrong namespace, or with the wrong value.** The selector asks for exactly `policy.sigstore.dev/include=true`; `enabled` or `yes` matches nothing.
> - **Setting `no-match-policy` to `allow` to make an error go away.** Every image without a policy is then admitted silently in every opted-in namespace.
> - **Switching the failure policy to `Ignore` during an outage and forgetting it.** The cluster then admits unchecked images until someone notices.
> - **Editing `config-policy-controller` by hand.** The next `helm upgrade` writes the chart's values back.

## Your mission: Enforce Signatures In The prod Namespace

You can now opt a namespace in and check the safety settings around Policy Controller. The graded lab gives you a cluster where `inventory-signed` exists and the release image is signed, but `prod` still admits the unsigned image; make `prod` refuse it while `dev` and the webhook's safe settings stay as they are.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-010-01
astrona start ats-123-playground-010-01
```
