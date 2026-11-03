# Combining Attestations

An image often needs several statements: it was built by the build service, it was reviewed, and it has no critical vulnerabilities. This part shows how to require all of them, and how the entries, the authorities and the policies combine.

## Several entries in one authority

The `attestations` list of an authority can hold any number of entries. Every entry must pass for the authority to accept the image, so the list is an AND:

```yaml
authorities:
  - name: inventory-key
    key:
      secretRef:
        name: inventory-public-key
    attestations:
      - name: trusted-builder
        predicateType: https://slsa.dev/provenance/v1
        policy:
          type: cue
          data: |
            predicateType: "https://slsa.dev/provenance/v1"
            predicate: runDetails: builder: id: "https://ci.inventory.example/builder@v1"
      - name: reviewed
        predicateType: https://inventory.example/review/v1
        policy:
          type: cue
          data: |
            predicateType: "https://inventory.example/review/v1"
            predicate: approved: true
```

An image needs a valid signature and both statements, all made with the key of this authority. Each entry has its own name, so a refusal names the entry that failed.

## Several authorities

Authorities in one policy are alternatives. An image passes when any one authority passes, including all of that authority's own attestation entries. Use this when two groups sign differently, for example images from the build service with provenance, or images from a vendor with only a signature. Keep the requirements for each group inside its own authority.

## Several policies

Policies are combined the other way. Every policy whose glob matches the image must pass. Use separate policies for rules that belong to different owners, such as a security team rule on vulnerabilities and a release team rule on reviews. Each owner changes one policy without touching the other.

<!-- astrona:playground:renew -->

Try it with the two statements of the playground. Make two policies on the same glob, `inventory-signed` with the review entry and `inventory-vulns` with the vulnerability entry, using the vulnerability policy from the rollout module. Attach the vulnerability predicates first, then compare the answers:

```sh
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=registry.localtest.me:5001/inventory/podinfo:6.14.1 --dry-run=server
```

`6.14.1` is refused by both policies, and the message lists each failure. `6.15.0` passes both.

| Combine with | Meaning | Use it when |
| --- | --- | --- |
| Entries in one authority | All must pass | One signer vouches for several facts |
| Authorities in one policy | Any one passes | Different signers are accepted |
| Policies on one image | All must pass | Different owners set different rules |

## Keep the rules readable

Name every entry for the fact it checks, not for how it checks it. Keep one fact per entry, so a refusal says what is missing. Put each fact into the policy of the team that owns it, and review the policies like code.

## Common pitfalls

> [!WARNING]
> - **Expecting two authorities to both pass.** Authorities are alternatives, so an image that satisfies the weaker one is admitted.
> - **Putting an attestation under an authority with a different key.** The statement must verify with the authority it is listed under.
> - **Overlapping globs by accident.** An image that matches two policies must satisfy both.
> - **Generic entry names.** A refusal for `attestation-0` tells nobody what to fix.
