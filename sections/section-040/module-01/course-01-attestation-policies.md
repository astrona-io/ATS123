# Attestation Policies With CUE And Rego

A key policy proves that the release key signed an image. It cannot tell an image built by the build service from one built on a developer's laptop and signed with the same key. This part attaches a statement about how each image was built, and makes Policy Controller require that the statement names the trusted build service.

## Attestations, predicates and predicate types

An **attestation** is a signed statement about an artifact. Sigstore uses the in-toto statement format: a JSON document with a `subject` (the image digest it is about), a `predicateType` (a URL that names the kind of statement) and a `predicate` (the statement itself). Cosign signs the whole document with the same key or keyless identity as a signature.

Two predicate types matter in this course. **SLSA provenance**, predicate type `https://slsa.dev/provenance/v1`, describes how an image was built. SLSA (Supply-chain Levels for Software Artifacts) is a framework for build integrity; its provenance names the build service under `runDetails.builder.id` and the inputs under `buildDefinition`. A **vulnerability attestation**, predicate type `https://cosign.sigstore.dev/attestation/vuln/v1`, carries the result of a vulnerability scan.

## Attach provenance with cosign attest

The workstation pod holds two provenance predicates in `/work`: `provenance-trusted.json` names the builder `https://ci.inventory.example/builder@v1`, and `provenance-laptop.json` names `https://laptop.inventory.example/manual-build`. Open a shell in the pod and read the first one:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
jq . /work/provenance-trusted.json
```

The file is the predicate only: `buildDefinition` with the build type and the repository, and `runDetails.builder.id`. Cosign wraps it in the in-toto statement. Attach it to `6.15.0`, and the laptop predicate to `6.14.1`:

```sh
REPO=registry.localtest.me:5001/inventory/podinfo
for PAIR in 6.15.0:trusted 6.14.1:laptop; do
  TAG="${PAIR%%:*}"; FILE="/work/provenance-${PAIR##*:}.json"
  COSIGN_PASSWORD=lab-only-password cosign attest --key /work/keys/cosign.key \
    --type slsaprovenance1 --predicate "$FILE" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false --yes \
    "$REPO@$(regctl image digest "$REPO:$TAG")"
done
```

`--type slsaprovenance1` sets the predicate type to `https://slsa.dev/provenance/v1`. The last three flags are the same as for signing: the classic format, which Policy Controller reads for key authorities, and no upload to the public transparency log. Cosign stores each attestation under a tag made of `sha256-`, the digest and `.att`. Check one:

```sh
cosign verify-attestation --key /work/keys/cosign.pub --type slsaprovenance1 \
  --insecure-ignore-tlog=true --new-bundle-format=false "$REPO:6.15.0" | jq -r .payload | base64 -d | jq .predicate.runDetails
```

`cosign verify-attestation` checks the signature on the attestation and prints it as JSON with a base64 `payload`; the pipeline decodes the payload and shows the builder ID of the trusted build service. Leave the shell with `exit`.

## Require an attestation in a policy

An authority can carry an `attestations` list. Each entry has a `name`, the `predicateType` it requires, and an optional `policy` that checks the content. Without a `policy`, any attestation of that type signed by the authority is enough. With a `policy`, Policy Controller passes the verified in-toto statement to the policy, so the policy sees `predicateType` and `predicate` at the top level.

A **CUE** policy is a CUE value that the statement must unify with: every field the CUE value sets must be present in the statement with that exact value. Extend `inventory-signed` so the key authority also requires provenance from the trusted builder. Save this as `clusterimagepolicy-inventory-signed.yaml`:

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
      attestations:
        - name: trusted-builder
          predicateType: https://slsa.dev/provenance/v1
          policy:
            type: cue
            data: |
              predicateType: "https://slsa.dev/provenance/v1"
              predicate: runDetails: builder: id: "https://ci.inventory.example/builder@v1"
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

`6.15.0` is admitted. `6.14.1` is refused, although its signature and its attestation are both valid: the CUE policy finds a different builder ID, and the error names the attestation `trusted-builder`. An image with a valid signature and no provenance at all is refused too, because the authority requires an attestation of that type.

## The same check in Rego

**Rego** is the policy language of Open Policy Agent. A Rego policy for Policy Controller uses the package `sigstore` and must make the rule `isCompliant` true; the statement is the `input`. The provenance check above reads like this in Rego:

```yaml
policy:
  type: rego
  data: |
    package sigstore
    default isCompliant = false
    isCompliant {
      input.predicateType == "https://slsa.dev/provenance/v1"
      input.predicate.runDetails.builder.id == "https://ci.inventory.example/builder@v1"
    }
```

CUE is shorter for "these fields must have these values". Rego is better when the check needs logic, such as counting the critical findings in a vulnerability scan.

You now know how to require a statement about an image and check its content, in two policy languages. The open question is how to switch such a policy on in a cluster that is already running, without refusing images you did not mean to.

## Common pitfalls

> [!WARNING]
> - **A CUE field that does not exist in the statement.** CUE needs every field it sets to be present, so a typo in `runDetails` or `builder` refuses every image.
> - **A predicate type that differs from the one cosign wrote.** `--type slsaprovenance1` writes `https://slsa.dev/provenance/v1`; `--type slsaprovenance` writes the older v0.2 type, which this policy does not match.
> - **Putting `attestations` on a different authority than the key that signed them.** The attestation must verify with the authority it is listed under.
> - **Forgetting that a valid signature is not enough.** With an `attestations` list, an image without the attestation is refused.

## Your mission: Require SLSA Provenance On Inventory Images

You can now attach provenance to an image and require it in a policy. The graded lab gives you signed images with provenance from the trusted builder, from a laptop and none at all, and asks you to extend `inventory-signed` so only the first is admitted in `prod`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-040-01
astrona start ats-123-playground-040-01
```
