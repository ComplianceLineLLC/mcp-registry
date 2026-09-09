# SonarQube MCP Server — Azure Deployment Guide

## Architecture

The SonarQube MCP Server is deployed as a centrally managed Docker container in **Azure Container Apps** with **internal-only ingress**. This means:

- No public internet endpoint — the server is unreachable from outside the Azure VNet
- Developers connect via corporate VPN to the VNet-private URL
- All developers connect to the same hosted instance — no Docker required locally
- The server is **stateless**: each request carries the developer's own SonarQube USER token via `Authorization: Bearer <token>`

```
[Developer + VPN] → [Azure VNet] → [Container App (internal ingress)] → [SonarQube Server (public, self-hosted)]
```

## Prerequisites

- Azure subscription with permission to create Container Apps
- An existing Azure Virtual Network (VNet), or permission to create one
- VPN Gateway or ExpressRoute providing developer access to the VNet
- SonarQube Server URL (public, self-hosted — e.g. `https://sqdev.mycompliancemanagement.com`; only the Container App/MCP wrapper is VNet-internal, not SonarQube Server itself)

## Deployment Steps

### 1. Create the Container Apps Environment (VNet-integrated, internal only)

```bash
# Create a dedicated subnet for Container Apps (skip if reusing an existing VNet/subnet)
az network vnet subnet create \
  --resource-group <rg-name> \
  --vnet-name <vnet-name> \
  --name sonarqube-mcp-subnet \
  --address-prefix 10.x.x.0/23

# Create the Container Apps environment with internal-only ingress
az containerapp env create \
  --name sonarqube-mcp-env \
  --resource-group <rg-name> \
  --location <region> \
  --internal-only true \
  --infrastructure-subnet-resource-id /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/sonarqube-mcp-subnet
```

### 2. Promote the image into your own ACR, then deploy from there

