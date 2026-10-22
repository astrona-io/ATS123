# Keyless Authorities, Identities And Trust Roots

A keyless policy has to say three things: which Sigstore instance to trust, which identities count, and in which format the signatures are stored. This part writes a keyless authority that admits only the podinfo release workflow's images, and then looks at the extra settings a private Sigstore instance needs.

## A keyless authority

A keyless authority replaces the public key with the address of a Fulcio instance and a list of identities. Its fields are:

| Field | What it does |
| --- | --- |
| `url` | The Fulcio instance whose certificates count, for example `https://fulcio.sigstore.dev` for the public-good instance |
| `identities` | A list of allowed identities. Each one has an `issuer` or `issuerRegExp`, and a `subject` or `subjectRegExp` |
| `ca-cert` | The root certificate of a private Fulcio, inline or from a Secret |
| `trustRootRef` | The name of a `TrustRoot` resource for a private Sigstore instance |
| `insecureIgnoreSCT` | Skips the check of the certificate transparency proof that Fulcio embeds; only for test instances |

An image passes the authority when its signature has a Fulcio certificate that chains to a trusted root, has a matching transparency log entry, and has an issuer and subject that match one of the identities. Two more fields sit next to `keyless` on the same authority: `ctlog`, which names the Rekor instance to check against (the public Rekor when it is missing), and `signatureFormat`.

## The bundle format

Cosign v3 stores signatures in the Sigstore bundle format by default: one JSON document with the signature, the certificate and the transparency log evidence, attached to the image through the OCI referrers layout. The podinfo release image was signed this way. Policy Controller reads the classic cosign format unless an authority sets `signatureFormat: bundle`, and in v0.15.1 it reads the bundle format only for keyless authorities. The course also sets `enable-oci11: "true"` in Policy Controller's settings, so the webhook can find signatures stored with the referrers layout.

## Write the policy

<!-- astrona:playground:renew -->

The policy below covers every image from `ghcr.io` and accepts only signatures made by the podinfo release workflow on a tag. Save this as `clusterimagepolicy-podinfo-release.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: podinfo-release
spec:
  images:
    - glob: "ghcr.io/**"
  authorities:
    - name: podinfo-release-workflow
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$
      signatureFormat: bundle
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-podinfo-release.yaml
```

The issuer is exact. The subject is a regular expression because the tag changes with every release. It starts with `^` and ends with `$`, so it must match the whole subject. The dots in `github.com`, `.github` and `release.yml` are escaped with `\.`, because an unescaped `.` matches any character. The only free part is the tag after `refs/tags/`.

Then check the result with both images:

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=ghcr.io/fluxcd/source-controller:v1.9.6 --dry-run=server
```

The podinfo image is admitted. The Flux image matches the glob too, so the same policy checks it, and it is refused: its keyless signature is valid, but no identity of `podinfo-release-workflow` matches its subject. The webhook needs a few seconds for the first check of an image, because it fetches the public-good trust root and the signature from `ghcr.io`.

## How loose identities fail

A regular expression that is too loose admits more than you meant. `subjectRegExp: .*` with `issuerRegExp: .*` accepts every keyless signature from every identity provider that the public Fulcio trusts: anyone with a GitHub, Google or Microsoft account can sign an image that passes. `^https://github\.com/stefanprodan/.*` accepts every workflow of every repository of one user, including test workflows that run on pull requests. Write the narrowest expression that still matches every legitimate release, and test it with `cosign verify --certificate-identity-regexp` before you apply it.

## Private Sigstore instances

The policy above trusts the public-good instance, whose keys Policy Controller receives through The Update Framework (TUF), a system for distributing and rotating trusted keys safely. An organisation that runs its own Fulcio and Rekor describes them in a `TrustRoot` resource and points the authority at it with `trustRootRef`. A `TrustRoot` holds one of three things: a `remote` TUF mirror and its initial `root.json`, a serialized TUF `repository` for clusters without internet access, or the `sigstoreKeys` of each certificate authority and log entered by hand. With the bundle format, the `ctlog` and the timestamp authority of the same authority must use the same `trustRootRef`.

You now have a keyless policy that admits one workflow's images from a whole registry and refuses everyone else's. Together with key policies, that covers the two ways an image can earn trust; what remains is checking statements about how an image was built.

## Common pitfalls

> [!WARNING]
> - **An unanchored regular expression.** Without `^` and `$`, `github.com/stefanprodan/podinfo/` also matches a subject in another repository whose name contains that text.
> - **Unescaped dots.** `release.yml` as a regular expression also matches `releaseXyml`; escape it as `release\.yml`.
> - **Missing `signatureFormat: bundle` for an image signed by cosign v3.** The webhook looks for a classic signature, finds none, and refuses a correctly signed image.
> - **A glob that covers only the allowed project.** `ghcr.io/stefanprodan/**` leaves every other `ghcr.io` image to the no-match policy, which may admit it.

## Your mission: Require Images Signed By The podinfo Release Workflow

You can now read a keyless identity and require it in a policy. The graded lab asks for a policy on every `ghcr.io` image that admits the podinfo release and refuses an image signed by another project's workflow.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-030-01
astrona start ats-123-playground-030-01
```
