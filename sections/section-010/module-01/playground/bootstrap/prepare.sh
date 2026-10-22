#!/usr/bin/env bash
# OS prep for the "How Policy Controller Works" playground (`ats-123-playground-010-01`).
#
# Environment preparation only. There is no task and no grading. This script
# installs Helm (pinned), the lab registry with TLS, the workstation pod with
# the Sigstore tools, the lab signing key and Policy Controller, then creates
# the starting state: Policy Controller with the key policy inventory-signed; 6.15.0 signed with the lab key; prod not opted in yet.
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

HELM_VERSION="3.22.1"
PC_CHART_VERSION="0.10.8"
REGISTRY_HOST="registry.localtest.me"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac

# Pin Helm rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  WORK="$(mktemp -d)"
  echo "[setup] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
  rm -rf "$WORK"
fi
helm version --short

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One name for the registry everywhere in the cluster. The answer is rewritten
# back to the asked name: Go programs (cosign and the webhook included) ignore
# DNS answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$REGISTRY_HOST"; then
  echo "[setup] Adding the CoreDNS rewrite for ${REGISTRY_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex registry\\.localtest\\.me registry.registry.svc.cluster.local"
        print "        answer name registry\\.registry\\.svc\\.cluster\\.local registry.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent. The registry pod waits
# for its certificate Secret, created below.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n workstation rollout status deployment/workstation --timeout=600s
for _ in $(seq 1 60); do ws sh -c 'command -v openssl >/dev/null && command -v update-ca-certificates >/dev/null' 2>/dev/null && break; sleep 5; done

# A lab-only certificate authority and a server certificate for the registry.
if ! kubectl -n registry get secret registry-tls >/dev/null 2>&1; then
  echo "[setup] Creating the lab certificate authority and the registry certificate..."
  ws sh -c 'mkdir -p /work/pki && cd /work/pki &&
    openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/CN=Astrona lab CA" \
      -keyout ca.key -out ca.crt 2>/dev/null &&
    openssl req -newkey rsa:2048 -nodes -subj "/CN=registry.localtest.me" \
      -keyout tls.key -out tls.csr 2>/dev/null &&
    printf "subjectAltName=DNS:registry.localtest.me,DNS:registry.registry.svc.cluster.local\n" > san.ext &&
    openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 \
      -extfile san.ext -out tls.crt 2>/dev/null'
  PKI_DIR="$(mktemp -d)"
  ws cat /work/pki/ca.crt > "$PKI_DIR/ca.crt"
  ws cat /work/pki/tls.crt > "$PKI_DIR/tls.crt"
  ws cat /work/pki/tls.key > "$PKI_DIR/tls.key"
  kubectl -n registry create secret tls registry-tls --cert="$PKI_DIR/tls.crt" --key="$PKI_DIR/tls.key"
  for NAMESPACE in cosign-system workstation; do
    kubectl -n "$NAMESPACE" create configmap registry-ca --from-file=ca.crt="$PKI_DIR/ca.crt" \
      --dry-run=client -o yaml | kubectl apply -f -
  done
  rm -rf "$PKI_DIR"
fi
# The workstation trusts the lab CA now; after a restart its start script
# reads the same CA from the ConfigMap registry-ca.
ws sh -c '[ -s /usr/local/share/ca-certificates/lab-ca.crt ] || { cp /work/pki/ca.crt /usr/local/share/ca-certificates/lab-ca.crt && update-ca-certificates >/dev/null 2>&1; }'
kubectl -n registry rollout status deployment/registry --timeout=300s

# The lab-only signing key pair, kept in a Secret so a pod restart keeps it.
if ! kubectl -n workstation get secret inventory-signing-key >/dev/null 2>&1; then
  echo "[setup] Creating the lab-only cosign key pair..."
  ws sh -c "mkdir -p /work/keys && cd /work/keys && COSIGN_PASSWORD='$COSIGN_PASSWORD' cosign generate-key-pair >/dev/null"
  KEY_DIR="$(mktemp -d)"
  ws cat /work/keys/cosign.key > "$KEY_DIR/cosign.key"
  ws cat /work/keys/cosign.pub > "$KEY_DIR/cosign.pub"
  kubectl -n workstation create secret generic inventory-signing-key \
    --from-file=cosign.key="$KEY_DIR/cosign.key" --from-file=cosign.pub="$KEY_DIR/cosign.pub"
  kubectl -n workstation create configmap inventory-public-key --from-file=cosign.pub="$KEY_DIR/cosign.pub" \
    --dry-run=client -o yaml | kubectl apply -f -
  rm -rf "$KEY_DIR"
fi

echo "[setup] Copying the example images into the registry..."
for TAG in 6.15.0 6.14.1; do
  ws regctl image copy --platform linux/amd64 \
    "ghcr.io/stefanprodan/podinfo:$TAG" "$IMAGE_REPO:$TAG" >/dev/null
done

echo "[setup] Installing Policy Controller (chart ${PC_CHART_VERSION})..."
helm repo add sigstore https://sigstore.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update sigstore >/dev/null
helm upgrade --install policy-controller sigstore/policy-controller --version "$PC_CHART_VERSION" \
  --namespace cosign-system \
  --values "$MANIFEST_DIR/policy-controller-values.yaml" \
  --wait --timeout 10m
wait_for_policy_controller

# The starting state of this playground.
TMPDIR_SEED="$(mktemp -d)"
# The lab public key, as a Secret in the Policy Controller namespace.
ws cat /work/keys/cosign.pub > "$TMPDIR_SEED/cosign.pub"
kubectl -n cosign-system create secret generic inventory-public-key \
  --from-file=cosign.pub="$TMPDIR_SEED/cosign.pub" --dry-run=client -o yaml | kubectl apply -f -
echo "[seed] Signing 6.15.0 with the lab key..."
sign_with_key /work/keys/cosign.key "$(digest_ref 6.15.0)" >/dev/null
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
rm -rf "$TMPDIR_SEED"

echo "[playground] Ready."
kubectl -n cosign-system get pods
echo "[playground] Open a shell with the tools: kubectl -n workstation exec -it deploy/workstation -- sh"
