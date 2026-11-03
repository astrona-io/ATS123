# Policies As Code

A policy that exists only in a cluster has no history, no review and no way back. This part keeps policies in files, applies them from version control, and tests them against sample images before they reach the cluster.

## One file per policy

Keep each `ClusterImagePolicy` in its own file in a repository, with the name of the policy as the file name. Changes then arrive as pull requests, and the diff shows what a change trusts. Secrets that hold public keys are public information, but they belong in the same repository so a key change is reviewed too.

```
policies/
  inventory-signed.yaml
  tools-signed.yaml
  keys/
    inventory-public-key.yaml
    tools-public-key.yaml
```

## Check a file before applying it

`kubectl` can validate a file against the cluster's resource definition without storing anything. A server-side dry run runs the validating and defaulting webhooks of Policy Controller for the policy itself:

<!-- astrona:playground:renew -->

```sh
kubectl apply --dry-run=server -f policies/inventory-signed.yaml
```

A mistake in a field name or a missing required field is reported before anyone applies the file. A policy that is valid can still be wrong, so also test it against sample images.

## Test with sample images

The most useful test of a policy is the one that asks the webhook about images whose outcome you know. Keep a short list in the repository, one image per line with the expected result, and run it after the policy is applied to a test cluster:

```sh
while read -r EXPECT NAMESPACE IMAGE; do
  if kubectl -n "$NAMESPACE" run "check-$RANDOM" --image="$IMAGE" --dry-run=server >/dev/null 2>&1; then GOT=allow; else GOT=deny; fi
  [ "$GOT" = "$EXPECT" ] && echo "ok    $IMAGE" || echo "WRONG $IMAGE expected $EXPECT got $GOT"
done <<'LIST'
allow prod registry.localtest.me:5001/inventory/podinfo:6.15.0
deny prod registry.localtest.me:5001/inventory/podinfo:6.14.0
LIST
```

The list has positive and negative cases. Every time someone files a bug about an image that was wrongly refused or admitted, add it to the list.

## Apply from the repository

Apply policies from the repository with a pipeline, not from laptops. The pipeline runs the validation and the tests, then applies. Tools such as Argo CD or Flux can do the apply step, and they also revert a change made by hand in the cluster, which keeps the cluster and the repository identical.

## Common pitfalls

> [!WARNING]
> - **Editing a policy with `kubectl edit`.** The change is not reviewed and is lost at the next apply.
> - **Testing only on production.** Keep a test cluster with the same policies.
> - **A test list without negative cases.** It passes while the policy admits everything.
> - **Letting many people write to the policy repository without review.** A policy decides who is trusted.
