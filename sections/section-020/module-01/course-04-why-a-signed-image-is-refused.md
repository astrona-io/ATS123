# Why A Signed Image Is Refused

The most common support question about a key policy is "the image is signed, so why does the cluster refuse it?". Almost every answer is one of a small set of mismatches between the signature and the policy. This part builds the policy again and walks through the mismatches one by one, with a test for each.

## Start from a working policy

Sign `6.15.0` with the lab key, copy the public key into a Secret, and apply the policy. Applying the policy again does nothing if it already exists. Start with the signature:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
RELEASE="registry.localtest.me:5001/inventory/podinfo@$(ws regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0)"
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$RELEASE"
ws cat /work/keys/cosign.pub > cosign.pub
kubectl -n cosign-system create secret generic inventory-public-key --from-file=cosign.pub=cosign.pub
```

Save this as `clusterimagepolicy-inventory-signed.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-signed
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: inventory-key
      key:
        secretRef:
          name: inventory-public-key
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-signed.yaml
```

If the Secret already exists, the first `create secret` command reports that and changes nothing. The policy admits `6.15.0` and refuses everything else under `inventory/`.

## The signature belongs to the digest

Cosign stores the signature next to the image under a tag derived from the digest. A new tag for the same image has the same digest, so it has the same signature. Add the tag `stable` to the signed image and ask for it:

```sh
ws regctl image copy registry.localtest.me:5001/inventory/podinfo:6.15.0 registry.localtest.me:5001/inventory/podinfo:stable
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:stable --dry-run=server
```

The request is admitted, because the webhook resolves `stable` to the signed digest. Now point `stable` at the unsigned image:

```sh
ws regctl image copy registry.localtest.me:5001/inventory/podinfo:6.14.1 registry.localtest.me:5001/inventory/podinfo:stable
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:stable --dry-run=server
```

The same tag name is refused now. A tag proves nothing; the digest behind it is what carries a signature, and moving the tag moved the trust.

## The checklist

When a signed image is refused, test these in order.

The signature may be for another digest. Compare `regctl image digest` of the tag with the digest in the error message. A multi-platform image has an index digest and a digest for each platform, and cosign signs the digest you give it, so sign the one the registry returns for the tag.

The signature may be made with another key. Run `cosign verify --key /work/keys/cosign.pub --insecure-ignore-tlog=true --new-bundle-format=false <image>` in the workstation pod. A failure here is not a policy problem.

The signature may be in the newer bundle format. A key authority reads the classic format in Policy Controller v0.15.1. List the tags with `regctl tag ls` and look for the `sha256-<digest>.sig` tag.

The policy may hold another key. Compare the Secret `inventory-public-key` with `/work/keys/cosign.pub`, byte for byte. A key rotated in the pipeline but not in the Secret refuses every new release.

The glob may miss the image, so the failure is not the key at all. The error message then has no policy name.

You can now separate a signing problem from a policy problem with one `cosign verify` command and one `regctl` listing. The next step is policies with more than one authority.

## Common pitfalls

> [!WARNING]
> - **Signing a tag that moves.** The signature stays with the old digest while the tag points somewhere new.
> - **Signing the platform digest but deploying the index.** Sign what `regctl image digest` returns for the reference that pods use.
> - **Comparing key files with a different line ending.** Compare the PEM text after you strip spaces and newlines.
> - **Fixing the policy when the signature is wrong.** Run `cosign verify` first, and change the policy only if it succeeds.
