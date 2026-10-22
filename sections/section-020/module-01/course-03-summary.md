# Summary

A key policy turns "our pipeline signed it" into a rule the cluster enforces. It needs two things to line up: a signature Policy Controller can read for the exact digest that runs, and a policy that trusts the matching public key for the right image patterns.

## What you learned

Cosign signs an image digest with a private key and stores a classic signature in the same repository, under a tag made of `sha256-`, the hex digest and `.sig`. For key authorities, Policy Controller v0.15.1 reads this classic format, not the newer Sigstore bundle format, so the lab signs with `--new-bundle-format=false`. Signing without the public transparency log keeps lab keys out of the public record, and verifying such a signature needs `--insecure-ignore-tlog=true`.

A `ClusterImagePolicy` lists `images` globs, `authorities` and a `mode`. Globs are matched against the image name with its digest; `*` stops at `/`, `**` does not, and the registry host must match exactly, port included. An image passes a policy when any one of its authorities accepts it, and it must pass every policy that matches it. A key authority takes the public key inline as `data`, from a Secret in the Policy Controller namespace with `secretRef`, or from a key management service with `kms`.

The `warn` mode checks images but admits the ones that fail, with a warning. It is the safe way to try a new policy, and it protects nothing if it is left on. The key facts to remember are these:

- Sign the digest, not the tag.
- Key authorities need the classic signature format in Policy Controller v0.15.1.
- `secretRef` Secrets live in `cosign-system`, and the first value in the Secret is the key.
- A missing port or a typo in a glob means the policy matches nothing, and the no-match policy decides instead.

<!-- astrona:playground:destroy -->
