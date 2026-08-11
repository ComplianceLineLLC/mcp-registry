# SonarQube MCP — Infrastructure Deployment Runbook

Human-readable walkthrough of the actual steps taken to stand up this infrastructure, in the order
they happened. The Bicep in this folder is the source of truth for *what* gets created; this document
is the source of truth for *how it was actually rolled out* — so the process can be audited, or
repeated from scratch if this environment is ever rebuilt.

Tracked alongside NWOW work item **#134516**; see [../../specs/134516-sonarqube-mcp-server/plan.md](../../specs/134516-sonarqube-mcp-server/plan.md)
for the task list and current status.

Commands are given in both PowerShell and bash — use whichever matches your shell.

## Prerequisites

- Access to **Azure DevTest subscription 1** (`326c5c7f-73c8-4e8b-b146-d643c06ced0d`, tenant `complianceline.com`)
- `az` CLI with the Bicep tooling available (`az bicep build` should run without installing anything extra)
- Network changes require sign-off from the network team (Gilbert) before anything is created — see the
  approved design in [network-architecture.html](../../specs/134516-sonarqube-mcp-server/network-architecture.html)

## Step 0 (historical, out of band) — Resource group

`rg-ethico-sonarqube-mcp-dev` (eastus) was created manually on **2026-08-03**, before any Bicep in this
folder existed — it was needed at the time to scope a Reader role assignment for the `NewRelic-Integrations`
app registration (see plan.md's Monitoring decision). `main.bicep` now defines this resource group
declaratively, so a genuine from-scratch rebuild going forward would create it as part of Step 2 below —
this manual step is a one-time historical fact, not something to repeat.

## Step 1 — Networking: create the delegated subnet

Executed **2026-08-11**, after Gilbert approved the proposed subnet/egress path.

Command run (against the existing shared VNet, in its own resource group — not this workload's):

**PowerShell:**

```powershell
az network vnet subnet create `
  --resource-group RG-PolicyManagement `
  --vnet-name clDEVvNET `
  --name SonarQubeMCP-Dev-Subnet `
  --address-prefixes 20.0.3.160/27 `
  --delegations Microsoft.App/environments `
  --network-security-group "/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/networkSecurityGroups/NSG-DEVSubscription" `
  --route-table "/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/routeTables/DEV-RouteTable"
```

**Bash:**

```bash
az network vnet subnet create \
  --resource-group RG-PolicyManagement \
  --vnet-name clDEVvNET \
  --name SonarQubeMCP-Dev-Subnet \
  --address-prefixes 20.0.3.160/27 \
  --delegations Microsoft.App/environments \
  --network-security-group "/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/networkSecurityGroups/NSG-DEVSubscription" \
  --route-table "/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/routeTables/DEV-RouteTable"
```

Captured as IaC at [modules/networking.bicep](modules/networking.bicep) for reproducibility — deployed as
its **own** `az deployment group create` against `RG-PolicyManagement`, deliberately kept separate from
`main.bicep` (which only ever targets this workload's own resource group). The reasoning: `clDEVvNET` is a
shared VNet with a dozen other teams' subnets already in it; folding subnet creation into the same
deployment as this workload's own ACR/Container App would mean every future redeploy of *our* resources
also carries write access to *shared* network infrastructure.

Why `20.0.3.160/27`: the one open `/27` gap in the VNet's already-carved-up `20.0.3.0/24` block, following
the same delegation pattern as five sibling Container-Apps subnets.

Verification run after creation:

**PowerShell:**

```powershell
az network vnet subnet show --resource-group RG-PolicyManagement --vnet-name clDEVvNET `
  --name SonarQubeMCP-Dev-Subnet `
  --query "{prefix:addressPrefix, nsg:networkSecurityGroup.id, routeTable:routeTable.id, delegations:delegations[].serviceName}"
```

**Bash:**

```bash
az network vnet subnet show --resource-group RG-PolicyManagement --vnet-name clDEVvNET \
  --name SonarQubeMCP-Dev-Subnet \
  --query "{prefix:addressPrefix, nsg:networkSecurityGroup.id, routeTable:routeTable.id, delegations:delegations[].serviceName}"
```

Confirmed: `20.0.3.160/27`, delegated to `Microsoft.App/environments`, joined to `NSG-DEVSubscription` +
`DEV-RouteTable` — matches the approved design exactly.

## Step 2 — ACR, managed identity, and AcrPull role assignment

**Status: pending.**

**PowerShell / bash (identical — single line, no continuation needed):**

```
az deployment sub create --location eastus --template-file main.bicep
```

Creates (idempotently, including the resource group from Step 0):

- `rg-ethico-sonarqube-mcp-dev`
- `ethicosonarqubecrdev` — the Azure Container Registry ([modules/acr.bicep](modules/acr.bicep))
- `ethico-sonarqube-mcp-mi-dev` — a user-assigned managed identity ([modules/managed-identity.bicep](modules/managed-identity.bicep))
- An `AcrPull` role assignment granting that identity pull access to the ACR ([modules/acr-role-assignment.bicep](modules/acr-role-assignment.bicep))

## Step 3 — Image promotion

**Status: pending.**

Pull `sonarsource/sonarqube-mcp:1.20.0.2929` from Docker Hub, Trivy-scan it, and (if clean of unaddressed
High/Critical findings) push it into `ethicosonarqubecrdev`, pinned by digest.

## Step 4 — Container Apps Environment, Container App, and Log Analytics (task #4)

**Status: pending.** Will extend `main.bicep` with the Container Apps Environment (wired to the subnet
from Step 1), the Container App itself (attaching the identity from Step 2), and a Log Analytics workspace
+ diagnostic settings.

## Step 5 — Monitoring (task #5) and pipeline (task #7)

**Status: pending.** Documented here once executed.
