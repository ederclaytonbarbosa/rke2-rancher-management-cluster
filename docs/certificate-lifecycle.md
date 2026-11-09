# Automatic certificate lifecycle

Rancher is exposed as `rancher.titechsolucoes.com.br` and uses a Let's Encrypt certificate managed by cert-manager.

## Renewal policy

The Rancher ingress carries these annotations:

```yaml
cert-manager.io/renew-before-percentage: "33"
cert-manager.io/private-key-rotation-policy: Always
cert-manager.io/revision-history-limit: "3"
```

This makes cert-manager request renewal when approximately one third of the issued certificate lifetime remains. It is intentionally percentage-based instead of hard-coding 70 days:

- a 90-day certificate renews at approximately day 60;
- a 64-day certificate renews at approximately day 43;
- a 45-day certificate renews at approximately day 30.

Let's Encrypt is shortening default certificate lifetimes, so a fixed 70-day schedule would eventually allow a certificate to expire before renewal. Percentage-based renewal follows the actual lifetime returned by the issuer.

## Automatic application

cert-manager writes the renewed key and certificate into the Kubernetes TLS Secret referenced by the Rancher ingress. The ingress controller watches this Secret and serves the updated certificate automatically. The old certificate remains available until the new issuance succeeds, avoiding a planned expiration window.

## Validation

```bash
bash ./scripts/verify-certificate.sh
```

The script checks the `Ready` condition, renewal time, expiration time, revision, and referenced TLS Secret.

Recommended monitoring:

- alert when a Certificate is not `Ready`;
- alert on ACME challenge or order failures;
- alert when fewer than 14 days remain;
- externally probe `https://rancher.titechsolucoes.com.br` and inspect the served certificate;
- periodically test the Let's Encrypt staging environment before major changes.

## DNS and HTTP-01 requirements

Public DNS must resolve `rancher.titechsolucoes.com.br` to the public ingress/load-balancer address. Ports 80 and 443 must reach the Rancher ingress. The Kubernetes API and RKE2 registration ports must remain restricted to trusted networks.

