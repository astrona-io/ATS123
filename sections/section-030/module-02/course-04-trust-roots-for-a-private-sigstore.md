# Trust Roots For A Private Sigstore

An organisation that runs its own Fulcio and Rekor must tell the cluster which keys and certificates to trust, because the built-in trust is for the public-good instance. The `TrustRoot` resource holds that information. This part describes what it can contain and how an authority points to it.

## What a TrustRoot is

A `TrustRoot` is a cluster resource in the group `policy.sigstore.dev`. Its `spec` has three alternative ways to supply trust. It holds exactly the keys and certificates that the authorities need: the certificate chain of the Fulcio, the public key of the Rekor log, the key of the certificate transparency log, and optionally a timestamp authority.

The three ways are:

| Field | What it holds | Use it when |
| --- | --- | --- |
| `remote` | A TUF mirror address and an initial `root` file | The organisation publishes its trust through a TUF repository, which keeps keys rotatable |
| `repository` | A serialized TUF repository | The cluster has no access to the mirror |
| `sigstoreKeys` | The certificate authorities, logs and timestamp authorities, written directly | You manage a few keys by hand |

TUF, The Update Framework, is a system for distributing and rotating trusted keys safely, so `remote` lets the keys change without editing the cluster resource.

## The sigstoreKeys form

In `sigstoreKeys`, `certificateAuthorities` lists the Fulcio certificate chains, each with a `subject`, a `uri` and a `certChain`. `tLogs` lists the Rekor logs, each with a `baseURL`, a `hashAlgorithm` and a `publicKey`. `ctLogs` lists the certificate transparency logs in the same form, and `timestampAuthorities` lists timestamp authorities like the certificate authorities.

The certificate chain and the public keys are PEM text that is stored in the resource in encoded form. You obtain them from the person who runs the Sigstore installation, never from the signer.

## Pointing an authority at it

An authority uses the resource by name. A keyless authority sets `trustRootRef` to the name of the `TrustRoot`, and the `ctlog` of the same authority sets the same `trustRootRef`. Authorities that use a private Sigstore do not need the public-good internet access.

List the trust roots of a cluster, and read one:

<!-- astrona:playground:renew -->

```sh
kubectl get trustroot
kubectl explain trustroot.spec --api-version=policy.sigstore.dev/v1alpha1
```

The first command lists the resources, and there are none in the playground. The second prints the fields of `spec` from the resource definition in the cluster, which is the most reliable reference for the version you run. Use `kubectl explain` on `clusterimagepolicy.spec.authorities` the same way when you need a field name.

## Trust is a decision

A trust root is the most sensitive resource of a keyless setup. Anyone who can change it can make the cluster trust their own certificate authority. Limit who may create and update `TrustRoot` and `ClusterImagePolicy` resources with RBAC, review changes like code, and keep the content in version control.

You can now describe how a private Sigstore is trusted and where the setting lives. That finishes the keyless authority: identity, logs, formats and roots.

## Common pitfalls

> [!WARNING]
> - **Letting many users edit a `TrustRoot`.** It decides who is trusted.
> - **Using a `remote` mirror with a root file you did not verify.** The first root is the anchor of trust.
> - **Naming the trust root in `keyless` but not in `ctlog`.** The log check then uses a different root.
> - **Copying the chain from the signer.** Obtain it from the operator of the Sigstore installation.
