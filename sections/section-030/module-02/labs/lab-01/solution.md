# Solution: Narrow A Keyless Identity Pattern

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the identity of `podinfo-release` against a list of sample subjects, the dry runs in `prod`, and the webhook's safe settings.

## Step 1: Read the policy and test it

```sh
kubectl get clusterimagepolicy podinfo-release -o yaml
PATTERN='^https://github\.com/stefanprodan/.*$'
for SUBJECT in \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.10.0 \
  https://github.com/stefanprodan/podinfo/.github/workflows/test.yml@refs/heads/pr-12 \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/heads/main \
  https://github.com/stefanprodan/other-project/.github/workflows/build.yml@refs/heads/main
do
  if printf '%s\n' "$SUBJECT" | grep -Eq "$PATTERN"; then echo "match     $SUBJECT"; else echo "no match  $SUBJECT"; fi
done
```

All four subjects match, so a test workflow or another project could sign an image that this policy admits.

## Step 2: Narrow the pattern

Save this as `clusterimagepolicy-podinfo-release.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: podinfo-release
spec:
  images:
    - glob: "ghcr.io/stefanprodan/podinfo**"
  authorities:
    - name: podinfo-release-workflow
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-podinfo-release.yaml
```

Run the loop of step 1 with the new pattern: only the first subject matches.

## Step 3: Prove the result

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
```

The image is admitted with no warning, because its certificate subject matches the narrow pattern.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```
