# SonarQube MCP Server — Azure Deployment Guide

## Architecture

The SonarQube MCP Server is deployed as a centrally managed Docker container in **Azure Container Apps** with **internal-only ingress**. This means:

- No public internet endpoint — the server is unreachable from outside the Azure VNet
- Developers connect via corporate VPN to the VNet-private URL
- All developers connect to the same hosted instance — no Docker required locally
- The server is **stateless**: each request carries the developer's own SonarQube USER token via `Authorization: Bearer <token>`

```
[Developer + VPN] → [Azure VNet] → [Container App (internal ingress)] → [Internal SonarQube Server]
```

## Prerequisites

- Azure subscription with permission to create Container Apps
- An existing Azure Virtual Network (VNet), or permission to create one
- VPN Gateway or ExpressRoute providing developer access to the VNet
- Internal SonarQube Server URL (e.g. `https://sqdev.mycompliancemanagement.com`)

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

### 2. Deploy the Container App

```bash
az containerapp create \
  --name sonarqube-mcp \
  --resource-group <rg-name> \
  --environment sonarqube-mcp-env \
  --image sonarsource/sonarqube-mcp:1.20.0.2929 \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 2 \
  --env-vars \
    SONARQUBE_TRANSPORT=http \
    SONARQUBE_HTTP_HOST=0.0.0.0 \
    SONARQUBE_HTTP_PORT=8080 \
    SONARQUBE_URL=<your-internal-sonarqube-url> \
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
curl https://<container-app-internal-url>/health

# Version check — should return {"version":"1.20.0"}
curl https://<container-app-internal-url>/info
```

## Developer Configuration

Developers do **not** need Docker installed. Add the following to `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json`:

```json
{
  "servers": {
    "mcp/sonarqube": {
      "type": "http",
      "url": "https://<container-app-internal-url>/mcp",
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
3. Redeploy the running container:
   ```bash
   az containerapp update \
     --name sonarqube-mcp \
     --resource-group <rg-name> \
     --image sonarsource/sonarqube-mcp:<new-version-tag>
   ```
4. Re-verify `/health` and `/info`, then merge the PR

## Rollback

If an update causes issues, revert immediately:

```bash
az containerapp update \
  --name sonarqube-mcp \
  --resource-group <rg-name> \
  --image sonarsource/sonarqube-mcp:1.20.0.2929
```

Then open a PR to revert the registry files to the previous version.
