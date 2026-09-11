# Add AgentContext MCP to the Registry (GitHub Copilot)

> Tracked by NWOW work item **#150240 - Add AgentContext MCP to registry**, with the actual work tracked via GitHub issue **[#14](https://github.com/ComplianceLineLLC/mcp-registry/issues/14)** in this repo. Follows the `specs/<work-item-id>-<slug>/` folder convention established for SonarQube (`specs/134516-sonarqube-mcp-server/`), without adopting the full spec-kit tool scaffolding.

## Context

AgentContext (developed by Seneca Global, hosted internally by Ethico) is a layered-context / "AI-native engineering" knowledge server: a repo calls `get_layered_context` and related tools to pull constitution → org → project → repo rules plus recorded learnings into the assistant's context, and can write learnings back via `save_learning`. It's already wired up and working for **Claude Code** in at least this repo (`mycm.net`) via a local, gitignored `.mcp.json`. Issue #14 asks us to make the same server available to **GitHub Copilot** through this registry, so any repo can pick it up the same way Copilot users already pick up Figma/SonarQube/etc.

Two reference docs on the Ethico wiki cover this:
- [Setup — AgentContext MCP](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/736/Setup-%E2%80%94-AgentContext-MCP) — the `agentcontext-cli` developer setup guide
- [Repo Tokens](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/738/Repo-Tokens) — the per-repo token list (treat as a secrets page — see note below)

## What's already proven working (Claude Code, this repo)

`mycm.net/.mcp.json` (gitignored, not committed) currently looks like:

```json
{
  "mcpServers": {
    "agentcontext-knowledge": {
      "type": "http",
      "url": "http://10.150.3.4/mcp",
      "headers": {
        "X-AgentContext-Actor": "<developer email>",
        "X-AgentContext-Token": "<this repo's token>"
      }
    }
  }
}
```

So the real architecture is: **internal-only HTTP remote** (`10.150.3.4`, VPN/office-network required — same network-boundary shape as our SonarQube self-hosted entry, just plain HTTP instead of an Azure Container App behind HTTPS), authenticated with two custom headers — an actor identity (developer email, for audit attribution) and a **per-repo** token (not per-developer — see Repo Tokens page). This is a meaningfully different auth shape than SonarQube/Figma (per-developer bearer token, one shared server URL); here the secret varies **by repo**, not by person.

**⚠️ Secret handling:** the Repo Tokens wiki page lists live token values in cleartext. This repo's registry output is published to a **public** GitHub Pages site (`compliancelinellc.github.io/mcp-registry`). No literal token value may ever appear in any committed file here (`index.json`, README, docs, this plan) — only placeholder variables, exactly like the existing SonarQube entry does for its bearer token. This is also non-overridable per the org constitution (C-001: no literal secrets in code).

## Open design question — what does "Copilot support" actually mean here?

Unlike Figma/SonarQube/Angular, AgentContext already ships its own onboarding tool: `agentcontext-cli init-repo` (Node CLI, installed from GitHub Packages under the `@senecaglobalinc` scope). Per the setup wiki, running it and selecting **"Copilot (VS Code)"** at the tool-selection step already scaffolds, per-repo: `.vscode/mcp.json`, `.github/copilot-instructions.md`, and `.agents/skills/` (5 skills) — prompting the developer for the MCP server URL and repo token interactively, and gitignoring the generated files. That's a complete, working Copilot onboarding path that bypasses this registry entirely.

Meanwhile, SonarQube's own plan/history (`specs/134516-sonarqube-mcp-server/plan.md`, verification step #6 notes) already established that VS Code's `@mcp` gallery installer does **not** auto-populate a registry entry's `headers`/`variables` block — a manual `mcp.json` edit was the only method that actually worked, even after conforming to the official schema.

So there are two real options, and this needs a decision before task work starts, not after:

