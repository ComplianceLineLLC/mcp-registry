# MCP Registry — Maintenance Policy

This document defines how the IT/DevOps team reviews, updates, and secures all MCP servers registered in this internal registry.

## Maintenance Categories

| Category | Description | Who Updates | Update Trigger |
| :--- | :--- | :--- | :--- |
| **Vendor-managed (remote)** | Hosted and maintained entirely by the vendor. No infrastructure to manage. | Vendor | Vendor changes their endpoint — monitor release notes |
| **Org-managed (hosted)** | Container we deploy and run internally on Azure. We control the version. | IT/DevOps | New release from vendor, security advisory, or policy change |
| **Developer-local (stdio)** | Runs as a local subprocess on the developer's machine via npx/node. VS Code enforces the version in `mcp.json`. | IT/DevOps (version pin) | New npm release or security advisory |

## MCP Inventory

| MCP | Category | Pinned Version | Package / Endpoint | Version Source |
| :--- | :--- | :--- | :--- | :--- |
| Azure DevOps | Developer-local | `2.7.0` | `@azure-devops/mcp` (npm) | https://www.npmjs.com/package/@azure-devops/mcp |
| Playwright | Developer-local | `1.0.0` | `@executeautomation/playwright-mcp-server` (npm) | https://www.npmjs.com/package/@executeautomation/playwright-mcp-server |
| Chrome DevTools | Developer-local | `0.1.0` | `chrome-devtools-mcp` (npm) | https://www.npmjs.com/package/chrome-devtools-mcp |
| Angular | Developer-local | `0.1.0` | `@angular/cli` (npm) | https://www.npmjs.com/package/@angular/cli |
| Microsoft Learn | Vendor-managed | N/A (remote) | `https://learn.microsoft.com/api/mcp` | https://github.com/MicrosoftDocs/mcp |
| Figma | Vendor-managed | N/A (remote) | `https://mcp.figma.com/mcp` | https://www.figma.com/developers/mcp |
| SonarQube | Org-managed | `1.24.0.3152` | `ethicosonarqubecrdev.azurecr.io/sonarsource/sonarqube-mcp` (ACR, promoted from Docker Hub — see [infrastructure/SonarQubeMCP/RUNBOOK.md](../infrastructure/SonarQubeMCP/RUNBOOK.md)) | https://github.com/SonarSource/sonarqube-mcp-server/releases |

## Monthly Review Checklist

Perform this review during the first week of each month.

### 1. Check for New Versions

```bash
# Azure DevOps MCP
npm view @azure-devops/mcp version

# Playwright MCP
npm view @executeautomation/playwright-mcp-server version

# Chrome DevTools MCP
npm view chrome-devtools-mcp version

# Angular CLI
npm view @angular/cli version

# SonarQube MCP — check GitHub Releases page
# https://github.com/SonarSource/sonarqube-mcp-server/releases
```

### 2. Security Scan

```bash
# Scan all npm-based packages for known vulnerabilities
npm audit --package-lock-only

# Scan the SonarQube MCP Docker image with Trivy
trivy image sonarsource/sonarqube-mcp:<current-version>
```

Subscribe to GitHub Security Advisories for each package:
- https://github.com/microsoft/azure-devops-mcp/security/advisories
- https://github.com/microsoft/playwright/security/advisories
- https://github.com/SonarSource/sonarqube-mcp-server/security/advisories

### 3. Update Decision Matrix

| Condition | Action | Timeline |
| :--- | :--- | :--- |
| Minor/patch release, no security advisory | Schedule for next monthly review | Next monthly cycle |
| Minor/patch release with a relevant enhancement | Open feature branch, update version, test, PR | Within 2 weeks |
| Security advisory — severity: High or Critical | Emergency update process | Within 24 hours |
| Security advisory — severity: Medium | Expedited update | Within 72 hours |
| Breaking change in major version | Evaluate impact, test in staging, coordinate with teams | Planned sprint |

