# Summary

A signature is only useful when something checks it before a pod is stored. In Kubernetes, that check happens in admission webhooks, and Policy Controller is Sigstore's admission webhook for container images.

## What you learned

The API server calls mutating admission webhooks first and validating admission webhooks last. Policy Controller registers one of each, both named `policy.sigstore.dev`. The mutating webhook replaces every image tag in a pod with a digest, so the image the node starts is the image that was checked. The validating webhook checks that digest against every `ClusterImagePolicy` that matches it, and every matching policy must pass.

A server-side dry run sends a pod through all of these steps and stores nothing. Policy Controller's webhooks have no side effects, so the API server calls them during a dry run, and the result is the webhook's real decision. That makes `kubectl run --dry-run=server` the quickest way to test a policy, even when the node could not pull the image.

Policy Controller also checks higher-level workload objects through their pod template, and replaces a tag with the digest it resolved, so a Deployment is refused when it is applied, not when its pods start. An error message names the webhook, the image, the policy and the reason, and the webhook's log adds the detail; reading them in a fixed order finds the cause of a refusal quickly.

Three settings frame every policy. Policy Controller only sees namespaces with the label `policy.sigstore.dev/include=true`. An image that no policy matches follows the no-match policy in the ConfigMap `config-policy-controller`, which denies by default and can be set to `warn` or `allow`. When the webhook cannot answer, the API server follows the webhook's failure policy, and only `Fail` keeps an outage from admitting unchecked images. The key facts to remember are these:

- The opt-in label is exactly `policy.sigstore.dev/include=true`.
- `no-match-policy` is `deny` when it is not set; `allow` admits every unknown image silently.
- A failure policy of `Fail` refuses pods during a webhook outage; `Ignore` admits them.
- The chart owns the ConfigMap and the failure policy, so lasting changes go through `helm upgrade`.

<!-- astrona:playground:destroy -->
