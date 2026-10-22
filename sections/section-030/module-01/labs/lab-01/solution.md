# Solution: Require Images Signed By The podinfo Release Workflow

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the policy `podinfo-release` has the right shape, the two dry runs in `prod` give the expected answers, and the webhook's safe settings are unchanged.

## Step 1: Read the identity

Verify the image in the workstation pod with the identity you expect from the workflow file and the tag:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws cosign verify ghcr.io/stefanprodan/podinfo:6.15.0 \
  --certificate-identity https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.15.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

The verification passes, which confirms the issuer and the exact subject. The next release runs on another tag, so the policy must allow any tag after `refs/tags/`.

## Step 2: Write the policy

Save this as `clusterimagepolicy-podinfo-release.yaml`:

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

`signatureFormat: bundle` is needed because the release workflow signed with cosign v3, which writes the Sigstore bundle format.

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n prod run check --image=ghcr.io/fluxcd/source-controller:v1.9.6 --dry-run=server
```

The podinfo image is admitted with no warning. The Flux image is refused by `podinfo-release`: its signature is valid, but its subject belongs to another repository. The first check of each image can take a few seconds while the webhook fetches the trust root and the signature.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `subjectRegExp: .*` | Any keyless signature from GitHub passes, so the Flux image is admitted |
| Glob `ghcr.io/stefanprodan/**` | The Flux image matches no policy and falls to the no-match policy instead of being checked |
| The exact subject with `@refs/tags/6.15.0` | It works today and refuses the next release |
| No `signatureFormat: bundle` | The webhook looks for a classic signature and refuses the podinfo image too |

## Practice on your own

- Change the expression to `^https://github\.com/stefanprodan/.*$` and think about which other workflows of that user it would now trust.
- Add a second identity for a workflow on the `main` branch, and test it with `cosign verify --certificate-identity-regexp`.
