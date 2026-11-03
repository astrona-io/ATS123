# Design Key Policies For A Real Registry

A real registry holds many repositories, signed by more than one team and with more than one key over time. One policy with one key and one glob stops being enough. This module teaches the design choices that remain after you can write a single key policy: how to pick image patterns, how several authorities and several policies combine, where signatures can be stored, and how to limit a policy to some resources.

Keep one sentence in mind: **authorities inside one policy are alternatives, and policies that match one image are all required.** Most design mistakes with Policy Controller come from reversing this rule.

The module has four parts. **Choosing Image Patterns** compares narrow patterns with a catch-all deny. **Several Authorities And Several Policies** applies the rule above, and a graded lab follows it: rotating a signing key without refusing the old releases. **Signatures In Another Repository** reads signatures from a repository you name. **Limiting A Policy To Some Resources** uses `match` to select resource kinds and labels.

## Learning objectives

After this module you can:

- Choose image patterns that cover a team's repositories and nothing else.
- Write a catch-all policy that refuses every image outside the approved registries.
- Combine several authorities in one policy for a key rotation.
- Explain which policies apply when two policies match one image.
- Tell Policy Controller to read signatures from a repository other than the image's own.
- Limit a policy to resource kinds and labels with `match`.

## Before you start

You need to write a key-based `ClusterImagePolicy` with a glob and a key authority from a Secret, and to prove it with server-side dry runs.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in `cosign-system` and no policy. The namespace `prod` opts in. The registry `registry.localtest.me:5001` holds `inventory/podinfo:6.15.0`, `6.14.1` and `6.14.0`, all unsigned. The Secret `inventory-public-key` in `cosign-system` holds the lab public key. The `workstation` pod holds `cosign`, `regctl` and the lab key pair in `/work/keys`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
