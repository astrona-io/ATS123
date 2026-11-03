# Signatures In Another Repository

By default cosign stores a signature in the same repository as the image, and Policy Controller looks there. Some organisations keep signatures elsewhere: the image repository is read-only for the signing pipeline, or one central repository holds all signatures. This part shows how to sign into another repository and how to point a key authority at it.

## Where cosign puts the signature

For the image `registry.localtest.me:5001/inventory/podinfo@sha256:<digest>`, cosign writes the signature to the tag `sha256-<digest>.sig` in the repository `registry.localtest.me:5001/inventory/podinfo`. The environment variable `COSIGN_REPOSITORY` changes the repository. With `COSIGN_REPOSITORY=registry.localtest.me:5001/inventory/signatures`, the same tag is created in that repository instead, and the image repository stays untouched.

Sign `6.15.0` that way:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
REPO=registry.localtest.me:5001/inventory/podinfo
ws env COSIGN_PASSWORD=lab-only-password COSIGN_REPOSITORY=registry.localtest.me:5001/inventory/signatures \
  cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$REPO@$(ws regctl image digest $REPO:6.15.0)"
ws regctl tag ls registry.localtest.me:5001/inventory/signatures
```

The listing shows the `sha256-...sig` tag in the signature repository.

## Tell the authority where to look

An authority can have a `source` list. Each entry has an `oci` field with a repository, and optionally `signaturePullSecrets`, a list of Secret names in `cosign-system` that hold registry credentials for that repository, and `tagPrefix`, a prefix that the signing tool added to the tag. With `source` set, Policy Controller reads signatures from the listed repository instead of the image's own.

Save this as `clusterimagepolicy-inventory-central.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-central
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: central-signatures
      key:
        secretRef:
          name: inventory-public-key
      source:
        - oci: registry.localtest.me:5001/inventory/signatures
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-inventory-central.yaml
```

Then check the result:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

`6.15.0` is admitted, because its signature is in the central repository. `6.14.1` is refused, because that repository holds no signature for its digest. A signature stored next to the image no longer counts for this authority.

## Credentials and access

If the signature repository is private, the webhook needs credentials. Create a Secret of type `kubernetes.io/dockerconfigjson` in `cosign-system` and name it in `signaturePullSecrets`. The Secret never needs write access: the webhook only reads.

You now know how to keep signatures out of the image repository and how to tell the webhook where they are. One more tool limits where a policy applies.

## Common pitfalls

> [!WARNING]
> - **Setting `COSIGN_REPOSITORY` when you sign but not `source` in the policy.** The webhook looks next to the image and finds nothing.
> - **Putting the Secret for `signaturePullSecrets` in the pod's namespace.** It must be in `cosign-system`.
> - **Granting the webhook write access to the signature repository.** Read access is enough.
> - **Assuming old signatures move with the setting.** Signatures made before the change stay in the old repository.
