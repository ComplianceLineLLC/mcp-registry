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
| **SonarQube** | Internal Remote (HTTPS — Azure Container Apps, VNet-restricted) | Code quality and security analysis via centrally hosted SonarQube MCP Server. |


## 🛠 Future Integrations (Phase 3)
| Server Name | Type | Description |
| :--- | :--- | :--- |
| **Postman** | Remote (HTTP) | API testing and automation integration. |

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

> **⚠️ Known Issue — Manual fix required after installation**
> The registry defines `"args": ["mcp"]` in the Angular package spec so that VS Code generates the correct startup command (`npx --registry https://registry.npmjs.org @angular/cli mcp`). However, VS Code's gallery installer currently does not honor the `args` field and omits the `mcp` subcommand, producing `npx --registry https://registry.npmjs.org @angular/cli` instead. Without the `mcp` subcommand, Angular CLI just prints help text and exits, so the server will fail to start.
>
> **After installing, manually update the Angular entry in your `mcp.json`** (typically `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json`) to add `"mcp"` as an argument:
> ```json
> "mcp/angular": {
>   "type": "stdio",
>   "command": "npx",
>   "args": ["-y", "@angular/cli", "mcp"],
>   "gallery": "https://compliancelinellc.github.io/mcp-registry",
>   "version": "0.1.0"
> }
> ```
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
## **SonarQube** (Internal Remote — Azure Container Apps)

The SonarQube MCP is centrally hosted by the organization as an Azure Container Apps instance with **internal-only ingress** (no public internet endpoint). Docker is **not** required on your machine.

- **Token Requirement:** You must use a SonarQube **USER token** only. Project tokens and Global Administrator tokens are not supported by SonarQube Server's MCP integration and will not work.
- **Read-Only:** The server enforces read-only mode — you can view issues and analysis results but cannot change issue statuses or quality gates through the MCP.

### Step 1: Network setup

The MCP won't work without this — it's not optional.

1. Connect to the **corporate VPN**. The server has internal-only ingress, with no public internet endpoint.
2. There's currently no DNS entry for this hostname, so add a one-time hosts-file entry mapping it to its internal IP:

   ```text
   20.0.3.165   ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io
   ```

   On Windows, add this line to `C:\Windows\System32\drivers\etc\hosts` (requires administrator rights).

### Step 2: Generate your SonarQube USER token

1. Sign in to `https://sqdev.mycompliancemanagement.com`
2. Go to **My Account → Security → Generate Tokens**
3. For **Type**, choose **User** — not Project or Global Administrator; those are rejected by the MCP
4. Name it `mcp-<your-username>` (e.g. `mcp-jsmith`) so it's distinguishable from other tokens like CI/CD scanner tokens in your account
5. **Set an expiration date**, e.g. 90 days — do not choose "No expiration." 
Note: Our SonarQube current license doesn't allow us to eliminate the option. Tokens without expiration dates are actively monitored.
6. Copy the generated token now — it won't be shown again

> **This token is personal.** Don't share it or commit it anywhere. It ties every request the MCP makes back to your own SonarQube account and audit log.

### Step 3: Connect from your MCP client

<details>
<summary><strong>VS Code (GitHub Copilot)</strong></summary>

