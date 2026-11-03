# Identity Providers And Subjects

A keyless policy compares two strings, the issuer and the subject. The strings come from the identity provider that issued the token, and each provider writes its subject in its own shape. This part lists the shapes you will meet, shows how to test an expression against them offline, and gives rules for writing a subject expression that is narrow enough.

## Issuer and subject for common providers

The issuer is a URL that identifies the provider, and it is the same for every user of that provider. For GitHub Actions, it is `https://token.actions.githubusercontent.com`, and the subject is the workflow URL: the repository, the workflow file path and the Git reference, joined as `https://github.com/<owner>/<repository>/.github/workflows/<file>@<ref>`.

For a person who signs in by hand, the subject is the email address and the issuer is the provider of the account. A Google account uses `https://accounts.google.com`, and a Microsoft account uses `https://login.microsoftonline.com`. A GitHub account used for interactive signing uses `https://github.com/login/oauth`. A service account of a cloud provider also has an email-shaped subject and the issuer of that cloud, for example `https://accounts.google.com` for a Google service account.

GitLab CI signs with the issuer `https://gitlab.com` (or the address of a self-managed instance), and Fulcio writes the subject as the address of the CI configuration file at the reference, for example `https://gitlab.com/<group>/<project>//.gitlab-ci.yml@refs/heads/main`. Always verify a real signature from your pipeline once, and copy the issuer and the subject from the output, instead of building them from this description.

## Exact subject or expression

A keyless identity in a policy has four fields. `issuer` and `subject` are exact strings. `issuerRegExp` and `subjectRegExp` are regular expressions in the Go (RE2) syntax. Use the exact form when only one value is legitimate, and the expression form when the value changes in a controlled way, such as the release tag.

An expression that is not anchored matches anywhere inside the string. `github.com/acme/app` matches `https://github.com/acme/app-evil/...` too. Anchor with `^` at the start and `$` at the end, and escape every dot that you mean literally.

## Test an expression before you apply it

You can test an expression against sample subjects with `grep -E`, which uses a syntax close enough to RE2 for patterns of this kind. Put the candidate in a variable and run it against a subject that must match and subjects that must not:

<!-- astrona:playground:renew -->

```sh
PATTERN='^https://github\.com/stefanprodan/podinfo/\.github/workflows/release\.yml@refs/tags/.*$'
for SUBJECT in \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.10.0 \
  https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/heads/master \
  https://github.com/stefanprodan/podinfo-fork/.github/workflows/release.yml@refs/tags/6.10.0 \
  https://github.com/stefanprodan/podinfo/.github/workflows/test.yml@refs/tags/6.10.0
do
  if printf '%s\n' "$SUBJECT" | grep -Eq "$PATTERN"; then echo "match     $SUBJECT"; else echo "no match  $SUBJECT"; fi
done
```

Only the first subject matches. The branch run, the other repository and the other workflow do not. This check costs nothing and does not touch the cluster, so run it each time you change an expression. The real check stays `cosign verify --certificate-identity-regexp ... --certificate-oidc-issuer ...` on a real image.

## Rules for a narrow expression

Keep the issuer exact, because there is rarely a reason to trust two providers for one policy. Write the owner and the repository in full. Name the workflow file, because other workflows in the same repository, for example test jobs on pull requests, can also get a certificate. Choose the reference on purpose: `refs/tags/.*` accepts any tag, and `refs/heads/main` accepts only that branch. If many people can push tags to the repository, protect the tags in the repository settings, because the policy trusts whatever the workflow built from that tag.

You can now read the identity strings of the common providers and test a pattern before it reaches the cluster. The remaining question is where the trust for those strings comes from: the Fulcio root and the logs that a trust root describes.

## Common pitfalls

> [!WARNING]
> - **A regular expression with an unescaped dot.** `release.yml` also matches `releaseXyml`.
> - **Using `\d` or lookahead.** Go regular expressions do not support lookahead, and `grep -E` does not know `\d`; test with `[0-9]`.
> - **Trusting the whole organisation.** `^https://github\.com/acme/.*` includes every workflow of every repository in it.
> - **Building the subject from memory.** Copy it from a real `cosign verify` output.
