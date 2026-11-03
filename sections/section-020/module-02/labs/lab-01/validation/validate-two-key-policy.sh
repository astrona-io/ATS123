#!/usr/bin/env bash
# PASS when: Confirms inventory-signed enforces and trusts exactly the old and the new public key.
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


# key_of POLICY_JSON INDEX: prints the public key of key authority INDEX (inline or from its Secret).
key_of() {
  local data secret
  data="$(printf '%s' "$1" | jq -r ".spec.authorities[$2].key.data // empty")"
  secret="$(printf '%s' "$1" | jq -r ".spec.authorities[$2].key.secretRef.name // empty")"
  if [ -n "$secret" ]; then
    data="$(kubectl -n cosign-system get secret "$secret" -o json 2>/dev/null | jq -r '.data | to_entries[0].value // empty' | base64 -d 2>/dev/null)"
  fi
  printf '%s' "$data" | tr -d ' \n\r'
}

CIP="$(kubectl get clusterimagepolicy inventory-signed -o json 2>/dev/null)" || { echo "FAIL: the ClusterImagePolicy inventory-signed does not exist."; exit 1; }
MODE="$(printf '%s' "$CIP" | jq -r '.spec.mode // "enforce"')"
[ "$MODE" = "enforce" ] || { echo "FAIL: inventory-signed is in mode $MODE; it must enforce."; exit 1; }
printf '%s' "$CIP" | jq -e '[.spec.authorities[] | select(.key | not)] | length == 0' >/dev/null \
  || { echo "FAIL: inventory-signed has an authority that is not a key authority."; exit 1; }
OLD="$(ws cat /work/keys/cosign.pub | tr -d ' \n\r')"
NEW="$(ws cat /work/next/cosign.pub | tr -d ' \n\r')"
COUNT="$(printf '%s' "$CIP" | jq '.spec.authorities | length')"
HAS_OLD=""; HAS_NEW=""
for I in $(seq 0 $((COUNT - 1))); do
  K="$(key_of "$CIP" "$I")"
  if [ "$K" = "$OLD" ]; then HAS_OLD=yes
  elif [ "$K" = "$NEW" ]; then HAS_NEW=yes
  else echo "FAIL: authority $I of inventory-signed holds a key that is neither the old nor the new key."; exit 1
  fi
done
[ -n "$HAS_OLD" ] || { echo "FAIL: no authority holds the old public key."; exit 1; }
[ -n "$HAS_NEW" ] || { echo "FAIL: no authority holds the new public key."; exit 1; }
echo "PASS: inventory-signed enforces and trusts exactly the old and the new key."
