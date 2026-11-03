# Several Identities And Several Authorities

Organisations rarely have one signer. A project may sign releases from a workflow and also accept a release engineer who signs by hand. This part shows two ways to accept more than one signer and explains how they differ in what they check.

## Several identities in one authority

A keyless authority has a list of `identities`. A signature passes the authority when its certificate matches any one of them. All identities in the list share the same Fulcio URL and the same trust root, because they belong to one authority.

Save this as `clusterimagepolicy-two-signers.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: two-signers
spec:
  images:
    - glob: "ghcr.io/stefanprodan/**"
  authorities:
    - name: release-signers
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$
          - issuer: https://accounts.google.com
            subject: release-engineer@example.com
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-two-signers.yaml
```

Then check the result:

<!-- astrona:playground:renew -->

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
```

The podinfo image is admitted through the first identity. An image signed by the engineer's Google account would pass through the second. An image signed by anyone else is refused.

## Several authorities

The same two signers can also be written as two authorities, each with its own `keyless` block. For identities that use the same Fulcio, the result is the same, because authorities are alternatives. The difference shows when the signers use different trust: one authority can name the public-good Fulcio and another can use a private Fulcio through `trustRootRef`, or one can be a key authority. In that case the signers cannot share one authority.

| Choice | Use it when |
| --- | --- |
| Several identities in one authority | All signers get certificates from the same Fulcio and logs |
| Several authorities | Signers differ in key, Fulcio, log or attestations |

Authorities also carry attestation rules. Put an attestation requirement on the authority that signed the attestation, so a different rule can apply to each signer.

## Naming the authorities

The `name` of an authority appears in refusal messages. A name such as `release-signers` tells the reader which rule failed. A default name such as `authority-0` tells nobody anything. Use short names that say what the authority represents.

You can now accept more than one signer without widening a pattern. The next question is what the log settings of an authority do.

## Common pitfalls

> [!WARNING]
> - **Merging a wide and a narrow identity into one regular expression with `|`.** Keep one identity per signer.
> - **Adding an identity of an unrelated provider by habit.** Each identity is a signer you trust.
> - **Giving authorities generic names.** The refusal message loses its meaning.
> - **Using an email subject as proof of a person.** It proves control of that account at signing time.
