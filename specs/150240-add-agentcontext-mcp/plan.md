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

## Registry entry design: full entry, mirroring SonarQube

Unlike Figma/SonarQube/Angular, AgentContext already ships its own onboarding tool: `agentcontext-cli init-repo` (Node CLI, installed from GitHub Packages under the `@senecaglobalinc` scope). Per the setup wiki, running it and selecting **"Copilot (VS Code)"** at the tool-selection step already scaffolds, per-repo: `.vscode/mcp.json`, `.github/copilot-instructions.md`, and `.agents/skills/` (5 skills) — prompting the developer for the MCP server URL and repo token interactively, and gitignoring the generated files.

The SonarQube plan's verification-step notes originally recorded that VS Code's `@mcp` installer didn't honor a registry entry's `headers`/`variables` block. **That finding was stale** — Walter re-tested it since and confirmed VS Code does correctly prompt for and persist the token via that mechanism. (The SonarQube plan.md on `main` still states the old negative finding — worth a follow-up correction there so it doesn't mislead the next reader, separately from this branch.)

With that corrected, **full entry it is**: build `v0.1/servers/mcp/agentcontext/versions/latest/index.json` with a `remotes[].headers[]` block parameterized exactly like SonarQube's — one variable for `X-AgentContext-Token` (the per-repo secret) and one for `X-AgentContext-Actor` (developer email) — so installing via `@mcp` in Copilot actually prompts for both and writes a working `.vscode/mcp.json`, same as SonarQube's bearer token does today. This keeps the registry as the single consistent "go here for everything" source of truth across every approved server, and it now genuinely works rather than being decorative. `agentcontext-cli init-repo` remains the documented path for Claude Code (and Cursor/Codex, which aren't gated by this registry anyway) — the two aren't mutually exclusive, they just serve different clients.

## Decisions confirmed so far

- **Governance status:** AgentContext is already `🟢 Approved` org-wide in [Appendix A](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/636/Appendix-A-MCP-Server-Registry-Status-Definitions) (no BAA/zero-training writeup needed, unlike Form.io/SyncFusion) — but the **Permitted for Local Use**, **MCP Registry Status**, and **Network Boundary** columns are still `TBD`. Closing out issue #14 means filling those in, not re-litigating approval.
- **Network boundary:** internal IP (`10.150.3.4`), VPN/office-network required — matches the existing "internal-only" pattern we already have precedent for (SonarQube), so no new governance argument needed, just documentation.
- **Auth shape:** two headers, `X-AgentContext-Actor` (developer email) and `X-AgentContext-Token` (per-repo secret from the `agentcontext-handler` admin UI) — not a single shared bearer token.
- **`agentcontext-handler` admin access is not a blocker.** Its role is provisioning — issuing/revoking per-repo tokens — and doesn't affect the registry-entry design. Separately, tokens for a number of repos (disclosure-report, mcr-net, template-builder, etc.) already exist on the Repo Tokens wiki page, so additional local `agentcontext-cli init-repo` test runs don't need to wait on Walter's admin access coming through.
- **Repo Tokens wiki page stays as-is.** Reviewed and decided: it sits behind Azure DevOps auth, so cleartext tokens there don't create exposure — the actual risk this plan guards against is a token leaking into something *this repo publishes* (the public GitHub Pages site), not the ADO wiki itself.
- **Copilot's connection is gated by this registry, full stop — there's no way to test it pre-registration.** GitHub's org-level Copilot MCP policy (the README's "Registry Only" enforcement) only permits servers listed in this registry; unlike Claude Code (which reads `.mcp.json` directly, no registry involved), Copilot cannot attempt a connection to AgentContext until *something* — stub or full entry — exists here. That fixes the sequencing: build an entry → preview it live by pointing GitHub Pages at this branch (as planned) → test Copilot for real → then merge. It does not, on its own, decide which shape the entry should be.

## Open questions to resolve before/while implementing

- [x] ~~Stub vs. full-entry?~~ **Full entry**, mirroring SonarQube's `headers[].variables` shape — see design section above. Depended on correcting the stale "VS Code doesn't honor headers" finding.
- [x] ~~Does `agentcontext-handler` need to be looped in?~~ No — provisioning-only, not a design dependency, and tokens for test repos are already available without it.
- [x] ~~Should the Repo Tokens wiki page move?~~ No — staying behind ADO auth is sufficient; not this repo's exposure surface.
- [ ] Confirm current rollout state across repos: in progress — about to run `agentcontext-cli init-repo` (Claude Code) against a second repo using an existing Repo Tokens value, to confirm the `.mcp.json` shape is consistent (same URL, differing only by token/actor) before relying on that assumption in the registry entry.

## Task List & Estimates

| # | Task | Estimate |
|---|---|---|
| 1 | Run `agentcontext-cli init-repo` (Claude Code) on a second repo using an existing Repo Tokens value; diff its `.mcp.json` against `mycm.net`'s to confirm the pattern | 15–30 min |
| 2 | Update [Appendix A](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/636/Appendix-A-MCP-Server-Registry-Status-Definitions)'s AgentContext row: fill in Permitted for Local Use / MCP Registry Status / Network Boundary | 15 min |
| 3 | Add `v0.1/servers/mcp/agentcontext/versions/latest/index.json` + master `v0.1/servers/index.json` entry: full `remotes[].headers[]` block with two parameterized variables (`X-AgentContext-Token`, `X-AgentContext-Actor`), mirroring SonarQube's schema exactly | 0.5–1 day |
| 4 | README.md: add an "AgentContext" section (Current Integrations table row + usage instructions), following the existing per-server section pattern | 0.5 day |
| 5 | Verify no literal token/secret anywhere in the diff before commit (see Secret handling note above) | 15 min, every commit |
| 6 | Point GitHub Pages at this branch (temporarily) so the entry is actually live for testing, per the Copilot-gating note above | 15 min |
| 7 | Functional verification (see below) | 0.5 day |
| 8 | Follow-up (separate/optional): correct the stale VS Code/headers finding in `specs/134516-sonarqube-mcp-server/plan.md` on `main` | 15 min |

## Verification Steps

1. **Registry correctness** — JSON validates against the MCP server schema; `@mcp` search in VS Code Copilot surfaces the AgentContext entry and prompts for both header variables on install.
2. **No secrets committed** — `git log -p` / `git diff origin/main` for this branch contains no literal token, no literal `X-AgentContext-Token` value, no internal IP treated as sensitive beyond what's already documented for SonarQube's equivalent internal-only pattern.
3. **Functional connection (Copilot)** — only possible once the entry is live on the branch-pointed Pages site (see task 7 — Copilot has no path to test this pre-registration). A developer with their own repo token gets GitHub Copilot in VS Code to successfully call `get_layered_context` against a real repo and see real layered context returned (not just a tool-discovery listing).
4. **Appendix A reflects reality** — the three `TBD` columns for AgentContext are filled in and match what was actually implemented.
