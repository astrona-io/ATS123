#!/usr/bin/env bash
# PASS when: Confirms the identity of podinfo-release accepts the release workflow on tags and rejects the sample subjects that must not match.
set -uo pipefail

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
REGISTRY="registry.localtest.me:5001"
IMAGE_REPO="$REGISTRY/inventory/podinfo"
COSIGN_PASSWORD="lab-only-password"

# Runs a command in the workstation pod, where the Sigstore tools live.
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# digest_ref TAG: prints the image reference by digest for a tag of the
# example repository, for example registry.localtest.me:5001/inventory/podinfo@sha256:...
digest_ref() {
  local digest
  digest="$(ws regctl image digest "$IMAGE_REPO:$1" 2>/dev/null)" || return 1
  [ -n "$digest" ] || return 1
  printf '%s@%s\n' "$IMAGE_REPO" "$digest"
}

# sign_with_key KEYFILE REFERENCE: signs in the classic (legacy) format and
# does not upload to the public transparency log, so key policies can check it.
sign_with_key() {
  ws env COSIGN_PASSWORD="$COSIGN_PASSWORD" cosign sign --key "$1" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false \
    --yes "$2"
}

# attest_with_key KEYFILE TYPE PREDICATE_FILE REFERENCE: adds a signed
# attestation in the classic format, without the public transparency log.
attest_with_key() {
  ws env COSIGN_PASSWORD="$COSIGN_PASSWORD" cosign attest --key "$1" \
    --type "$2" --predicate "$3" \
    --new-bundle-format=false --use-signing-config=false --tlog-upload=false \
    --yes "$4"
}

# admission NAMESPACE IMAGE: asks the API server to admit a pod with a
# server-side dry run (the webhooks run, nothing is stored, no image is
# pulled). Prints ALLOWED or DENIED followed by everything kubectl printed.
admission() {
  local output status
  output="$(kubectl -n "$1" run "admission-check-$$-$RANDOM" --image="$2" \
    --restart=Never --dry-run=server -o name 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf 'ALLOWED %s\n' "$output"
  else
    printf 'DENIED %s\n' "$output"
  fi
}

# pc_setting KEY: prints one value of the ConfigMap config-policy-controller.
pc_setting() {
  kubectl -n cosign-system get configmap config-policy-controller \
    -o go-template="{{ index .data \"$1\" }}" 2>/dev/null
}

# wait_for_policy_controller: waits until the webhook Deployment is available.
wait_for_policy_controller() {
  kubectl -n cosign-system rollout status deployment/policy-controller-webhook --timeout=300s >/dev/null
}

CIP="$(kubectl get clusterimagepolicy podinfo-release -o json 2>/dev/null)" || { echo "FAIL: the ClusterImagePolicy podinfo-release does not exist."; exit 1; }
MODE="$(printf '%s' "$CIP" | jq -r '.spec.mode // "enforce"')"
[ "$MODE" = "enforce" ] || { echo "FAIL: podinfo-release is in mode $MODE; it must enforce."; exit 1; }
printf '%s' "$CIP" | jq -e '[.spec.authorities[] | select(.static)] | length == 0' >/dev/null \
  || { echo "FAIL: podinfo-release has a static authority."; exit 1; }
printf '%s' "$CIP" | jq -e '[.spec.authorities[] | select(.keyless)] | length > 0' >/dev/null \
  || { echo "FAIL: podinfo-release has no keyless authority."; exit 1; }
ISSUER="https://token.actions.githubusercontent.com"
printf '%s' "$CIP" | jq -e --arg i "$ISSUER" '[.spec.authorities[] | select(.keyless) | .keyless.identities[]? | select((.issuer // "") != $i)] | length == 0' >/dev/null \
  || { echo "FAIL: an identity of podinfo-release does not use the exact issuer $ISSUER."; exit 1; }
# accepts SUBJECT: succeeds when any identity of any keyless authority accepts it.
accepts() {
  local line kind value
  while IFS=$'\t' read -r kind value; do
    case "$kind" in
      exact) [ "$value" = "$1" ] && return 0 ;;
      regexp) printf '%s\n' "$1" | grep -Eq -- "$value" && return 0 ;;
      any) return 0 ;;
    esac
  done < <(printf '%s' "$CIP" | jq -r '.spec.authorities[] | select(.keyless) | .keyless.identities[]? |
    if .subject then "exact\t" + .subject elif .subjectRegExp then "regexp\t" + .subjectRegExp else "any\t" end')
  return 1
}
BASE="https://github.com/stefanprodan"
for S in "$BASE/podinfo/.github/workflows/release.yml@refs/tags/6.10.0" "$BASE/podinfo/.github/workflows/release.yml@refs/tags/6.9.0"; do
  accepts "$S" || { echo "FAIL: the identity rejects the release subject $S."; exit 1; }
done
for S in \
  "$BASE/podinfo/.github/workflows/test.yml@refs/heads/pr-12" \
  "$BASE/podinfo/.github/workflows/release.yml@refs/heads/main" \
  "$BASE/other-project/.github/workflows/release.yml@refs/tags/1.0.0" \
  "$BASE/podinfo-fork/.github/workflows/release.yml@refs/tags/1.0.0" \
  "https://github.com/attacker/podinfo/.github/workflows/release.yml@refs/tags/6.10.0"
do
  accepts "$S" && { echo "FAIL: the identity still accepts $S, which must not be trusted."; exit 1; }
done
echo "PASS: the identity accepts only the release workflow of stefanprodan/podinfo on tags."
