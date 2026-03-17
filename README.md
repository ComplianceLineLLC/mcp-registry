# GitHub Copilot MCP Registry

This repository hosts the official **Model Context Protocol (MCP) Registry** for ComplianceLine LLC dba Ethico. It serves as the "Source of Truth" for all AI-powered tools and integrations available to our developers through GitHub Copilot.

## 🎯 Purpose
By centralizing our MCP configurations here, we achieve:
* **Governance:** Only vetted and approved tools are available to the organization.
* **Ease of Use:** Developers don't need to manually configure complex JSON files; they simply connect to this registry URL.
* **Security:** We prevent the execution of unvetted third-party MCP servers by enforcing a "Registry Only" policy.

## 🛠 Current Integrations
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Azure DevOps** | Local wrapper (npx) — communicates with Microsoft-managed Azure DevOps (HTTP) | Integration with work items, PRs, and pipelines. |
| **Playwright** | Local (stdio) | Browser automation and end-to-end testing assistance. |

## 🛠 Future Integrations (Phase 2)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Chrome DevTools** | Local (npx) | Integration with Chrome DevTools for debugging and performance analysis. |
| **Microsoft Learn** | Remote (HTTP) | Access to Microsoft Learn content and interactive tutorials. |
| **Angular** | Local (npx) | Angular CLI integration for local development: scaffolding, component generation, build/serve, testing, and linting automation. |

## 🛠 Future Integrations (Phase 3)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Postman** | Remote (HTTP) | API testing and automation integration. |
| **SonarQube** | Remote (HTTP) | Code quality and security analysis. |

## 🛠 Future Integrations (TBD)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **LaunchDarkly** | Remote (HTTP) | Feature flag management and experimentation. |
| **Markdown** | Local (stdio) | Markdown rendering and preview assistance. |


## 🚀 How to Use
1. **Org Admins:** The registry will be hosted via GitHub Pages at: `https://[your-org].github.io/[repo-name]/`
2. **Developers:** In VS Code or Visual Studio, ensure you are signed into the organization account. Type `@mcp` in Copilot Chat to see the "Organization Approved" tools.

## 📂 Repository Structure
This repo follows the **MCP Registry Specification v0.1**. Because this is a static site, we use an `index.json` pattern:
* `/v0.1/servers/index.json` - The master list of available tools.
* `/v0.1/servers/mcp/[name]/versions/latest/index.json` - Specific execution logic for each tool.

## 🔐 Contribution Policy
1. All changes must be made via a **Feature Branch**.
2. A **Pull Request** is required for all merges into `main`.
3. Validate JSON syntax before merging to avoid breaking Copilot functionality for the entire organization.