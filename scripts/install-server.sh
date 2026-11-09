#!/usr/bin/env bash
set -euo pipefail

require_value() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable is missing: ${name}" >&2
    exit 1
  fi
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root or with sudo." >&2
  exit 1
fi

require_value RKE2_TOKEN
require_value NODE_NAME
require_value NODE_IP
require_value TLS_SANS

RKE2_CHANNEL="${RKE2_CHANNEL:-stable}"
CLUSTER_INIT="${CLUSTER_INIT:-false}"

install_args=(sh -s - --channel "${RKE2_CHANNEL}")
if [[ -n "${RKE2_VERSION:-}" ]]; then
  export INSTALL_RKE2_VERSION="${RKE2_VERSION}"
fi

curl --proto '=https' --tlsv1.2 -sfL https://get.rke2.io | "${install_args[@]}"

install -d -m 0700 /etc/rancher/rke2
umask 077

{
  printf 'token: %s\n' "${RKE2_TOKEN}"
  printf 'node-name: %s\n' "${NODE_NAME}"
  printf 'node-ip: %s\n' "${NODE_IP}"
  printf 'advertise-address: %s\n' "${NODE_IP}"
  printf 'write-kubeconfig-mode: "0600"\n'
  printf 'cni: canal\n'
  printf 'etcd-snapshot-schedule-cron: "0 */6 * * *"\n'
  printf 'etcd-snapshot-retention: 20\n'
  printf 'tls-san:\n'
  IFS=',' read -ra sans <<<"${TLS_SANS}"
  for san in "${sans[@]}"; do
    printf '  - %s\n' "${san}"
  done
  if [[ "${CLUSTER_INIT}" != "true" ]]; then
    require_value RKE2_SERVER
    printf 'server: %s\n' "${RKE2_SERVER}"
  fi
} > /etc/rancher/rke2/config.yaml

chmod 0600 /etc/rancher/rke2/config.yaml
systemctl enable --now rke2-server

echo "RKE2 server installation started for ${NODE_NAME}."
echo "Follow progress with: journalctl -u rke2-server -f"

