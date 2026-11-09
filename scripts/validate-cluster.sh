#!/usr/bin/env bash
set -euo pipefail

command -v kubectl >/dev/null 2>&1 || {
  echo "kubectl is required." >&2
  exit 1
}

kubectl get --raw='/readyz?verbose'
kubectl wait --for=condition=Ready nodes --all --timeout=10m
kubectl get nodes \
  -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLES:.metadata.labels.node-role\.kubernetes\.io/control-plane,ETCD:.metadata.labels.node-role\.kubernetes\.io/etcd,VERSION:.status.nodeInfo.kubeletVersion'
kubectl -n kube-system get pods -o wide

server_count="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o name | wc -l | tr -d ' ')"
if [[ "${server_count}" -ne 3 ]]; then
  echo "Expected 3 control-plane nodes, found ${server_count}." >&2
  exit 1
fi

echo "Management cluster validation completed successfully."

