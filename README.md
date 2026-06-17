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
| **Angular** | Local (npx) | Angular CLI integration for local development: scaffolding, component generation, build/serve, testing, and linting automation. |
| **Azure DevOps** | Local wrapper (npx) — communicates with Microsoft-managed Azure DevOps (HTTP) | Integration with work items, PRs, and pipelines. |
| **Chrome DevTools** | Local (npx) | Integration with Chrome DevTools for debugging and performance analysis. |
| **Figma** | Remote (HTTP) | Official Figma MCP server for design file access and collaboration. |
| **Microsoft Learn** | Remote (HTTP) | Access to Microsoft Learn content and interactive tutorials. |
| **Playwright** | Local (stdio) | Browser automation and end-to-end testing assistance. |


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

---
## **Angular** (Local - npx)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Angular MCP.
- Install the Angular MCP with VS Code or Visual Studio.
- Once installed, open your Angular project folder in VS Code, then ask Copilot Chat prompts such as:

  `Generate a new Angular component called UserProfile`

  `Run the Angular unit tests for this project`

  `Scaffold a new Angular service for authentication`

  The Angular MCP will invoke the Angular CLI on your behalf, scaffolding files and running build or test commands within your current workspace.

---
## **Azure DevOps** (Local wrapper - npx)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Azure DevOps MCP.
- Install the Azure DevOps MCP with VS Code or Visual Studio.
- In your project, add a `.vscode/mcp.json` file (create the `.vscode` folder if it doesn't exist) or updated the VS Code generated file at `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json` with the following content:

  ```json
  {
    "inputs": [
      {
        "id": "ado_org",
        "type": "promptString",
        "description": "Azure DevOps organization name (e.g. 'Ethico')"
      }
    ],
    "servers": {
      "ado": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@azure-devops/mcp", "${input:ado_org}"]
      }
    }
  }
  ```

Example for `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json`

```json
{
  "servers": {
    "mcp/azure-devops": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", 
      "@azure-devops/mcp", 
      "Ethico"],
      "gallery": "https://compliancelinellc.github.io/mcp-registry",
      "version": "2.7.0"
    }
  },
  "inputs": []
}
```

  VS Code will prompt you for your Azure DevOps organization name the first time the server starts. Enter `Ethico` when prompted.

- You will be prompted in the browser to sign in with your organizational account and grant permissions to the MCP. Once authenticated, you can ask Copilot Chat example prompts such as:

  `List recent work items assigned to me in Azure DevOps`

Alternatively, check your VS Code User Settings by pressing `Ctrl+Shift+P` and then type "Preferences: Open User Settings (JSON)"
Look for the github.copilot.chat.mcp section. If you don't find it, add it along with setting a Personal Access Token (PAT):
```json
    "github.copilot.chat.agent.thinkingTool": true,
    "chat.viewSessions.orientation": "stacked",
    "chat.mcp.gallery.enabled": true,
    "github.copilot.chat.mcp.servers": {
        "azure-dev": {
            "command": "npx",
            "args": ["-y", "@azure/mcp-server-azure-devops"],
            "env": {
                "AZURE_DEVOPS_PAT": "your-pat-here",
                "AZURE_DEVOPS_ORG_URL": "https://dev.azure.com/Ethico"
            }
        }
    },
```

Key points:

- Replace "your-pat-here" with your actual PAT token
- The PAT needs Release (Read), Build (Read), and Project and Team (Read) scopes
- After adding this, reload VS Code (`Ctrl+Shift+P` → "Developer: Reload Window")


---
## **Chrome DevTools** (Local - npx)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Chrome DevTools MCP.
- Install the Chrome DevTools MCP with VS Code or Visual Studio.
- Once installed, open or navigate to the page you want to inspect, then ask Copilot Chat prompts such as:

  `Analyze the performance profile of the currently open page in Chrome`

  `Show me any console errors on the active Chrome tab`

  The Chrome DevTools MCP will connect to your local Chrome browser using the DevTools Protocol and return diagnostic information directly in Copilot Chat.

---
## **Figma** (Remote - HTTP)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Figma MCP.
- Install the Figma MCP with VS Code or Visual Studio. Because this is a remote MCP, no local package installation is required — the client connects directly to `https://mcp.figma.com/mcp`.
- You may be prompted to sign in with your Figma account to access your design files and projects.

  **Getting Started (No Existing Designs):**
  If you don't have existing Figma designs, you can quickly create a test file to verify the MCP is working:
  1. Go to [figma.com](https://figma.com) and sign in (free account works)
  2. Click "New design file" to create a blank canvas
  3. Add a few basic elements:
     - Create a rectangle (press `R`) and style it with a color
     - Add text (press `T`) with a heading like "My Test App"
     - Create a button component (draw a rectangle + text, then right-click → "Create component")
  4. Name your file something memorable (e.g., "MCP Test Design")
  5. Copy the file URL from your browser

  Alternatively, duplicate a [Figma Community template](https://www.figma.com/community) to start with a professional design system.

- Once connected, you can ask Copilot Chat prompts such as:

  `@mcp Create a new Figma file called "MCP New Test Design"`

  `Show me the design components in [Figma design URL]`

  `@mcp Please list out the layers in my file "MCP Test Design" from [Figma design URL]`

  `Get the color palette from [Figma design URL]`

  `What text styles are defined in my Figma file?`

  `Export the button component as SVG`

  The Figma MCP will access your Figma files and return design information, allowing you to integrate design system data directly into your development workflow. The MCP can read design tokens (colors, typography, spacing), components, layers, and export assets—bridging the gap between design and code.

---
## **Microsoft Learn** (Remote - HTTP)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Microsoft Learn MCP.
- Install the Microsoft Learn MCP with VS Code or Visual Studio. Because this is a remote MCP, no local package installation is required — the client connects directly to `https://learn.microsoft.com/api/mcp`.
- You may be prompted to sign in with your Microsoft account to access personalized learning content.
- Once connected, you can ask Copilot Chat prompts such as:

  `Find Microsoft Learn modules about Azure Bicep`

  `Show me the getting started guide for ASP.NET Core on Microsoft Learn`

  The Microsoft Learn MCP will query the Microsoft Learn catalog and return relevant documentation and tutorial links.

---
## **Playwright** (Local - stdio)
- Search for available MCPs on your machine by typing `@mcp` in Copilot Chat and locate the Playwright MCP.
- Install the Playwright MCP with VS Code or Visual Studio.
- Once installed, you can ask Copilot Chat to generate tests. Example prompt:

  `Generate a Playwright test to check if the "log on" button is visible at https://qa.mycompliancemanagement.com/login`

  The Playwright MCP will assist with test code and local browser automation.

---
## 📂 Repository Structure
This repo follows the **MCP Registry Specification v0.1**. Because this is a static site, we use an `index.json` pattern:
* `/v0.1/servers/index.json` - The master list of available tools.
* `/v0.1/servers/mcp/[name]/versions/latest/index.json` - Specific execution logic for each tool.

## 🔐 Contribution Policy
1. All changes must be made via a **Feature Branch**.
2. A **Pull Request** is required for all merges into `main`.
3. Validate JSON syntax before merging to avoid breaking Copilot functionality for the entire organization.