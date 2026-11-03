# Key Pairs And Key Protection

A key policy is only as strong as the care taken with the private key. Whoever holds it can sign an image that the cluster will run. This part shows what cosign puts in a key pair, how the private key is protected on disk, and why large organisations keep it in a key management service instead.

## What `cosign generate-key-pair` creates

Cosign makes two files. `cosign.pub` is the public key in PEM text, an ASCII format that wraps the key in `-----BEGIN PUBLIC KEY-----` lines. It holds an ECDSA public key on the P-256 curve, and the policy needs only this file. `cosign.key` is the private key, also PEM text, encrypted with a password. The password is read from the environment variable `COSIGN_PASSWORD` or typed at a prompt.

Generate a second pair in the workstation pod, in a folder that does not touch the lab key, and look at the first line of each file:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'mkdir -p /work/demo && cd /work/demo && COSIGN_PASSWORD=demo-password cosign generate-key-pair && head -1 cosign.key cosign.pub'
```

The private key starts with a line that says it is an encrypted cosign private key, and the public key starts with the public key header. The private key file is useless without the password, but an attacker can try passwords offline, so the password must be long and random.

## Getting the public key back

You can derive the public key from the private key at any time:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'cd /work/demo && COSIGN_PASSWORD=demo-password cosign public-key --key cosign.key'
```

The command prints the PEM text, which is the same text as in `cosign.pub`. This is the text that goes into a policy as `key.data`, or into a Secret that `key.secretRef` names. Policy Controller never sees the private key, and it never needs it.

## Keeping the private key out of files

A key file on a build server is a target. Cosign can instead use a key that lives in a key management service (KMS), a service that signs data with a key it never gives out. Cosign addresses these keys with a URI scheme: `awskms://`, `gcpkms://`, `azurekms://` and `hashivault://`. The command `cosign sign --key awskms://...` sends the data to the service, and the service returns the signature.

The policy side matches. A key authority can set `kms` to the same style of URI, and Policy Controller fetches the public key from the service when it checks a signature. The webhook then needs permission to read the public key of that key, and nothing more. A KMS key also gives you an audit log of every signature and lets you disable the key in one place.

## Hash algorithm and rotation

A key authority has an optional `hashAlgorithm` field that defaults to `sha256`. Leave it alone unless the signer used another algorithm.

Rotation is the day when you replace a key. Because an authority holds one key, a policy with two authorities (the old and the new key) accepts images signed with either one during the change. The cluster keeps running while the pipeline moves to the new key. When every image that matters carries a signature from the new key, you remove the old authority. This works because an image passes a policy when any one of its authorities accepts it.

You now know what a key pair is, how to get the public key for a policy, and why a key management service is the better home for a production key. The open question is what to check when an image is signed but the cluster still refuses it.

## Common pitfalls

> [!WARNING]
> - **Putting `cosign.key` into a Secret that the cluster reads.** A policy needs the public key only. Keep the private key with the signer.
> - **Committing `cosign.key` to a repository.** The password is the only protection left; rotate the key if this happens.
> - **A weak or shared `COSIGN_PASSWORD`.** Anyone with the file can try passwords offline.
> - **Deleting the old authority first during a rotation.** Images signed with the old key are refused at once.
