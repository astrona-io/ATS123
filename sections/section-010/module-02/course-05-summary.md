# Summary

Policy Controller is a component with settings, and the way the settings are changed decides whether they last. Its objects come from one Helm release, and the release is the place to make changes.

## What you learned

The chart creates two custom resource kinds, `ClusterImagePolicy` and `TrustRoot`, a Deployment that runs the webhook, a ConfigMap `config-policy-controller` with the settings, a ConfigMap `config-image-policies` that the webhook writes itself, and mutating and validating webhook configurations. The values of the release, read with `helm get values`, set the image, the trusted registry authority, the failure policy and the configuration data.

A lasting change goes through `helm upgrade` with `--reuse-values` and `--set-string`. A change made by hand with `kubectl edit` disappears at the next upgrade. The webhook is itself a registry client: it trusts a private registry through `registryCaBundle`, uses the pod's pull secrets for images and `signaturePullSecrets` for signatures, and fails with an access or certificate error that has no policy name when either is wrong.

Because the failure policy is `Fail`, the availability of the webhook is the availability of deployments in the opted-in namespaces. Upgrade with more than one replica, test one pass and one fail after each change, and treat `helm uninstall` as the removal of enforcement. The key facts to remember are these:

- Change settings in the release, never in the ConfigMap.
- `helm upgrade` without `--reuse-values` resets values to the chart defaults.
- A registry error without a policy name is not a signature problem.
- Removing the webhook configurations admits every image.

<!-- astrona:playground:destroy -->
