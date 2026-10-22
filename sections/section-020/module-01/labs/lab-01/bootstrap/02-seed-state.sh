#!/usr/bin/env bash
# Creates the starting state for ats-123-lab-020-01:
# prod opts in, no policy exists, 6.15.0 is signed with the lab key, 6.14.1 with another key, 6.14.0 is unsigned; the Secret inventory-public-key holds the lab public key.
#
# The fix is NOT applied here — producing it is the task.
set -euo pipefail

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

TMPDIR_SEED="$(mktemp -d)"
# The lab public key, as a Secret in the Policy Controller namespace.
ws cat /work/keys/cosign.pub > "$TMPDIR_SEED/cosign.pub"
kubectl -n cosign-system create secret generic inventory-public-key \
  --from-file=cosign.pub="$TMPDIR_SEED/cosign.pub" --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$TMPDIR_SEED"
ws regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.0 "$IMAGE_REPO:6.14.0" >/dev/null
echo "[seed] Signing 6.15.0 with the lab key..."
sign_with_key /work/keys/cosign.key "$(digest_ref 6.15.0)" >/dev/null
echo "[seed] Signing 6.14.1 with a second key that no policy trusts..."
ws sh -c "[ -s /work/other/cosign.key ] || { mkdir -p /work/other && cd /work/other && COSIGN_PASSWORD='$COSIGN_PASSWORD' cosign generate-key-pair >/dev/null; }"
sign_with_key /work/other/cosign.key "$(digest_ref 6.14.1)" >/dev/null
kubectl label namespace prod policy.sigstore.dev/include=true --overwrite

echo "[lab] Starting state ready."
