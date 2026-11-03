# Narrowing A Keyless Identity

A first keyless policy often uses a wide pattern so that it works at once. The pattern then admits more signers than anyone intended. This part starts from a loose pattern, shows what it accepts in a test that needs no cluster, and replaces it with a pattern for one release workflow.

## A policy that is too wide

The release workflow of `stefanprodan/podinfo` signs the image `ghcr.io/stefanprodan/podinfo:6.10.0`. A policy author who wants to start quickly trusts every workflow of the user:

<!-- astrona:playground:renew -->

Save this as `clusterimagepolicy-podinfo-loose.yaml`:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: podinfo-loose
spec:
  images:
    - glob: "ghcr.io/stefanprodan/**"
  authorities:
    - name: any-stefanprodan-workflow
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/.*$
```

Apply it:

```sh
kubectl apply -f clusterimagepolicy-podinfo-loose.yaml
```

Then check the result:

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
```

The image is admitted. The policy works for the release it was written for. It also accepts a signature made by any workflow, on any branch, of any repository owned by that user.

## Test what a pattern accepts

You can see this without any cluster. Put sample subjects through the pattern with `grep -E`:

```sh
PATTERN='^https://github\.com/stefanprodan/.*$'
for SUBJECT in \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.10.0 \
  https://github.com/stefanprodan/podinfo/.github/workflows/test.yml@refs/heads/pr-12 \
  https://github.com/stefanprodan/other-project/.github/workflows/build.yml@refs/heads/main
do
  if printf '%s\n' "$SUBJECT" | grep -Eq "$PATTERN"; then echo "match     $SUBJECT"; else echo "no match  $SUBJECT"; fi
done
```

All three subjects match. The second is a test workflow on a pull request branch and the third is another project. Both would now count as trusted release signers.

## Narrow the pattern

Name the repository, the workflow file and the kind of reference. Replace the policy with a pattern that matches only the release workflow on tags. Edit the YAML to this and apply it again:

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: podinfo-loose
spec:
  images:
    - glob: "ghcr.io/stefanprodan/**"
  authorities:
    - name: podinfo-release-workflow
      keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: ^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$
```

Run the same test with the new pattern:

```sh
PATTERN='^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$'
for SUBJECT in \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.10.0 \
  https://github.com/stefanprodan/podinfo/.github/workflows/test.yml@refs/heads/pr-12 \
  https://github.com/stefanprodan/other-project/.github/workflows/build.yml@refs/heads/main
do
  if printf '%s\n' "$SUBJECT" | grep -Eq "$PATTERN"; then echo "match     $SUBJECT"; else echo "no match  $SUBJECT"; fi
done
```

Only the first subject matches now. Apply the policy and check that the release image is still admitted:

```sh
kubectl -n prod run check --image=ghcr.io/stefanprodan/podinfo:6.10.0 --dry-run=server
```

You now have a rule that trusts one workflow on release tags, and a test that shows what any rule accepts. The mission asks you to do the same to a policy you did not write.

## Common pitfalls

> [!WARNING]
> - **Narrowing the glob and keeping a wide identity.** The glob limits which images are judged; the identity decides who may sign them.
> - **Testing only the subject that must match.** Always include subjects that must not match.
> - **Anchoring only one end.** Without `$`, extra text at the end is accepted.
> - **Using the pull request branch as a release signal.** Match `refs/tags/` and protect the tags.

## Your mission: Narrow A Keyless Identity Pattern

You can now see what a pattern accepts and replace a loose one. The graded lab starts with a policy whose pattern trusts every workflow of one owner. The task is to narrow it to the release workflow on release tags, and the grader tests your pattern against a list of subjects.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-123-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS123.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-123-lab-030-02
astrona start ats-123-playground-030-02
```
