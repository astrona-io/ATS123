# Transparency Logs And Signature Formats

Two fields of an authority decide how a signature is found and how its time is proven: `ctlog`, which selects the transparency log, and `signatureFormat`, which selects how the signature is stored. This part explains both and shows how to tell the format of an image before you write a policy for it.

## The ctlog field

An authority's `ctlog` names the Rekor log to check. In spite of its name, it is not the certificate transparency log. It has two fields: `url`, the address of a Rekor instance, and `trustRootRef`, the name of a `TrustRoot` that holds the log's public key. When `ctlog` is absent for a keyless authority, Policy Controller uses the public-good Rekor and the public-good trust root. For a key authority with no `ctlog`, the transparency log check is skipped, which is how the key policies in this course work with signatures that were never uploaded.

Two things follow. A keyless authority for the public-good instance needs no `ctlog`, but it needs internet access. A keyless authority for a private Sigstore must name its log, or the check fails for lack of a trusted key.

A third field, `rfc3161timestamp`, names a `TrustRoot` that holds a timestamp authority. It is used for signatures with a signed timestamp in place of a log entry.

## Two signature formats

Cosign v2 and earlier wrote a signature as a separate image tagged `sha256-<digest>.sig`. Cosign v3 can write a Sigstore **bundle**, a single JSON file that carries the signature, the certificate and the log entry. The authority field `signatureFormat` is `legacy` by default and may be `bundle`.

Policy Controller v0.15.1 checks key authorities only in the classic format. For image signatures in the bundle format, it reports that bundle support is not implemented yet. So the format of the image decides what you can enforce, and you should check it before you choose an example or write a policy.

Look at the tags of a public image in the workstation pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'cosign tree ghcr.io/stefanprodan/podinfo:6.10.0'
```

The listing shows the kind of signature objects attached to the image. A line for a signature with a `.sig` tag means the image carries a classic signature. A bundle appears as a different kind of referrer object. Compare this to a newer podinfo release when you want to see the difference.

## Choosing what to check

If your pipeline signs with cosign v3 and the default bundle format, a Policy Controller at v0.15.1 cannot enforce those images. Either sign with the flag for the classic format, as the key examples in this course do, or wait for a Policy Controller release that supports bundles. Do not weaken the policy to make the error go away.

You now know the two log-related fields and the two formats. The remaining piece is how a private installation of Sigstore is described to the cluster.

## Common pitfalls

> [!WARNING]
> - **Assuming `ctlog` is about certificates.** It selects the Rekor log.
> - **Setting `signatureFormat: bundle` to fix a format error.** The error says bundle support is missing, so it fails the same way.
> - **Leaving `ctlog` out for a private Sigstore.** The public log key does not verify entries from your own log.
> - **Choosing an example image without `cosign tree`.** Check the format first.
