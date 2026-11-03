# Require Images Signed With Your Key

A release pipeline that signs its images gives you a simple, strong rule: run only what the pipeline signed. Policy Controller can enforce that rule if you tell it which images it covers and which public key to trust. Anything else, including an image signed with a different key, is refused before the pod is stored.

Keep one sentence in mind: **a key policy trusts one public key for one set of image patterns, and the signature must belong to the digest that runs.** Both halves matter. The right key on the wrong image pattern protects nothing, and the wrong key refuses your own releases.

The module has four parts. **Signing Images For The Cluster** signs an image by digest with the lab key pair, verifies it with `cosign verify`, and finds where the signature lives in the registry. **Key Authorities In A ClusterImagePolicy** writes the policy that trusts that key, explains image globs and the ways to give Policy Controller a public key, and compares `enforce` with `warn`. A graded lab follows the second part. **Key Pairs And Key Protection** covers what `cosign generate-key-pair` creates, how to get the public key back and how to protect the private key, and **Why A Signed Image Is Refused** is a checklist for the case where a signed image is refused anyway.

## Learning objectives

After this module you can:

- Sign an image by digest with `cosign sign --key` and verify it with `cosign verify --key`.
- Explain where cosign stores a classic signature in the registry.
- Write a `ClusterImagePolicy` with `images` globs and a key authority.
- Give Policy Controller a public key as inline `data`, as a Secret, or as a KMS reference.
- Explain how a policy in `warn` mode behaves, and when to use it.
- Prove a key policy with dry runs of a signed, a wrongly signed and an unsigned image.

## Before you start

You need to know what an image digest is and what an admission webhook does: Policy Controller resolves every image to a digest and checks it against every `ClusterImagePolicy` that matches. The namespace `prod` opts in with the label `policy.sigstore.dev/include=true`, and images that match no policy are refused there.

Your playground is a single-node `kind` cluster with **Policy Controller v0.15.1** in `cosign-system` and **no policy yet**, so `prod` refuses every image. The lab registry `registry.localtest.me:5001` holds `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`, both unsigned. The `workstation` pod holds `cosign` v3.1.4, `regctl` and a lab-only key pair in `/work/keys` (`cosign.key` and `cosign.pub`, password `lab-only-password`).

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
