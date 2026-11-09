# RKE2 Rancher Management Cluster

Production-oriented reference implementation for a highly available Rancher management cluster built on RKE2.

## Architecture

```text
Administrators
      |
      v
rancher.titechsolucoes.com.br:443
      |
      v
External L4 load balancer / VIP: 192.0.2.10
      |-- TCP 9345 -> management server nodes (RKE2 registration)
      |-- TCP 6443 -> management server nodes (Kubernetes API)
      |-- TCP 80/443 -> management server nodes (Rancher ingress)
      |
      +-- mgmt-cp-01 192.0.2.11 (etcd + control plane + worker)
      +-- mgmt-cp-02 192.0.2.12 (etcd + control plane + worker)
      +-- mgmt-cp-03 192.0.2.13 (etcd + control plane + worker)
```

The three RKE2 server nodes form the etcd quorum and also run Rancher. A separate, stable endpoint is required in front of them. The IP addresses are reserved documentation values; the `titechsolucoes.com.br` hostnames are deployment parameters owned by the project author.

## What this project demonstrates

- Three-node RKE2 control-plane and embedded-etcd topology
- Fixed registration endpoint for resilient node joins
- Automated RKE2 server installation with runtime-only secrets
- Highly available Rancher deployment with three replicas
- cert-manager installation and TLS-ready Rancher ingress
- Health, readiness, and node-role validation
- etcd snapshot configuration and operational runbooks
- Example HAProxy configuration for an external load balancer
- Security-focused defaults with no committed credentials

## Prerequisites

- Three Linux nodes with unique hostnames and synchronized time
- A supported operating system and Kubernetes version for the selected Rancher release
- An external TCP load balancer or virtual IP
- DNS records for the RKE2 API and Rancher hostname
- Passwordless or interactive sudo access on every node
- `curl`, `systemd`, and standard Linux utilities
- `kubectl` and Helm 3 on the administration host before installing Rancher

See [docs/network-requirements.md](docs/network-requirements.md) before installation.

## Repository structure

```text
.
├── config/
│   └── haproxy.cfg.example
├── docs/
│   ├── network-requirements.md
│   ├── certificate-lifecycle.md
│   └── operations.md
├── inventory/
│   └── management-cluster.example.yaml
├── manifests/
│   └── rancher-values.yaml
└── scripts/
    ├── install-rancher.sh
    ├── install-server.sh
    ├── verify-certificate.sh
    └── validate-cluster.sh
```

## Deployment workflow

### 1. Prepare the load balancer and DNS

Adapt `config/haproxy.cfg.example` on an external load-balancer host. Create DNS records such as:

```text
rke2-mgmt-api.titechsolucoes.com.br -> 192.0.2.10
rancher.titechsolucoes.com.br -> your public ingress/load-balancer address
```

### 2. Generate the cluster token securely

Run this on a trusted administration host. Do not commit the result.

```bash
export RKE2_TOKEN="$(openssl rand -hex 32)"
```

### 3. Bootstrap the first server

On `mgmt-cp-01`:

```bash
sudo --preserve-env=RKE2_TOKEN \
  NODE_NAME=mgmt-cp-01 \
  NODE_IP=192.0.2.11 \
  TLS_SANS=rke2-mgmt-api.titechsolucoes.com.br,192.0.2.10 \
  CLUSTER_INIT=true \
  bash ./scripts/install-server.sh
```

### 4. Join the remaining servers

On `mgmt-cp-02` and `mgmt-cp-03`, adjust `NODE_NAME` and `NODE_IP`:

```bash
sudo --preserve-env=RKE2_TOKEN \
  NODE_NAME=mgmt-cp-02 \
  NODE_IP=192.0.2.12 \
  RKE2_SERVER=https://rke2-mgmt-api.titechsolucoes.com.br:9345 \
  TLS_SANS=rke2-mgmt-api.titechsolucoes.com.br,192.0.2.10 \
  bash ./scripts/install-server.sh
```

### 5. Configure cluster access

Copy `/etc/rancher/rke2/rke2.yaml` from the first server to the administration host and replace `127.0.0.1` with `rke2-mgmt-api.titechsolucoes.com.br`.

```bash
export KUBECONFIG="$PWD/rke2-management.yaml"
bash ./scripts/validate-cluster.sh
```

### 6. Install Rancher

```bash
export RANCHER_HOSTNAME=rancher.titechsolucoes.com.br
export LETSENCRYPT_EMAIL='replace-with-your-email@titechsolucoes.com.br'
export RANCHER_BOOTSTRAP_PASSWORD='replace-at-runtime'
bash ./scripts/install-rancher.sh
unset RANCHER_BOOTSTRAP_PASSWORD
```

The bootstrap password must be changed immediately after the first login. Let's Encrypt HTTP-01 validation requires public DNS to resolve correctly and inbound HTTP/HTTPS access to reach the Rancher ingress. Certificate renewal and private-key rotation are automated using a percentage of the issued lifetime; see [docs/certificate-lifecycle.md](docs/certificate-lifecycle.md).

## Version strategy

RKE2 defaults to the `stable` channel. Pin `RKE2_VERSION` when change control requires an immutable version. Rancher and cert-manager defaults are declared at the top of `scripts/install-rancher.sh` and can be overridden through environment variables after compatibility review.

## Security notes

- Never commit RKE2 tokens, kubeconfig files, private keys, or bootstrap passwords.
- GitHub Actions Secrets may store runtime values, but workflows can read them. Use protected environments, least privilege, trusted actions, and a self-hosted runner only when automation must reach private cluster nodes.
- Restrict ports `9345`, `6443`, and `2379-2381` to trusted networks.
- Replace documentation TLS with a trusted internal CA or ACME issuer for production.
- Store etcd snapshots outside the cluster and test restoration procedures.
- Review Rancher and RKE2 support matrices before upgrades.

## References

- [RKE2 high availability](https://docs.rke2.io/install/ha)
- [RKE2 configuration](https://docs.rke2.io/install/configuration)
- [Rancher HA installation on RKE2](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/kubernetes-cluster-setup/rke2-for-rancher)
- [Rancher Helm installation](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster)

