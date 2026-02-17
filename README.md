# GitHub Copilot MCP Registry

This repository hosts the official **Model Context Protocol (MCP) Registry** for ComplianceLine LLC dba Ethico. It serves as the "Source of Truth" for all AI-powered tools and integrations available to our developers through GitHub Copilot.

## 🎯 Purpose
By centralizing our MCP configurations here, we achieve:
* **Governance:** Only vetted and approved tools are available to the organization.
* **Ease of Use:** Developers don't need to manually configure complex JSON files; they simply connect to this registry URL.
* **Security:** We prevent the execution of unvetted third-party MCP servers by enforcing a "Registry Only" policy.

<br />

## 🛠 Planned Initial Integrations (Phase 1)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Azure DevOps** | Remote (HTTP) | Integration with work items, PRs, and pipelines. |
| **Playwright** | Local (stdio) | Browser automation and end-to-end testing assistance. |

<br />

## 🛠 Future Integrations (Phase 2)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Chrome DevTools** | Remote (HTTP) | Integration with Chrome DevTools for debugging and performance analysis. |
| **LaunchDarkly** | Remote (HTTP) | Feature flag management and experimentation. |
| **Markdown** | Local (stdio) | Markdown rendering and preview assistance. |
| **Microsoft Learn** | Remote (HTTP) | Access to Microsoft Learn content and interactive tutorials. |
| **Postman** | Remote (HTTP) | API testing and automation integration. |
| **SonarQube** | Remote (HTTP) | Code quality and security analysis. |

<br />

## 🚀 How to Use
1. **Org Admins:** The registry will be hosted via GitHub Pages at: `https://[your-org].github.io/[repo-name]/`
2. **Developers:** In VS Code or Visual Studio, ensure you are signed into the organization account. Type `@mcp` in Copilot Chat to see the "Organization Approved" tools.

<br />

## 📂 Repository Structure
This repo follows the **MCP Registry Specification v0.1**. Because this is a static site, we use an `index.json` pattern:
* `/v0.1/servers/index.json` - The master list of available tools.
* `/v0.1/servers/[name]/versions/latest/index.json` - Specific execution logic for each tool.

<br />

## 🔐 Contribution Policy
1. All changes must be made via a **Feature Branch**.
2. A **Pull Request** is required for all merges into `main`.
3. Validate JSON syntax before merging to avoid breaking Copilot functionality for the entire organization.