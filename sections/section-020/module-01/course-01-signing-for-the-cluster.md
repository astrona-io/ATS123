# Signing Images For The Cluster

A key policy can only check what is there, so the first job is a signature Policy Controller can find and read. This part signs an image with the lab key pair, verifies it the way the webhook will, and finds the signature in the registry.

## Sign the digest, not the tag

A cosign key pair is a private key that signs and a public key that verifies. `cosign generate-key-pair` writes them as `cosign.key` (encrypted with a password) and `cosign.pub`. The playground made the lab-only pair at start, in `/work/keys` in the workstation pod, with the password `lab-only-password`.

Cosign signs one image digest. If you give it a tag, it resolves the tag and signs the digest it found at that moment, so the safe habit is to look up the digest yourself and sign that. Open a shell in the workstation pod; the commands in this part all run there:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Look up the digest of the release image and keep it in a variable:

```sh
RELEASE="registry.localtest.me:5001/inventory/podinfo@$(regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0)"
echo "$RELEASE"
```

The variable now holds the image name, an `@` and the `sha256:` digest. Sign it with the lab key:

```sh
COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$RELEASE"
```

The three extra flags shape the signature for this cluster. `--new-bundle-format=false` writes the classic cosign signature format, because Policy Controller v0.15.1 only reads the newer Sigstore bundle format for keyless authorities, not for key authorities. `--use-signing-config=false` and `--tlog-upload=false` keep the signature out of the public Rekor transparency log, so a lab key never appears in the public record. All three flags are marked deprecated in cosign v3.1.4 but still work. `--yes` skips the confirmation question.

## Verify the signature

Before you trust a policy to check the signature, check it yourself with the public key:

```sh
cosign verify --key /work/keys/cosign.pub --insecure-ignore-tlog=true \
  --new-bundle-format=false "$RELEASE"
```

`cosign verify` prints a line that the signatures were verified against the key, followed by a JSON array with one entry per signature. Each entry holds the signed payload: the image name, its digest under `critical.image.docker-manifest-digest`, and the type `cosign container image signature`. `--insecure-ignore-tlog=true` tells cosign not to look for a Rekor entry, because you signed without one.

Now try the same command on the other image:

```sh
cosign verify --key /work/keys/cosign.pub --insecure-ignore-tlog=true \
  --new-bundle-format=false registry.localtest.me:5001/inventory/podinfo:6.14.1
```

It fails and says that no signatures were found. Nothing has signed `6.14.1`.

## Where the signature lives

Cosign stores a classic signature in the same repository as the image, under a tag made from the digest: `sha256-` followed by the hex digest, with `.sig` at the end. List the tags:

```sh
regctl tag ls registry.localtest.me:5001/inventory/podinfo
```

Next to `6.14.1` and `6.15.0` there is now one tag that starts with `sha256-` and ends with `.sig`. Its hex part is the digest of `6.15.0`. Policy Controller finds the signature the same way: it resolves the image to a digest, builds that tag name and reads it. That is why the signature belongs to the digest. Move the tag `6.15.0` to another image, and the new digest has no signature.

> [!TIP]
> When a key policy refuses an image you are sure you signed, list the tags with `regctl tag ls` and compare the `sha256-...sig` tag with the digest the webhook names in its error. A mismatch means the signature belongs to a different image than the one being deployed.

Leave the shell with `exit`. You now have one image signed with the lab key, a verified signature, and the knowledge of where Policy Controller will look for it. The open question is how to tell Policy Controller which images need this signature and which public key to trust.

## Common pitfalls

> [!WARNING]
> - **Signing a tag that moves later.** The signature belongs to the digest the tag pointed to when you signed.
> - **Forgetting `--new-bundle-format=false` for a key policy.** Cosign v3 writes the Sigstore bundle format by default, which Policy Controller v0.15.1 does not read for key authorities.
> - **Verifying without `--insecure-ignore-tlog=true` when you signed without the log.** Cosign then looks for a Rekor entry that does not exist and fails.
> - **Sharing the private key.** Only the public key `cosign.pub` goes to the cluster; the private key stays with the signer.
