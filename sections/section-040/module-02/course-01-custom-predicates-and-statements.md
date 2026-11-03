# Custom Predicates And Statements

Cosign knows a few predicate types by name, such as `slsaprovenance1` and `vuln`. Anything else can be attached with a predicate type that you choose. This part attaches a review statement to an image, reads it back, and shows what a policy will see.

## The statement and its three parts

An attestation is an in-toto statement with a `subject`, a `predicateType` and a `predicate`. The `subject` lists the image digest. The `predicateType` is a URI that names the kind of statement. The `predicate` is the content, and it is yours to define for a custom type.

Cosign has the alias `custom`, which uses the predicate type `https://cosign.sigstore.dev/attestation/v1`. For a type of your own, give `--type` a URI. Use an address that your organisation controls, so nobody else defines the same type with a different meaning.

## Attach a review statement

<!-- astrona:playground:renew -->

The workstation holds a predicate file for each image. Read the one for `6.15.0`:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws cat /work/review-6.15.0.json
```

The file is a small JSON object with the fields `reviewer`, `ticket` and `approved`. Attach it to the image by digest, with the lab key, in the classic format:

```sh
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
  --type https://inventory.example/review/v1 --predicate /work/review-6.15.0.json \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes \
  "$REPO@$(ws regctl image digest "$REPO:6.15.0")"
```

Do the same for `6.14.1` with `/work/review-6.14.1.json`. Then read the statement back:

```sh
ws sh -c 'cosign verify-attestation --key /work/keys/cosign.pub \
  --type https://inventory.example/review/v1 --insecure-ignore-tlog=true --new-bundle-format=false \
  registry.localtest.me:5001/inventory/podinfo:6.15.0 | jq -r .payload | base64 -d | jq .'
```

The output is the full statement. The `predicateType` is the URI you chose, and `predicate` holds the three fields. This is exactly the document that a policy receives.

## What the policy sees

Policy Controller verifies the signature first and passes the decoded statement to the policy. A policy therefore writes `predicateType` and `predicate.approved` at the top level, never a path into the signed envelope. An attestation that fails verification never reaches the policy, so a policy cannot be fooled by an unsigned statement.

A statement is only a claim. The signature tells you who made the claim, and the policy tells you whether the claim is enough. A review statement signed with the same key that signs releases proves that someone with that key said the review happened.

> [!TIP]
> Version your predicate type in the URI, as in `/review/v1`. When the fields change, a new type lets old and new policies live side by side.

## Common pitfalls

> [!WARNING]
> - **Using `--type custom` for two different statements.** Both get the same predicate type, so a policy cannot tell them apart. Use one URI per kind.
> - **Attaching to a tag instead of a digest.** The tag can move; attach to the digest.
> - **A predicate file that is not valid JSON.** Cosign accepts it, and the policy fails later.
> - **Looking for the fields under `payload`.** Policy Controller has already decoded it.
