# Network requirements

## External load balancer

The load balancer must preserve TCP connections and expose:

| Port | Protocol | Purpose | Backend |
|---|---|---|---|
| 9345 | TCP | RKE2 supervisor and node registration | All server nodes |
| 6443 | TCP | Kubernetes API | All server nodes |
| 80 | TCP | Rancher HTTP redirect and ACME HTTP-01 when used | All server nodes |
| 443 | TCP | Rancher HTTPS ingress | All server nodes |

## Node-to-node traffic

Allow the ports required by the selected RKE2 CNI and embedded etcd. At minimum, plan for Kubernetes API, RKE2 supervisor, kubelet, embedded etcd peer/client traffic, and Canal networking between cluster nodes. Restrict access by source network instead of exposing management ports publicly.

## DNS

- `rke2-mgmt-api.titechsolucoes.com.br` resolves internally to the load-balancer address used for RKE2 registration and Kubernetes API access.
- `rancher.titechsolucoes.com.br` resolves publicly to the address serving ports 80 and 443.
- Every node has forward and reverse resolution or consistent `/etc/hosts` entries.

For the configured Let's Encrypt HTTP-01 flow, public validation traffic must reach the Rancher ingress on port 80. Do not publish the Kubernetes API or RKE2 supervisor ports to the internet merely to satisfy certificate issuance.

## Host preparation checklist

- Unique hostname on every node
- Static or reserved node addresses
- NTP or chrony synchronized
- Required kernel modules and sysctls available
- Swap disabled unless explicitly supported and configured
- firewalld rules reviewed for the chosen CNI
- SELinux configuration aligned with the supported RKE2 installation path

Always confirm the exact port matrix and supported operating systems in the RKE2 and Rancher documentation for the versions being deployed.

