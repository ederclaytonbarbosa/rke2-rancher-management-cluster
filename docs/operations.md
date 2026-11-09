# Operations runbook

## Daily checks

```bash
kubectl get nodes
kubectl get pods -A
kubectl get --raw='/readyz?verbose'
kubectl -n cattle-system get deployment rancher
```

## RKE2 service logs

```bash
sudo journalctl -u rke2-server --since '30 minutes ago'
```

## etcd snapshots

The server configuration schedules an etcd snapshot every six hours and retains 20 local snapshots. Copy snapshots to protected external storage and periodically validate restoration in a non-production environment.

```bash
sudo rke2 etcd-snapshot ls
sudo rke2 etcd-snapshot save --name manual-before-change
```

## Upgrade approach

1. Review the Rancher support matrix and release notes.
2. Create and export a verified etcd snapshot.
3. Upgrade one RKE2 server at a time while preserving quorum.
4. Validate nodes and system workloads after every node.
5. Upgrade cert-manager and Rancher only through supported paths.
6. Record versions, validation evidence, and rollback decisions.

## Sensitive artifacts

Treat the following as secrets:

- `/etc/rancher/rke2/rke2.yaml`
- `/var/lib/rancher/rke2/server/node-token`
- `/etc/rancher/rke2/config.yaml`
- Rancher bootstrap and administrator credentials
- etcd snapshots

