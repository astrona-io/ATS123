# Inspecting Attestations

A policy that checks an attestation fails in confusing ways when you cannot see the attestation. This part shows where an attestation is stored, how to read its three layers, and which predicate types cosign can write, so that you can compare what is attached to an image with what a policy asks for.

## The envelope, the statement and the predicate

An attestation has three layers. The outer layer is a **DSSE envelope** (Dead Simple Signing Envelope), a signed wrapper with a `payloadType`, a base64 `payload` and a list of `signatures`. The payload decodes to an **in-toto statement**: JSON with `_type`, `subject` (the image name and digest), `predicateType` and `predicate`. The predicate is the claim itself, and its shape depends on the predicate type.

Cosign stores the envelope in the registry, next to the image, under a tag made of `sha256-`, the digest and `.att`. Because the tag is built from the digest, an attestation belongs to one digest, like a signature does.

## Attach a custom attestation and look at it

The predicate types that cosign knows by short name are `slsaprovenance`, `slsaprovenance02`, `slsaprovenance1`, `link`, `spdx`, `spdxjson`, `cyclonedx`, `vuln`, `openvex` and `custom`. The type `custom` carries any JSON you choose and uses the predicate type `https://cosign.sigstore.dev/attestation/v1`.

Write a small review record in the workstation pod and attach it to the signed image:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws sh -c 'printf "{\"reviewedBy\":\"release-board\",\"ticket\":\"CHG-2041\"}" > /work/review.json'
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
  --type custom --predicate /work/review.json \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes \
  "$REPO@$(ws regctl image digest $REPO:6.15.0)"
```

The three flags at the end are the same as for signing: the classic format that key authorities read, and no upload to the public log. List what is attached to the image:

```sh
ws cosign tree registry.localtest.me:5001/inventory/podinfo:6.15.0
```

The listing shows the attestations attached to the image, each with its digest. Every attestation you add appears as another layer in the same `.att` image.

## Read and verify the statement

`cosign verify-attestation` checks the signature on the envelope and prints it. Pipe it through `jq` to decode the payload:

```sh
ws cosign verify-attestation --key /work/keys/cosign.pub --type custom \
  --insecure-ignore-tlog=true --new-bundle-format=false registry.localtest.me:5001/inventory/podinfo:6.15.0 \
  | ws jq -r '.payload | @base64d | fromjson | {predicateType, predicate}'
```

The output shows the predicate type `https://cosign.sigstore.dev/attestation/v1` and the review record. Compare these two fields with the `predicateType` and the policy of the `attestations` entry. A policy that asks for the wrong type, or for a field that the predicate does not have, fails on a perfectly good image.

You can now see an attestation the way the webhook sees it: a statement with a predicate type and a predicate, signed by a key or an identity. The next question is how the webhook decides that the statement is good enough.

## Common pitfalls

> [!WARNING]
> - **Reading the envelope and stopping.** The payload is base64. Decode it to see the predicate.
> - **Attesting a tag that moves.** An attestation belongs to one digest; a new build needs a new attestation.
> - **Mixing up `--type slsaprovenance` and `--type slsaprovenance1`.** They write different predicate types.
> - **Expecting `custom` attestations to be checked by a policy automatically.** Nothing reads them until an `attestations` entry asks for that predicate type.
