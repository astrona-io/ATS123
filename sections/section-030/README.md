# Section 030: Keyless Policies And Identities

A key policy trusts whoever holds a private key. Keys leak, get copied into the wrong pipeline and outlive the people who made them. Keyless signing replaces the long-lived key with an identity: Sigstore's certificate authority, Fulcio, issues a short-lived certificate that names who signed, for example one GitHub Actions workflow of one repository.

This section teaches Policy Controller to trust identities instead of keys. You read the identity in a real keyless signature from a public image, then write a policy that admits images only when that exact identity signed them, and refuses images signed by anyone else, even with a perfectly valid signature.

**Topic covered:** Keyless policies

## What you will learn

- What a keyless signature contains: a short-lived Fulcio certificate, the issuer and the subject.
- What the identity of a GitHub Actions workflow looks like.
- Verifying a keyless signature with `cosign verify` and an identity.
- Keyless authorities: `url`, `identities` with `issuer`, `subject` and their regular expression forms.
- The Sigstore bundle format, the classic signature format Policy Controller v0.15.1 verifies, and the transparency log check.
- `TrustRoot` resources for private Sigstore instances.

## The learning path

The section has two modules. Each module has a landing page, four parts, a graded lab right after the part it tests, a summary and a knowledge check. Each module has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Trust Signing Identities Instead Of Keys

The playground has Policy Controller running with no policy, `prod` opted in, and `no-match-policy` set to `warn` so you can experiment. The examples are public images on `ghcr.io` that were signed keylessly by GitHub Actions.

1. Keyless Signatures And The Identity In The Certificate
2. Keyless Authorities, Identities And Trust Roots, followed by the lab **Require Images Signed By The podinfo Release Workflow**
3. Inside A Fulcio Certificate
4. Identity Providers And Subjects
5. Summary

### 2. Keyless Identity Rules And Trust Roots

The playground has Policy Controller running and a workstation pod with the tools. The examples use the public podinfo release image that GitHub Actions signed keylessly.

1. Narrowing A Keyless Identity, followed by the lab **Narrow A Keyless Identity Pattern**
2. Several Identities And Several Authorities
3. Transparency Logs And Signature Formats
4. Trust Roots For A Private Sigstore
5. Summary

## Section capstone: Fix A Keyless Policy That Trusts Too Much

A keyless policy exists for `ghcr.io`, but it accepts any identity from any issuer, covers only one user's images, only warns, and images outside it are allowed. A Flux controller image, validly signed by another project, walks straight into `prod`. Narrow the policy until only the podinfo release workflow counts. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-123-capstone-030
```
