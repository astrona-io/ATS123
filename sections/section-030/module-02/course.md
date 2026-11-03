# Keyless Identity Rules And Trust Roots

A keyless policy is only as good as its identity rule, and the rule is only as good as the trust behind the certificate. This module takes the keyless authority apart: how to narrow an identity until it names one workflow, how to accept more than one legitimate signer, what the transparency log settings do, and how a private Sigstore installation is described to the cluster.

Keep one sentence in mind: **a keyless authority trusts a certificate authority and a log, and then an identity rule decides who may sign.** The first half is about trust roots, the second half about identities, and a mistake in either one admits the wrong images.

The module has four parts. **Narrowing A Keyless Identity** replaces a loose pattern with an exact one, and a graded lab follows it. **Several Identities And Several Authorities** shows how to accept more than one signer. **Transparency Logs And Signature Formats** explains the `ctlog` field and the two signature formats. **Trust Roots For A Private Sigstore** describes a `TrustRoot` resource.

## Learning objectives

After this module you can:

- Write a `subjectRegExp` that matches one release workflow on release tags and nothing else.
- Test an identity expression against matching and non-matching subjects before applying it.
- Accept two signers in one authority, and explain the difference from two authorities.
- Explain what the `ctlog` field of an authority selects.
- Choose between the classic and the bundle signature format for a given image.
- Describe the three ways a `TrustRoot` can hold keys.

## Before you start

You need to know how a keyless signature is made, what Fulcio and Rekor do, and what issuer and subject mean. You need to be able to write a keyless authority with an identity.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in `cosign-system`, with no policy. `prod` opts in. The webhook reads the public-good trust root, so the cluster needs internet access. The `workstation` pod holds `cosign`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
