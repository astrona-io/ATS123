#!/usr/bin/env bash
# PASS when: Confirms inventory-signed trusts exactly the lab public key, in enforce mode, without a static authority.
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

CIP="$(kubectl get clusterimagepolicy inventory-signed -o json 2>/dev/null)" || { echo "FAIL: the ClusterImagePolicy inventory-signed does not exist."; exit 1; }
MODE="$(printf '%s' "$CIP" | jq -r '.spec.mode // "enforce"')"
[ "$MODE" = "enforce" ] || { echo "FAIL: inventory-signed is in mode $MODE; it must enforce."; exit 1; }
printf '%s' "$CIP" | jq -e '[.spec.authorities[] | select(.static)] | length == 0' >/dev/null \
  || { echo "FAIL: inventory-signed has a static authority."; exit 1; }
WANT="$(ws cat /work/keys/cosign.pub | tr -d ' \n\r')"
FOUND=""
for AUTHORITY in $(printf '%s' "$CIP" | jq -r '.spec.authorities | keys[]'); do
  DATA="$(printf '%s' "$CIP" | jq -r ".spec.authorities[$AUTHORITY].key.data // empty")"
  SECRET="$(printf '%s' "$CIP" | jq -r ".spec.authorities[$AUTHORITY].key.secretRef.name // empty")"
  if [ -n "$SECRET" ]; then
    DATA="$(kubectl -n cosign-system get secret "$SECRET" -o json 2>/dev/null | jq -r '.data | to_entries[0].value // empty' | base64 -d 2>/dev/null)"
  fi
  [ "$(printf '%s' "$DATA" | tr -d ' \n\r')" = "$WANT" ] && FOUND=yes
done
[ -n "$FOUND" ] || { echo "FAIL: no authority of inventory-signed holds the lab public key /work/keys/cosign.pub."; exit 1; }
echo "PASS: inventory-signed enforces signatures by the lab key."
