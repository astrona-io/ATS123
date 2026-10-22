#!/usr/bin/env bash
# PASS when: Confirms the webhook still fails closed and images that match no policy are denied.
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

POLICIES="$(kubectl get validatingwebhookconfiguration policy.sigstore.dev -o jsonpath='{.webhooks[*].failurePolicy}' 2>/dev/null)"
[ -n "$POLICIES" ] || { echo "FAIL: the ValidatingWebhookConfiguration policy.sigstore.dev is missing."; exit 1; }
for POLICY in $POLICIES; do
  [ "$POLICY" = "Fail" ] || { echo "FAIL: the webhook failure policy is $POLICY; it must be Fail."; exit 1; }
done
NO_MATCH="$(pc_setting no-match-policy)"
case "$NO_MATCH" in
  ""|deny) ;;
  *) echo "FAIL: no-match-policy is '$NO_MATCH'; images that match no policy must be denied."; exit 1 ;;
esac
READY="$(kubectl -n cosign-system get deployment policy-controller-webhook -o jsonpath='{.status.availableReplicas}')"
[ "${READY:-0}" -ge 1 ] 2>/dev/null || { echo "FAIL: the policy-controller-webhook Deployment has no available replica."; exit 1; }
echo "PASS: the webhook fails closed, is running, and denies images no policy matches."