1. **Registry entry is a documentation/discovery stub.** Add a minimal `mcp/agentcontext` entry (so it's discoverable via `@mcp` search / listed in Appendix A) whose description points developers at running `agentcontext-cli init-repo` and selecting Copilot — i.e., the registry doesn't try to carry the real connection config at all, since the CLI already does that per-repo, per-token, more completely than a static registry entry could (it also handles the actor-email header, the migration-detection step, and the Codex/Cursor cases we don't need here).
2. **Registry entry mirrors the SonarQube pattern** (`remotes[].headers[].variables`, parameterized, no literal secret) even knowing it likely won't auto-populate `mcp.json`, purely so the entry exists for consistency with every other approved server and for Appendix A linkage — with the README documenting the manual-edit fallback exactly like SonarQube's does.

Option 1 avoids duplicating a mechanism that already works and is arguably more correct (it doesn't misrepresent a per-repo-secret server as a generic per-developer one); option 2 keeps the registry as the single "go here for everything" source of truth developers are told to use. **Recommendation: option 1**, given the CLI is already the documented, working install path and per-repo (not per-developer) tokens don't fit the registry's existing header/variable model as cleanly — but this is worth confirming before doing the JSON work, since it changes what task 3 below actually produces.

## Decisions confirmed so far

- **Governance status:** AgentContext is already `🟢 Approved` org-wide in [Appendix A](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/636/Appendix-A-MCP-Server-Registry-Status-Definitions) (no BAA/zero-training writeup needed, unlike Form.io/SyncFusion) — but the **Permitted for Local Use**, **MCP Registry Status**, and **Network Boundary** columns are still `TBD`. Closing out issue #14 means filling those in, not re-litigating approval.
- **Network boundary:** internal IP (`10.150.3.4`), VPN/office-network required — matches the existing "internal-only" pattern we already have precedent for (SonarQube), so no new governance argument needed, just documentation.
- **Auth shape:** two headers, `X-AgentContext-Actor` (developer email) and `X-AgentContext-Token` (per-repo secret from the `agentcontext-handler` admin UI) — not a single shared bearer token.

## Open questions to resolve before/while implementing

- [ ] Which of the two options above (registry-as-stub vs. registry-as-full-entry)?
- [ ] Does the `agentcontext-handler` admin UI (or its owner) need to be looped in for anything, or is this purely a documentation/registry task on our side?
- [ ] Should the Repo Tokens wiki page move somewhere with tighter access control, given it's a live cleartext-secrets list? (Out of scope for this issue, but worth flagging to whoever owns that wiki space.)
- [ ] Confirm current rollout state: is Claude Code's `.mcp.json` pattern (seen in `mycm.net`) already replicated across other repos, or is `mycm.net` the only one so far?

## Task List & Estimates

| # | Task | Estimate |
|---|---|---|
| 1 | Resolve the open design question above (stub vs. full entry) | 15–30 min (conversation, not build) |
| 2 | Update [Appendix A](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/636/Appendix-A-MCP-Server-Registry-Status-Definitions)'s AgentContext row: fill in Permitted for Local Use / MCP Registry Status / Network Boundary | 15 min |
| 3 | Add `v0.1/servers/mcp/agentcontext/versions/latest/index.json` + master `v0.1/servers/index.json` entry, per whichever shape task 1 decides | 0.5–1 day |
| 4 | README.md: add an "AgentContext" section (Current Integrations table row + usage instructions), following the existing per-server section pattern | 0.5 day |
| 5 | Verify no literal token/secret anywhere in the diff before commit (see Secret handling note above) | 15 min, every commit |
| 6 | Functional verification (see below) | 0.5 day |

## Verification Steps

1. **Registry correctness** — JSON validates against the MCP server schema; `@mcp` search in VS Code Copilot surfaces the AgentContext entry (if task 1 chose the full-entry option).
2. **No secrets committed** — `git log -p` / `git diff origin/main` for this branch contains no literal token, no literal `X-AgentContext-Token` value, no internal IP treated as sensitive beyond what's already documented for SonarQube's equivalent internal-only pattern.
3. **Functional connection (Copilot)** — following whatever path task 1 settles on, a developer with their own repo token can get GitHub Copilot in VS Code to successfully call `get_layered_context` against a real repo and see real layered context returned (not just a tool-discovery listing).
4. **Appendix A reflects reality** — the three `TBD` columns for AgentContext are filled in and match what was actually implemented.
