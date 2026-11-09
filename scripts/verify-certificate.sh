#!/usr/bin/env bash
set -euo pipefail

command -v kubectl >/dev/null 2>&1 || {
  echo "kubectl is required." >&2
  exit 1
}

namespace="${RANCHER_NAMESPACE:-cattle-system}"
certificate="${RANCHER_CERTIFICATE:-tls-rancher-ingress}"

kubectl -n "${namespace}" wait \
  --for=condition=Ready "certificate/${certificate}" \
  --timeout=5m

kubectl -n "${namespace}" get "certificate/${certificate}" -o wide
kubectl -n "${namespace}" get "certificate/${certificate}" \
  -o jsonpath='Renewal time: {.status.renewalTime}{"\n"}Not after: {.status.notAfter}{"\n"}Revision: {.status.revision}{"\n"}'

secret_name="$(kubectl -n "${namespace}" get "certificate/${certificate}" -o jsonpath='{.spec.secretName}')"
if [[ -z "${secret_name}" ]]; then
  echo "Certificate does not reference a TLS Secret." >&2
  exit 1
fi

kubectl -n "${namespace}" get secret "${secret_name}" >/dev/null
echo "Automatic certificate renewal is configured and the TLS Secret exists: ${secret_name}"

