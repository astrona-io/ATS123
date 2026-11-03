#!/usr/bin/env bash
# PASS when: Confirms one policy per repository, each trusting exactly its own team key, and no policy covering both repositories.
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


# digest_of REPO TAG: prints the digest reference of a tag in any lab repository.
digest_of() {
  local d
  d="$(ws regctl image digest "$REGISTRY/$1:$2" 2>/dev/null)" || return 1
  [ -n "$d" ] || return 1
  printf '%s/%s@%s\n' "$REGISTRY" "$1" "$d"
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

ALL="$(kubectl get clusterimagepolicy -o json 2>/dev/null)" || { echo "FAIL: could not list ClusterImagePolicy resources."; exit 1; }
INV_IMG="registry.localtest.me:5001/inventory/podinfo:6.15.0"
TOOLS_IMG="registry.localtest.me:5001/tools/podinfo:6.15.0"
matches() { local g="${1//\*\*/*}"; case "$2" in $g) return 0 ;; esac; return 1; }
INV_KEY="$(ws cat /work/keys/cosign.pub | tr -d ' \n\r')"
TOOLS_KEY="$(ws cat /work/tools/cosign.pub | tr -d ' \n\r')"
FOUND_INV=""; FOUND_TOOLS=""
for NAME in $(printf '%s' "$ALL" | jq -r '.items[].metadata.name'); do
  CIP="$(printf '%s' "$ALL" | jq --arg n "$NAME" '.items[] | select(.metadata.name == $n)')"
  M_INV=""; M_TOOLS=""
  for G in $(printf '%s' "$CIP" | jq -r '.spec.images[].glob'); do
    matches "$G" "$INV_IMG" && M_INV=yes
    matches "$G" "$TOOLS_IMG" && M_TOOLS=yes
  done
  if [ -n "$M_INV" ] && [ -n "$M_TOOLS" ]; then echo "FAIL: the policy $NAME covers both the inventory and the tools repository."; exit 1; fi
  [ -n "$M_INV$M_TOOLS" ] || continue
  MODE="$(printf '%s' "$CIP" | jq -r '.spec.mode // "enforce"')"
  [ "$MODE" = "enforce" ] || { echo "FAIL: the policy $NAME is in mode $MODE; it must enforce."; exit 1; }
  printf '%s' "$CIP" | jq -e '[.spec.authorities[] | select(.key | not)] | length == 0' >/dev/null \
    || { echo "FAIL: the policy $NAME has an authority that is not a key authority."; exit 1; }
  COUNT="$(printf '%s' "$CIP" | jq '.spec.authorities | length')"
  [ "$COUNT" -eq 1 ] || { echo "FAIL: the policy $NAME has $COUNT authorities; it must trust exactly one key."; exit 1; }
  K="$(key_of "$CIP" 0)"
  if [ -n "$M_INV" ]; then
    [ "$K" = "$INV_KEY" ] || { echo "FAIL: the policy $NAME covers the inventory repository but does not trust exactly the lab key."; exit 1; }
    FOUND_INV=yes
  else
    [ "$K" = "$TOOLS_KEY" ] || { echo "FAIL: the policy $NAME covers the tools repository but does not trust exactly the tools key."; exit 1; }
    FOUND_TOOLS=yes
  fi
done
[ -n "$FOUND_INV" ] || { echo "FAIL: no policy covers the inventory repository."; exit 1; }
[ -n "$FOUND_TOOLS" ] || { echo "FAIL: no policy covers the tools repository."; exit 1; }
echo "PASS: each repository has its own policy with exactly its own team key."
