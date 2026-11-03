# Install And Configure Policy Controller

Policy Controller is software that you install, configure and upgrade like any other cluster component. Its settings decide how strict the whole cluster is: what happens to images no policy covers, what happens when the webhook is down, and which registry certificates it trusts. A setting changed in the wrong place is lost at the next upgrade.

Keep one sentence in mind: **the Helm release is the source of truth for Policy Controller's settings, and anything changed in the cluster by hand disappears at the next `helm upgrade`.** Read settings from the cluster, but change them in the release.

The module has four parts. **What The Chart Installs** lists the objects in the namespace and the cluster. **Chart Values And Configuration Data** explains the values this course uses and how to change one with `helm upgrade`; a graded lab follows it. **Registries, Certificates And Pull Secrets** shows how the webhook reaches a registry. **Upgrades, Availability And Removal** covers what to check before and after a change.

## Learning objectives

After this module you can:

- List the objects that the Policy Controller chart creates.
- Read the values of a release with `helm get values`.
- Change a setting in the Helm release without losing the other settings.
- Explain how the webhook trusts a private registry certificate.
- Explain what a webhook outage does with each failure policy.
- Remove or upgrade Policy Controller without leaving the cluster unprotected.

## Before you start

You need to know what an admission webhook is, what the opt-in namespace label does, and what the no-match policy and the failure policy mean. You need basic Helm knowledge: a release, a chart, and values.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1**, installed with the Helm chart 0.10.8 as the release `policy-controller` in `cosign-system`, and no policy. `prod` opts in. The `workstation` pod holds `cosign` and `regctl`, and Helm 3.22.1 is installed on your terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
