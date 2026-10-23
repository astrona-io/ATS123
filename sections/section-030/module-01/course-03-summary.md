# Summary

Keyless signing moves trust from a private key to an identity. A policy built on it admits an image only when a specific identity signed it, so a leaked key or a signature from another project no longer counts.

## What you learned

A keyless signature starts with an OpenID Connect identity token, for example the token GitHub gives a workflow. Fulcio checks the token and issues a short-lived X.509 certificate for a fresh public key, writing the token's issuer and subject into it. Rekor records the signature, so it can be checked after the certificate expires. For a GitHub Actions workflow, the issuer is `https://token.actions.githubusercontent.com` and the subject is the URL of the workflow file in its repository, followed by `@` and the Git reference it ran on.

A keyless authority in a `ClusterImagePolicy` names the Fulcio instance with `url` and the allowed `identities`, each with an issuer and a subject or their regular expression forms. The image must have a signature with a certificate that chains to a trusted root, a transparency log entry, and a matching identity. Images signed by cosign v3 use the Sigstore bundle format, which Policy Controller v0.15.1 cannot verify for image signatures yet; it verifies images signed in the classic format, such as podinfo 6.10.0.

The identity is the whole security of a keyless policy. Anchor every regular expression with `^` and `$`, escape the dots, and leave only the release tag free. Cover the whole registry with the glob, so images from other projects are checked and refused, not handed to the no-match policy. Private Sigstore instances are trusted through a `TrustRoot` resource that the authority names with `trustRootRef`. The key facts to remember are these:

- The issuer for GitHub Actions is `https://token.actions.githubusercontent.com`.
- The subject names the repository, the workflow file and the Git reference.
- `issuerRegExp: .*` with `subjectRegExp: .*` trusts anyone who can get a public Fulcio certificate.
- Test an identity with `cosign verify --certificate-identity` before it goes into a policy.

<!-- astrona:playground:destroy -->
