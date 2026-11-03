# Summary

A real registry needs more than one key policy. The design choices are few, and each follows from a small number of rules.

## What you learned

Image patterns decide what a policy judges. The star stops at a slash, the double star does not, and the registry name must match exactly. Narrow policies per team keep each key limited to its own prefix, and a catch-all with a `fail` static authority names the policy in the error for a registry you want to refuse, as long as it does not overlap the narrow policies.

Authorities inside one policy are alternatives: an image passes when any one accepts it. Policies that match one image are all required: the image must pass every one. A key rotation uses the first rule by listing the old and the new key as two authorities, and ends by removing the old one.

An authority reads signatures from the image's own repository unless `source` names another. The signer writes there with `COSIGN_REPOSITORY`, and private repositories use `signaturePullSecrets` in the Policy Controller namespace. The `match` field limits a policy to resource kinds and labels, and objects it leaves out fall to the no-match policy. The key facts to remember are these:

- Alternatives inside a policy, requirements across policies.
- Keep the old authority until nothing you run depends on it.
- A signature location must match between signing and `source`.
- `match` narrows a policy, and it is not a security boundary.

<!-- astrona:playground:destroy -->
