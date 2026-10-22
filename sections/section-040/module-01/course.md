# Check Attestations And Roll Policies Out

A signature tells you that the release pipeline approved an image. It does not tell you that the image was built by your build service from your repository, or that it has no critical vulnerabilities. Those are statements about the image, and Sigstore carries them as attestations: signed documents attached to the image, which Policy Controller can require and read.

Keep one sentence in mind: **an attestation check is only as useful as the policy that reads it, and a policy is only safe after it has run in warn mode.** A policy that refuses the wrong images on day one gets switched off; a policy that only warns forever protects nothing.

The module has two parts. **Attestation Policies With CUE And Rego** attaches SLSA provenance to an image with `cosign attest`, and extends a key policy so it requires provenance from one build service, checked with a CUE policy. A graded lab follows it. **Rolling Out Policies And Reading Denials** covers warn mode, the order in which to turn things on, and how to read why the webhook refused a pod.

## Learning objectives

After this module you can:

- Explain what an in-toto attestation, a predicate and a predicate type are.
- Attach a SLSA provenance attestation with `cosign attest` and check it with `cosign verify-attestation`.
- Add an `attestations` entry with a CUE policy to a key authority.
- Write a Rego policy for an attestation.
- Roll out a policy with warn mode and opt-in namespaces, and switch it to enforcement.
- Find the reason for a refusal in the error message and the webhook's log.

## Before you start

You need to know how a key-based `ClusterImagePolicy` works: `images` globs choose the images, a key authority trusts one public key, and every matching policy must pass. You need to know what a server-side dry run is: `kubectl run --dry-run=server` returns the webhook's decision without storing anything.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in `cosign-system`. The key policy `inventory-signed` covers `registry.localtest.me:5001/inventory/**`, and the images `inventory/podinfo:6.15.0` and `6.14.1` are both signed with the lab key, so both are admitted in `prod`. The `workstation` pod holds `cosign` v3.1.4, the lab key pair in `/work/keys` (password `lab-only-password`), and four predicate files in `/work`: `provenance-trusted.json`, `provenance-laptop.json`, `scan-6.15.0.json` and `scan-6.14.1.json`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
