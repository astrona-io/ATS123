# Rolling Policies Out And Operating Them

A policy that is correct on paper can still stop a team's deployment on the first day, and a webhook that is not watched can fail without anyone noticing. This module covers the work after the policy is written: splitting policies by owner, moving them from warning to enforcement, keeping them in version control, and reading the signals the webhook gives.

Keep one sentence in mind: **a policy is a change to every deployment in the cluster, so it is rolled out like any other risky change, in small steps that can be undone.**

The module has four parts. **Splitting Policies By Owner** shows why one broad policy fails and how to divide it, and a graded lab follows it. **Staged Rollouts With Warn Mode** extends the warn-then-enforce path across namespaces. **Policies As Code** keeps policies in version control and checks them before they reach the cluster. **Monitoring The Webhook** covers logs, metrics and the failure modes that matter in production.

## Learning objectives

After this module you can:

- Split a broad policy into policies that each have one owner and one trusted signer.
- Roll a policy out one namespace at a time with warn mode.
- Keep policies in files and check them against sample images in CI.
- Read the webhook's logs and metrics to find refusals and failures.
- Explain how the failure policy and the replica count decide what an outage does.
- Describe a safe emergency procedure for an image that must run despite a policy.

## Before you start

You need to know how key policies, attestation entries and warn mode work. You need to know how to run a server-side dry run in `prod`.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** and the broad key policy `all-images`. It covers every image in the lab registry `registry.localtest.me:5001` and trusts the lab key. The registry holds `inventory/podinfo` images signed with the lab key and `tools/podinfo` images signed with a separate tools key. `prod` opts in. The `workstation` pod holds `cosign` v3.1.4, `regctl`, `jq`, and the key pairs in `/work/keys` (the lab key) and `/work/tools` (the tools key), with the password `lab-only-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
