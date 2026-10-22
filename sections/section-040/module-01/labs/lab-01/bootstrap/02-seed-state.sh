#!/usr/bin/env bash
# Creates the starting state for ats-123-lab-040-01:
# inventory-signed only checks the lab key; 6.15.0 has provenance from the trusted builder, 6.14.1 from a laptop, 6.14.0 none.
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
sign_with_key /work/keys/cosign.key "$(digest_ref 6.14.1)" >/dev/null
sign_with_key /work/keys/cosign.key "$(digest_ref 6.14.0)" >/dev/null
# SLSA v1 provenance predicates, one from the trusted builder and one not.
ws sh -c 'cat > /work/provenance-trusted.json' <<'EOF'
{"buildDefinition":{"buildType":"https://ci.inventory.example/build/v1","externalParameters":{"repository":"https://git.inventory.example/inventory/podinfo","ref":"refs/tags/6.15.0"}},"runDetails":{"builder":{"id":"https://ci.inventory.example/builder@v1"}}}
EOF
ws sh -c 'cat > /work/provenance-laptop.json' <<'EOF'
{"buildDefinition":{"buildType":"https://ci.inventory.example/build/v1","externalParameters":{"repository":"https://git.inventory.example/inventory/podinfo","ref":"refs/tags/6.14.1"}},"runDetails":{"builder":{"id":"https://laptop.inventory.example/manual-build"}}}
EOF
# Vulnerability predicates in cosign's vuln format (invocation, scanner, metadata);
# the scanner result holds the findings: none critical for 6.15.0, one for 6.14.1.
ws sh -c 'cat > /work/scan-6.15.0.json' <<'EOF'
{"invocation":{"parameters":null,"uri":"https://ci.inventory.example/scan","event_id":"1","builder.id":"https://ci.inventory.example/builder@v1"},"scanner":{"uri":"https://ci.inventory.example/scanner","version":"1.0.0","db":{"uri":"https://ci.inventory.example/db","version":"2026-10-22"},"result":{"Results":[{"Target":"podinfo","Vulnerabilities":[{"VulnerabilityID":"CVE-2026-1001","Severity":"LOW"}]}]}},"metadata":{"scanStartedOn":"2026-10-22T08:00:00Z","scanFinishedOn":"2026-10-22T08:01:00Z"}}
EOF
ws sh -c 'cat > /work/scan-6.14.1.json' <<'EOF'
{"invocation":{"parameters":null,"uri":"https://ci.inventory.example/scan","event_id":"1","builder.id":"https://ci.inventory.example/builder@v1"},"scanner":{"uri":"https://ci.inventory.example/scanner","version":"1.0.0","db":{"uri":"https://ci.inventory.example/db","version":"2026-10-22"},"result":{"Results":[{"Target":"podinfo","Vulnerabilities":[{"VulnerabilityID":"CVE-2026-1002","Severity":"CRITICAL"}]}]}},"metadata":{"scanStartedOn":"2026-10-22T08:00:00Z","scanFinishedOn":"2026-10-22T08:01:00Z"}}
EOF
kubectl apply -f - <<'EOF'
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: inventory-signed
spec:
  images:
    - glob: "registry.localtest.me:5001/inventory/**"
  authorities:
    - name: inventory-key
      key:
        secretRef:
          name: inventory-public-key
EOF
kubectl label namespace prod policy.sigstore.dev/include=true --overwrite
echo "[seed] Attaching provenance attestations..."
attest_with_key /work/keys/cosign.key slsaprovenance1 /work/provenance-trusted.json "$(digest_ref 6.15.0)" >/dev/null
attest_with_key /work/keys/cosign.key slsaprovenance1 /work/provenance-laptop.json "$(digest_ref 6.14.1)" >/dev/null

echo "[lab] Starting state ready."
