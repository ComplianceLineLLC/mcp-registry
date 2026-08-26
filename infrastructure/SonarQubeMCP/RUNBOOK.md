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

**Status: done — 2026-08-11.** Ran successfully; `provisioningState: "Succeeded"` with all four expected
resources present (the resource group, the ACR, the managed identity, and its `AcrPull` role assignment).

**PowerShell / bash (identical — single line, no continuation needed):**

```shell
az deployment sub create --location eastus --template-file main.bicep
```

Created (idempotently, including the resource group from Step 0):

- `rg-ethico-sonarqube-mcp-dev`
- `ethicosonarqubecrdev` — the Azure Container Registry ([modules/acr.bicep](modules/acr.bicep))
- `ethico-sonarqube-mcp-mi-dev` — a user-assigned managed identity ([modules/managed-identity.bicep](modules/managed-identity.bicep))
- An `AcrPull` role assignment granting that identity pull access to the ACR ([modules/acr-role-assignment.bicep](modules/acr-role-assignment.bicep))

## Step 3 — Image promotion

**Status: done — 2026-08-12.** The originally-planned pin, `sonarsource/sonarqube-mcp:1.20.0.2929`, was
scanned first and came back with **4 unaddressed HIGH findings** (`c-ares` CVE-2026-33630; `nodejs`
CVE-2026-56846, CVE-2026-56848, CVE-2026-58043 — all `Status: fixed` upstream, meaning newer package
builds already resolve them). Rather than accept that risk or wait on a rebuild, checked the
[GitHub Releases page](https://github.com/SonarSource/sonarqube-mcp-server/releases) for newer tags:
`1.20.0.2929` (our original pin) has four releases ahead of it — `1.21.0.2975`, `1.22.0.3040`,
`1.23.0.3101`, and the latest, **`1.24.0.3152`**. Trivy-scanned `1.24.0.3152` and it came back **clean**
(0 findings) — its base Alpine/Node layers had already moved past the vulnerable versions. **Decision:
promote `1.24.0.3152` instead of the originally-planned `1.20.0.2929`.**

**PowerShell / bash (identical):**

```shell
docker run --rm aquasec/trivy image --severity HIGH,CRITICAL sonarsource/sonarqube-mcp:1.24.0.3152

az acr import --name ethicosonarqubecrdev --source docker.io/sonarsource/sonarqube-mcp:1.24.0.3152 --image sonarsource/sonarqube-mcp:1.24.0.3152

az acr repository show --name ethicosonarqubecrdev --image sonarsource/sonarqube-mcp:1.24.0.3152 --query digest -o tsv
```

Imported successfully. Resulting digest — **this is what task #4 pins in the Container App**, not the
mutable tag:

```text
sha256:edf80a38956d7d8de75166c1ae173b73c8a01a9a62038232ce0b75ead7dc450c
```

Full image reference: `ethicosonarqubecrdev.azurecr.io/sonarsource/sonarqube-mcp@sha256:edf80a38956d7d8de75166c1ae173b73c8a01a9a62038232ce0b75ead7dc450c`

**Follow-up required:** this version bump ripples into places still pinned to `1.20.0.2929` —
`docs/mcp-maintenance.md`'s inventory table, `docs/sonarqube-deployment.md`'s example commands and
`/info` response, `v0.1/servers/index.json` and `v0.1/servers/mcp/sonarqube/versions/latest/index.json`,
and `plan.md`'s verification step #2. Task #8 ("Registry & doc updates") already covers touching most of
these files for the FQDN/execution-model fix — worth doing the version bump in the same pass rather than
as a second edit to the same files.

## Step 4 — Container Apps Environment, Container App, and Log Analytics (task #4)

**Status: authored 2026-08-26, not yet deployed.** `main.bicep` extended with four new modules:

- [modules/log-analytics.bicep](modules/log-analytics.bicep) — `law-sonarqube-mcp-dev`, `PerGB2018`, 30-day retention
- [modules/container-apps-environment.bicep](modules/container-apps-environment.bicep) — `internal: true`, wired to the `SonarQubeMCP-Dev-Subnet` from Step 1 (cross-resource-group reference — the subnet lives in `RG-PolicyManagement`, referenced by resource ID string only, no `existing` lookup needed), Consumption workload profile (matches the `/27` subnet sizing — Dedicated profiles need the larger `/23` Microsoft recommends), logs routed to the workspace above
- [modules/container-app.bicep](modules/container-app.bicep) — pulls the digest-pinned image from ACR (`sha256:edf80a38…`, task #3) using the `ethico-sonarqube-mcp-mi-dev` identity for registry auth; internal ingress on port 8080; env vars per [docs/sonarqube-deployment.md](../../docs/sonarqube-deployment.md); min/max replicas 1/2
- [modules/diagnostic-settings.bicep](modules/diagnostic-settings.bicep) — explicit console/system log + metric streaming from the Container App to the workspace, separate from the environment's own log plumbing

Compiles clean (`az bicep build`, no warnings).

**PowerShell / bash (identical — single line):**

```shell
az deployment sub create --location eastus --template-file main.bicep
```

Idempotent with Steps 2–3 — re-running this also re-confirms the resource group, ACR, and identity are
unchanged, then adds the four new resources.

## Step 5 — Monitoring (task #5) and pipeline (task #7)

**Status: pending.** Documented here once executed.
