# Summary

A keyless authority has two halves that must both be right: the trust behind the certificate, and the identity rule that decides who may sign. An error in either half admits the wrong image.

## What you learned

An identity rule is narrow when it names the issuer exactly and the subject down to the repository, the workflow file and the kind of Git reference. A loose pattern such as every workflow of one owner accepts test workflows and other repositories. Test a pattern with sample subjects that must match and sample subjects that must not, before it reaches the cluster.

A keyless authority may list several identities that share one Fulcio and one set of logs. Use several authorities when the signers differ in key, Fulcio, log or attestation rules. Name authorities so refusal messages say which rule failed.

The `ctlog` field of an authority selects the Rekor log, and a key authority without it skips the log check. Policy Controller v0.15.1 reads key authorities only in the classic signature format and not the Sigstore bundle format. A private Sigstore is described by a `TrustRoot`, with a remote TUF mirror, a serialized repository or directly written keys, and an authority points to it with `trustRootRef`. The key facts to remember are these:

- Narrow to the repository, the workflow file and the reference type.
- Several identities share trust; several authorities can differ in trust.
- `ctlog` selects Rekor, not the certificate log.
- Whoever edits a `TrustRoot` decides who is trusted.

<!-- astrona:playground:destroy -->