## Standard Update Process

1. Open a feature branch: `git checkout -b update/<mcp-name>-<version>`
2. **For org-managed MCPs (SonarQube)** — vet and promote the new image before touching any registry files:
   - Trivy-scan the candidate tag directly against Docker Hub: `docker run --rm aquasec/trivy image --severity HIGH,CRITICAL sonarsource/sonarqube-mcp:<new-version>`
   - If it comes back with unaddressed High/Critical findings, check GitHub Releases for a newer tag before accepting the risk — see [infrastructure/SonarQubeMCP/RUNBOOK.md](../infrastructure/SonarQubeMCP/RUNBOOK.md#step-3--image-promotion) for how this played out on the initial promotion
   - If clean, promote into ACR pinned by digest: `az acr import --name ethicosonarqubecrdev --source docker.io/sonarsource/sonarqube-mcp:<new-version> --image sonarsource/sonarqube-mcp:<new-version>`, then read back the digest with `az acr repository show --name ethicosonarqubecrdev --image sonarsource/sonarqube-mcp:<new-version> --query digest -o tsv`
3. Update the version in `v0.1/servers/index.json`
4. Update the version in `v0.1/servers/mcp/<name>/versions/latest/index.json`
5. Update any version references in `README.md`
6. For org-managed MCPs (SonarQube): update `imageDigest` in [infrastructure/SonarQubeMCP/main.bicep](../infrastructure/SonarQubeMCP/main.bicep) to the new digest and redeploy (`az deployment sub create --location eastus --template-file main.bicep`); update the version/URL references in [sonarqube-deployment.md](sonarqube-deployment.md) too
7. Verify all endpoints or run a quick smoke test
8. Open a PR, request review from a second team member, merge

Steps 2 and 6 are manual today. Once the Azure DevOps Pipeline at `Pipelines/SonarQubeMCP/` (plan.md
task #7, not yet built) lands, it automates this scan → promote → redeploy → verify sequence — this
section should be updated to reference the pipeline once that happens, rather than describing manual
steps that are no longer how updates actually happen.

## Emergency Security Update Process

For High/Critical severity advisories:

1. **Within 1 hour:** Notify the team via the `#mcp-ops` channel
2. **Within 4 hours:** Open a hotfix branch and update the affected MCP version
3. **Within 24 hours (High) / 72 hours (Critical — already patched urgency):**
   - Complete the update and redeploy (for SonarQube)
   - Merge the PR (single reviewer is acceptable for emergency patches)
   - Notify developers via `#engineering-announcements` with the new version and any config change instructions
4. Document the advisory and remediation in the PR description

## Version Pinning Policy

All MCPs in this registry pin to an **exact version**. Floating version ranges (e.g. `^1.0.0`, `latest`) are not permitted in registry files.

Rationale:
- Reproducibility: all developers get the same server behavior
- Security: prevents silent supply-chain updates
- Auditability: version is always visible in the registry JSON

Exception: Vendor-managed remote MCPs (Microsoft Learn, Figma) have no pinned version because the version is controlled entirely by the vendor at the remote endpoint.

## Governance Alignment

The following controls are enforced in the registry to remain compliant with the IT security governance policy for SonarQube:

| Control | Implementation | Where Enforced |
| :--- | :--- | :--- |
| Self-Hosted Only — no SonarCloud | `SONARQUBE_URL` must be internal; `SONARQUBE_ORG` must never be set | `sonarqube-deployment.md`, container env vars |
| Private VNet boundary | Azure Container Apps with `--ingress internal`; no public endpoint | Azure infrastructure |
| USER tokens only | Registry documentation and developer guide explicitly state USER token requirement | `README.md`, `sonarqube-deployment.md` |
| No Global Administrator tokens | Stated in README security requirement | `README.md` |
| Read-only enforcement | `SONARQUBE_READ_ONLY=true` | Container env var |
| Telemetry disabled | `TELEMETRY_DISABLED=true` | Container env var |
