#!/usr/bin/env bash
set -euo pipefail

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

require_value() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable is missing: ${name}" >&2
    exit 1
  fi
}

require_command kubectl
require_command helm
require_value RANCHER_HOSTNAME
require_value RANCHER_BOOTSTRAP_PASSWORD
require_value LETSENCRYPT_EMAIL

RANCHER_VERSION="${RANCHER_VERSION:-2.15.3}"
CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.21.3}"
VALUES_FILE="${VALUES_FILE:-manifests/rancher-values.yaml}"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "Rancher values file not found: ${VALUES_FILE}" >&2
  exit 1
fi

runtime_values="$(mktemp)"
trap 'rm -f "${runtime_values}"' EXIT
chmod 0600 "${runtime_values}"
cat >"${runtime_values}" <<EOF
hostname: ${RANCHER_HOSTNAME}
bootstrapPassword: ${RANCHER_BOOTSTRAP_PASSWORD}
letsEncrypt:
  email: ${LETSENCRYPT_EMAIL}
EOF

helm repo add jetstack https://charts.jetstack.io --force-update
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable --force-update
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version "${CERT_MANAGER_VERSION}" \
  --set crds.enabled=true \
  --wait \
  --timeout 10m

helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --version "${RANCHER_VERSION}" \
  --values "${VALUES_FILE}" \
  --values "${runtime_values}" \
  --wait \
  --timeout 15m

kubectl -n cattle-system rollout status deployment/rancher --timeout=10m
kubectl -n cattle-system wait \
  --for=condition=Ready certificate/tls-rancher-ingress \
  --timeout=15m
echo "Rancher is available at https://${RANCHER_HOSTNAME}"
echo "Rotate the bootstrap password immediately after the first login."

