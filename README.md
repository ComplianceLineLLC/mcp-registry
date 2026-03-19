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
1. **Org Admins:** The registry will be hosted via GitHub Pages at: `https://compliancelinellc.github.io/mcp-registry/`
2. **Developers:** In VS Code or Visual Studio, ensure you are signed into the organization account. Type `@mcp` in Copilot Chat to see the "Organization Approved" tools.

## 🔧 Using Individual MCP Servers
Before using an MCP, search for available MCPs on your machine in Copilot Chat by typing `@mcp`. Install the MCP you want to use from within VS Code or Visual Studio (follow the editor prompts or use the Extensions/Marketplace). After installation the MCP should be available to Copilot Chat and ready to respond to prompts.

**Playwright** (Local - stdio)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Playwright MCP.
- Install the Playwright MCP with VS Code or Visual Studio.
- Once installed, you can ask Copilot Chat to generate tests. Example prompt:

  `Generate a Playwright test to check if the "log on" button is visible at https://qa.mycompliancemanagement.com/login`

  The Playwright MCP will assist with test code and local browser automation.

**Azure DevOps** (Local wrapper - npx)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Azure DevOps MCP.
- Install the Azure DevOps MCP with VS Code or Visual Studio.
- In the PowerShell terminal run the following commands:

   ```ps
   az devops login --org https://dev.azure.com/Ethico
   az devops configure --defaults organization=https://dev.azure.com/Ethico project=NWOW
   ```

- After setting the PAT (and restarting Visual Studio or VS Code), you can ask Copilot Chat example prompts such as:

  `List recent work items assigned to me in Azure DevOps`

  You may be then prompted in the browser to sign in with your organizational account and grant permissions to the MCP. Once authenticated, the Azure DevOps MCP will respond to your prompt with relevant information from Azure DevOps.

## 📂 Repository Structure
This repo follows the **MCP Registry Specification v0.1**. Because this is a static site, we use an `index.json` pattern:
* `/v0.1/servers/index.json` - The master list of available tools.
* `/v0.1/servers/mcp/[name]/versions/latest/index.json` - Specific execution logic for each tool.

## 🔐 Contribution Policy
1. All changes must be made via a **Feature Branch**.
2. A **Pull Request** is required for all merges into `main`.
3. Validate JSON syntax before merging to avoid breaking Copilot functionality for the entire organization.