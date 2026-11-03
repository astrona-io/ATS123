# Choosing Image Patterns

The `images` field decides which images a policy judges, and so which images it protects. A pattern that is too wide breaks other teams' workloads. A pattern that is too narrow leaves images to the no-match policy. This part compares the choices and builds a catch-all that closes the gaps.

## What a pattern matches

Each entry in `images` is a `glob`. Policy Controller matches it against the full image name, registry first, with the digest the mutating webhook wrote. The star `*` stops at a slash, and the double star `**` crosses slashes. The registry name, including a port, must be written exactly as it appears in the image.

That gives three useful shapes. An exact repository, `registry.localtest.me:5001/inventory/podinfo*`, covers one repository. The star at the end lets the name continue into the digest. A team prefix, `registry.localtest.me:5001/inventory/**`, covers everything a team publishes. A registry-wide pattern, `registry.localtest.me:5001/**`, covers the whole registry.

## Narrow policies, one per team

Narrow policies let each team own its key. A policy for `inventory/**` trusts the inventory key, and a policy for another prefix trusts that team's key. Neither team can sign for the other, because a policy only trusts its key for its own prefix.

Prepare the playground and apply the inventory policy:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
RELEASE="registry.localtest.me:5001/inventory/podinfo@$(ws regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0)"
ws env COSIGN_PASSWORD=lab-only-password cosign sign --key /work/keys/cosign.key \
  --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes "$RELEASE"
```

Save this as `clusterimagepolicy-inventory-signed.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-signed
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/podinfo*"
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

Then check the result:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

The signed image is admitted. The second image is refused by `inventory-signed`, because it matches the pattern and has no signature from the lab key.

## The gap, and a catch-all that closes it

Any image outside `inventory/podinfo*` matches no policy. Whether that image is admitted depends on the no-match policy, and `deny` is the safe value. A teammate may still want a clear message, or may want the no-match policy at `warn` while teams write their policies. A catch-all closes the gap in the policy itself: a policy with the pattern `**` and a `static` authority with `action: fail` refuses every image that matches it, with the policy name in the message.

Because every matching policy must pass, a catch-all with `fail` would also refuse the images that the narrow policies approve. Use a catch-all only for a registry or prefix that no narrow policy covers, for example a public registry you want to name in the error: a pattern `ghcr.io/**` with `static: {action: fail}`. Do not make it `**`.

Try it:

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

The image matches no policy, and the error says so. The error from a catch-all would name the policy instead, which tells the person who sees it where to look.

You can now choose between exact, prefix and registry-wide patterns and know what each leaves to the no-match policy. The next question is how to combine several keys.

## Common pitfalls

> [!WARNING]
> - **A pattern with `*` where the repository has a slash.** `inventory/*` misses `inventory/team/app`. Use `**`.
> - **A registry-wide `fail` catch-all.** It refuses images that other policies approve, because every matching policy must pass.
> - **A pattern without the digest in mind.** `.../podinfo` matches only the exact name, and the image name has a digest at the end; end the pattern with `*` or `**`.
> - **Relying on a no-match policy of `allow`.** Unpatterned images then run unchecked.
