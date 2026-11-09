# GitHub Actions Secrets

Secrets can be stored in **Repository settings → Secrets and variables → Actions** when a trusted workflow needs them. Recommended names are:

| Secret | Purpose |
|---|---|
| `RKE2_TOKEN` | Shared token used while joining RKE2 nodes |
| `RANCHER_BOOTSTRAP_PASSWORD` | One-time Rancher bootstrap password |
| `LETSENCRYPT_EMAIL` | Email used by the Let's Encrypt issuer |

Do not add secret values to YAML, shell scripts, workflow logs, pull requests, or screenshots.

## Important security boundaries

- A repository secret is available to workflows that you authorize; it is not a general-purpose vault for cluster operations.
- Use a protected GitHub Environment for production secrets and require manual approval.
- Pin third-party actions to reviewed commit SHAs when a workflow consumes secrets.
- Do not expose secrets to workflows triggered from untrusted forks.
- Use a dedicated self-hosted runner only if GitHub Actions must reach private infrastructure.
- Prefer short-lived credentials and rotate a token immediately if a workflow or log may have exposed it.
- Avoid storing a cluster-admin kubeconfig unless there is a strict operational need; use a narrowly scoped service account instead.

The portfolio workflows included in this repository do not request or consume any runtime secrets.
