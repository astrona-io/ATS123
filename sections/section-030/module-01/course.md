# Trust Signing Identities Instead Of Keys

Every key policy has the same weak point: the private key. Whoever holds it can sign anything, and you cannot tell from the signature whether it came from the release pipeline or from a laptop. Keyless signing moves the trust from a key to an identity that a certificate authority checked at the moment of signing.

Keep one sentence in mind: **a keyless signature is only as strict as the identity you require.** A valid Fulcio certificate proves that someone with some identity signed. Your policy decides which issuer and which subject count, and a loose regular expression turns "our release workflow" into "anyone on GitHub".

The module has four parts. **Keyless Signatures And The Identity In The Certificate** explains how Fulcio, the OpenID Connect (OIDC) token and the transparency log work together, and reads the identity of a real signed image with `cosign verify`. **Keyless Authorities, Identities And Trust Roots** writes the keyless policy, explains exact and regular expression identities, the bundle format and `TrustRoot` resources for private Sigstore instances. A graded lab follows the second part. **Inside A Fulcio Certificate** reads the facts a certificate carries and explains why it lives for minutes, and **Identity Providers And Subjects** lists the issuer and subject of common providers and shows how to test an expression before it goes into a policy.

## Learning objectives

After this module you can:

- Explain what Fulcio checks and what it writes into a keyless certificate.
- Name the issuer and the subject of a GitHub Actions workflow identity.
- Verify a keyless signature with `cosign verify` and an exact identity.
- Write a keyless authority with `url` and `identities`.
- Write a subject regular expression that matches one repository's workflow and nothing else.
- Explain which signature format Policy Controller v0.15.1 can verify, and when a policy needs a `ctlog` or a `TrustRoot`.

## Before you start

You need to know what an admission webhook is and how a `ClusterImagePolicy` works: `images` globs choose the images, an image passes when any one of the `authorities` accepts it, and every matching policy must pass. The namespace `prod` opts in with the label `policy.sigstore.dev/include=true`.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in `cosign-system`, **no policy**, and `no-match-policy: warn`, so unmatched images are admitted with a warning while you experiment. The examples are two public images that were signed keylessly in GitHub Actions: `ghcr.io/stefanprodan/podinfo:6.10.0` and `ghcr.io/fluxcd/source-controller:v1.9.6`. The `workstation` pod holds `cosign` v3.1.4. Both the workstation and Policy Controller need outbound internet: they read the public signatures from `ghcr.io` and the Sigstore public-good trust root.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