1. Type `@mcp` in Copilot Chat and locate **SonarQube** in the Organization Approved list.
2. Install it via the editor prompt — no local package to install, since this is a remote server (same as Figma).
3. Installing adds a bare entry with no authentication configured — you need to add that yourself. Open the file `@mcp` installed into (check `.vscode/mcp.json` in your workspace first, otherwise `C:\Users\<your user>\AppData\Roaming\Code\User\mcp.json`), and add an `inputs` entry plus a `headers` block to the `mcp/sonarqube` server so it looks like this:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "sonarqube-token",
      "description": "SonarQube USER token (mcp-<username>)",
      "password": true
    }
  ],
  "servers": {
    "mcp/sonarqube": {
      "type": "http",
      "url": "https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/mcp",
      "headers": {
        "Authorization": "Bearer ${input:sonarqube-token}"
      }
    }
  }
}
```

4. Start the server. VS Code prompts you for your token once, then stores it securely and reuses it on future starts — you won't be asked again.

> **If you skip step 3 and try starting the server first**, VS Code shows a "Dynamic Client Registration not supported" dialog — it's incorrectly assuming this server uses OAuth. Click **Cancel**, don't provide a manual client ID, then complete step 3 and start the server again.
>
> If the secure prompt ever misbehaves, a plain hardcoded header also works (stores the token in plaintext in the file, so treat the file accordingly):
> ```json
> "headers": { "Authorization": "Bearer <your-sonarqube-user-token>" }
> ```
>
> **If you ever uninstall and reinstall this MCP**, you'll need to redo step 3 — that's expected, not a sign something's broken.

</details>

<details>
<summary><strong>Claude Code (VS Code extension / CLI)</strong></summary>

Run (works the same whether you're in a plain terminal or VS Code's integrated terminal — Claude Code's config is shared between the CLI and the VS Code extension):

```shell
claude mcp add sonarqube --transport http https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/mcp --header "Authorization: Bearer <your-sonarqube-user-token>"
```

Replace `<your-sonarqube-user-token>` with the token from Step 2. This adds the server to your user-level Claude Code config.

If you'd rather edit the config file directly, note that Claude Code's format differs from VS Code's — the top-level key is `mcpServers`, not `servers`, and the server name has no `mcp/` prefix:

```json
{
  "mcpServers": {
    "sonarqube": {
      "type": "http",
      "url": "https://ca-sonarqube-mcp-dev.thankfulmoss-c6ccc4d1.eastus.azurecontainerapps.io/mcp",
      "headers": {
        "Authorization": "Bearer <your-sonarqube-user-token>"
      }
    }
  }
}
```

</details>

### Using it

Once configured, you can ask prompts such as:

`Show me the open issues for project my-project in SonarQube`

`What security hotspots are flagged in the latest analysis of my-project?`

`List code smells in the authentication module`

The SonarQube MCP will fetch analysis results from the internal SonarQube Server and surface them directly in your chat, helping you resolve issues without leaving your editor.

> **Using the Claude Code CLI non-interactively** (e.g. `-p`/print mode, or scripting): print mode can't show a permission-approval prompt at all, so a tool call will just fail with nothing to approve unless you pre-authorize it, e.g. `claude -p "..." --allowedTools mcp__sonarqube__*`. Interactive use (`claude` or `claude "..."`) doesn't need this — you'll get a normal approval prompt.

### If your token expires

An expired or invalid token shows up as a `401` error from the MCP. Generate a replacement using the same steps as Step 2, then update it in your `mcp.json` (VS Code) or re-run `claude mcp add` (Claude Code) with the new value.

For full deployment and operations details, see [docs/sonarqube-deployment.md](docs/sonarqube-deployment.md).

---
## 📂 Repository Structure
This repo follows the **MCP Registry Specification v0.1**. Because this is a static site, we use an `index.json` pattern:
* `/v0.1/servers/index.json` - The master list of available tools.
* `/v0.1/servers/mcp/[name]/versions/latest/index.json` - Specific execution logic for each tool.

## ⚙️ Operations & Maintenance
The SonarQube MCP is the first organization-managed MCP in this registry, requiring periodic updates by the IT/DevOps team.

| Document | Purpose |
| :--- | :--- |
| [docs/sonarqube-deployment.md](docs/sonarqube-deployment.md) | Azure Container Apps deployment guide for the SonarQube MCP Server |
| [docs/mcp-maintenance.md](docs/mcp-maintenance.md) | Monthly update and security review process for all MCPs in this registry |

## 🔐 Contribution Policy
1. All changes must be made via a **Feature Branch**.
2. A **Pull Request** is required for all merges into `main`.
3. Validate JSON syntax before merging to avoid breaking Copilot functionality for the entire organization.