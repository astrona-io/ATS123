#!/usr/bin/env bash
# PASS when: Confirms prod admits podinfo:6.10.0 and refuses an image that no policy matches.
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

RESULT="$(admission prod ghcr.io/stefanprodan/podinfo:6.10.0)"
case "$RESULT" in
  ALLOWED*) ;;
  *) echo "FAIL: ghcr.io/stefanprodan/podinfo:6.10.0 in prod should be allowed, got: $RESULT"; exit 1 ;;
esac
case "$RESULT" in
  *[Ww]arning*) echo "FAIL: ghcr.io/stefanprodan/podinfo:6.10.0 in prod returned a warning, so a policy is in warn mode or matched nothing: $RESULT"; exit 1 ;;
esac
IMAGE_UNDER_TEST="$(digest_ref 6.15.0)"
case "$IMAGE_UNDER_TEST" in
  ""|*@) echo "FAIL: could not resolve the image for 6.15.0; is the registry up?"; exit 1 ;;
esac
RESULT="$(admission prod "$IMAGE_UNDER_TEST")"
case "$RESULT" in
  DENIED*) ;;
  *) echo "FAIL: an image no policy matches in prod should be denied, got: $RESULT"; exit 1 ;;
esac
echo "PASS: prod admits the release image and refuses images no policy matches."