Don't point the Container App at the Docker Hub image directly — this project's supply-chain approach is
to vet the image once (Trivy scan) and promote it into an org-controlled ACR, pinned by digest, so the
Container App only ever pulls from a source you control. See
[infrastructure/SonarQubeMCP/RUNBOOK.md](../infrastructure/SonarQubeMCP/RUNBOOK.md#step-3--image-promotion)
for the actual promotion steps (`az acr import` + reading back the digest).

```bash
az containerapp create \
  --name sonarqube-mcp \
  --resource-group <rg-name> \
  --environment sonarqube-mcp-env \
  --image <your-acr-name>.azurecr.io/sonarsource/sonarqube-mcp@<digest-from-acr-import> \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 2 \
  --env-vars \
    SONARQUBE_TRANSPORT=http \
    SONARQUBE_HTTP_HOST=0.0.0.0 \
    SONARQUBE_HTTP_PORT=8080 \
    SONARQUBE_URL=<your-sonarqube-url> \
    SONARQUBE_READ_ONLY=true \
    TELEMETRY_DISABLED=true \
    SONARQUBE_MCP_IN_CONTAINER=true
```

> **TLS Note:** Azure Container Apps automatically handles HTTPS/TLS termination at the ingress layer. The container runs plain HTTP on port 8080 internally — `SONARQUBE_TRANSPORT=http` is correct here. Developers connect via HTTPS to the Container Apps URL.

> **No shared service account token needed:** In HTTP mode the server is stateless. Each developer provides their own `Authorization: Bearer <token>` per-request. There is no shared service account token required at the server level.

### 3. Environment Variables Reference

| Variable | Required | Value | Purpose |
| :--- | :--- | :--- | :--- |
| `SONARQUBE_TRANSPORT` | Yes | `http` | Enable HTTP mode (Azure Container Apps handles TLS) |
| `SONARQUBE_HTTP_HOST` | Yes | `0.0.0.0` | Listen on all interfaces inside the container |
| `SONARQUBE_HTTP_PORT` | Yes | `8080` | Port the container listens on |
| `SONARQUBE_URL` | Yes | `<internal SonarQube URL>` | Points to the internal SonarQube Server |
| `SONARQUBE_READ_ONLY` | Yes | `true` | AI cannot change issue statuses or quality gates |
| `TELEMETRY_DISABLED` | Yes | `true` | Disables anonymous telemetry to SonarSource |
| `SONARQUBE_MCP_IN_CONTAINER` | Yes | `true` | Required for correct behavior inside a container runtime |

> **Never set `SONARQUBE_ORG`** — this would connect the server to SonarCloud, which is not approved per governance policy.

### 4. Verify the Deployment

From within the VNet (e.g., via VPN or a bastion host), confirm the server is healthy:

```bash
# Liveness check — should return HTTP 200 with an empty body
curl https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/health

# Version check — should return {"version":"1.24.0"}
curl https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/info
```

## Developer Configuration

Developers do **not** need Docker installed. Add the following to `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json`:

```json
{
  "servers": {
    "mcp/sonarqube": {
      "type": "http",
      "url": "https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/mcp",
      "headers": {
        "Authorization": "Bearer <your-sonarqube-user-token>"
      }
    }
  }
}
```

> **Token type:** Must be a SonarQube **USER token**. Project tokens and Global Administrator tokens are not compatible with SonarQube Server's MCP integration.

> **VPN required:** The Container Apps internal URL only resolves within the Azure VNet. Developers must be on VPN.

## Updating the Server

See [mcp-maintenance.md](mcp-maintenance.md) for the full update policy. Short version:

1. Check [GitHub Releases](https://github.com/SonarSource/sonarqube-mcp-server/releases) for the new version tag
2. Open a feature branch and update the version in:
   - `v0.1/servers/index.json`
   - `v0.1/servers/mcp/sonarqube/versions/latest/index.json`
   - `README.md` (any version references)
   - This file (image tag in the deploy command and the rollback section below)
3. Trivy-scan the new tag, promote it into ACR by digest, then update the running Container App directly
   — **never** point the Container App at the Docker Hub tag directly (see
   [infrastructure/SonarQubeMCP/RUNBOOK.md](../infrastructure/SonarQubeMCP/RUNBOOK.md#step-3--image-promotion)
   for the exact commands). This is what the `devops` repo's image-update pipeline (task #7,
   [devops/Pipelines/SonarQubeMCP/](https://dev.azure.com/Ethico/NWOW/_git/devops)) automates end to end —
   trigger it with the new version tag rather than running these by hand when it's available:
   ```bash
   az acr import --name <your-acr-name> --source docker.io/sonarsource/sonarqube-mcp:<new-version-tag> --image sonarsource/sonarqube-mcp:<new-version-tag>
   az acr repository show --name <your-acr-name> --image sonarsource/sonarqube-mcp:<new-version-tag> --query digest -o tsv
   az containerapp update --name ca-sonarqube-mcp-dev --resource-group rg-ethico-sonarqube-mcp-dev --image <your-acr-name>.azurecr.io/sonarsource/sonarqube-mcp@<digest-from-above>
   ```
   **Intentionally, this does not touch `imageDigest` in [main.bicep](../infrastructure/SonarQubeMCP/main.bicep)** — see the note on that parameter for why, and don't "fix" the drift by adding a step here that edits and redeploys Bicep for a routine update.
4. Re-verify `/health` and `/info`, then merge the PR

## Rollback

If an update causes issues, revert immediately by pointing the running Container App back at the
previously-promoted digest — **not** by pulling a Docker Hub tag directly, and **not** by redeploying
`main.bicep`, since only digests that have already been Trivy-scanned and promoted into ACR should ever
run here, and a routine rollback has no reason to touch the rest of the infrastructure:

```bash
az containerapp update --name ca-sonarqube-mcp-dev --resource-group rg-ethico-sonarqube-mcp-dev --image <your-acr-name>.azurecr.io/sonarsource/sonarqube-mcp@<prior-known-good-digest>
```

Then open a PR to revert the registry files to the previous version. (`1.24.0.3152`
— digest `sha256:edf80a38956d7d8de75166c1ae173b73c8a01a9a62038232ce0b75ead7dc450c` — is both the current
and the only version ever actually deployed; the originally-planned `1.20.0.2929` was scanned but never
promoted, see [infrastructure/SonarQubeMCP/RUNBOOK.md](../infrastructure/SonarQubeMCP/RUNBOOK.md#step-3--image-promotion).
Update this rollback target whenever a future version is promoted, to whatever digest was running
immediately before it.)

> **Why `main.bicep`'s `imageDigest` isn't part of routine updates or rollbacks:** that parameter's
> hardcoded default only matters for a full from-scratch redeploy of this environment (e.g. disaster
> recovery) — it is understood to become stale the moment either process above runs, since neither one
> touches the file. That's accepted, not a bug: `main.bicep` is a one-time setup tool, not the routine
> update mechanism, and we're not expecting to re-run it outside of a full environment rebuild. If that
> ever happens, the expected sequence is `main.bicep` first (bringing up the environment pinned to
> whatever old digest is on file), then re-running the image-update pipeline (task #7) immediately after
> to bring the Container App up to the actual current version — not editing the stale default beforehand.
