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
- **Copilot's connection is gated by this registry — now confirmed by a live test, not just policy inference.** GitHub's org-level Copilot MCP policy (the README's "Registry Only" enforcement) only permits servers listed in this registry; unlike Claude Code (which reads `.mcp.json` directly, no registry involved), Copilot cannot attempt a connection to AgentContext until *something* — stub or full entry — exists here. That fixes the sequencing: build an entry → preview it live by pointing GitHub Pages at this branch (as planned) → test Copilot for real → then merge. It does not, on its own, decide which shape the entry should be.

## Live test (2026-09-11): CLI-only Copilot config does not work — registry entry is load-bearing

Ran `agentcontext-cli init-repo` (selecting Copilot) in `mcr.net` and `disclosurereport`, then tested GitHub Copilot Chat directly against a correctly-populated `.vscode/mcp.json` (single-folder VS Code window, `Chat` tab confirmed active — not the separate `Claude Code` extension tab, which was the first false start):

- Copilot's response: *"I couldn't call `get_layered_context`; the AgentContext MCP tool isn't available in this session."*
- Its own "servers with unstarted tools" banner named `Foundry MCP` and `mcp/azure-devops` (both registry-approved) — **`agentcontext-knowledge` wasn't listed at all**, even though `.vscode/mcp.json` genuinely declares it.

This is a clean result (first attempt was invalidated by testing in `mycm.net`, which never had `.vscode/mcp.json` populated for Copilot at all — only `.mcp.json` for Claude Code — so that run proved nothing). The `mcr.net` retest is conclusive: **Copilot filters out non-registry servers before they're even offered as startable**, not just from `@mcp` search. So the CLI's Copilot scaffolding is currently correct but functionally inert — it cannot do anything for Copilot until this registry actually carries the entry. This resolves the earlier open question in favor of the registry being genuinely required (not just a discoverability nicety), and raises the priority of tasks 3/6 below.

**Side finding, unproven but worth flagging:** the CLI names the server identically (`agentcontext-knowledge`) in every repo's `.vscode/mcp.json`/`.mcp.json`. A developer with more than one AgentContext-enabled repo open in the same multi-root VS Code workspace would have three same-named server definitions with three different repo tokens — untested what VS Code/Copilot actually does in that case (silently pick one? error? merge?). Not blocking this issue, but worth a note for whoever owns the CLI if it comes up later.

## Open questions to resolve before/while implementing

- [x] ~~Stub vs. full-entry?~~ **Full entry**, mirroring SonarQube's `headers[].variables` shape — see design section above. Depended on correcting the stale "VS Code doesn't honor headers" finding.
- [x] ~~Does `agentcontext-handler` need to be looped in?~~ No — provisioning-only, not a design dependency, and tokens for test repos are already available without it.
- [x] ~~Should the Repo Tokens wiki page move?~~ No — staying behind ADO auth is sufficient; not this repo's exposure surface.
- [x] ~~Confirm current rollout state across repos.~~ Done — ran the CLI (both Claude Code and Copilot options) against `mcr.net` and `disclosurereport`. Pattern is consistent: same URL, differing only by `X-AgentContext-Token`/actor; `CLAUDE.md` gets appended to (not overwritten) via an `<!-- agentcontext:managed -->` marker block. See the live-test section above for the Copilot-specific finding this surfaced.

## Task List & Estimates

| # | Task | Estimate |
|---|---|---|
| 1 | ~~Run `agentcontext-cli init-repo` on a second repo~~ — **Done**, see live-test section above | ~~15–30 min~~ |
| 2 | ~~Update Appendix A's AgentContext row~~ — **Done.** Table row filled in (`Yes (Internal Network Only — VPN/Office Required)` / `Implementation Pending` / `Internal Network (VPN-Restricted)`); full section written with Architecture and Data Boundary, an explicit **Zero-Training Guarantee carve-out** (no vendor citation exists — accepted because the deployment never leaves Ethico's internal network, same rationale as SonarQube's Self-Hosted carve-out), Authentication model, and Security Hardening subsections | ~~15 min~~ |
| 3 | ~~Add the registry entry~~ — **Done.** `v0.1/servers/mcp/agentcontext/versions/latest/index.json` (per-version file) and a matching entry in the master `v0.1/servers/index.json` (count bumped 7→8), both with a full `remotes[].headers[]` block parameterized exactly like SonarQube's — two variables, `agentcontext_repo_token` (secret) and `agentcontext_actor_email`. Both files validated as parseable JSON; grepped for the real token/email values from local testing — clean, only placeholders present | ~~0.5–1 day~~ |
| 4 | ~~README.md: add an "AgentContext" section~~ — **Done.** Current Integrations table row, plus a full section mirroring SonarQube's format (network setup, getting a repo token, VS Code/Copilot connect steps with manual-header fallback, agentcontext-cli path for Claude Code/Cursor/Codex, example prompts) | ~~0.5 day~~ |
| 5 | ~~Verify no literal token/secret anywhere in the diff before commit~~ — **Done for every commit so far** (grepped each one against the real token/email values seen during local testing — clean throughout); still worth a final check before merge | ~~15 min, every commit~~ |
| 6 | ~~Point GitHub Pages at this branch~~ — **Done.** Walter switched Pages to `14-add-agentcontext-mcp`; confirmed live via direct curl against the published URLs (fresh `Last-Modified`, `count: 8`, `mcp/agentcontext` present, no secrets, only placeholders) before any VS Code testing | ~~15 min~~ |
| 7 | ~~Functional verification~~ — **Done, fully.** See Verification Steps below | ~~0.5 day~~ |
| 8 | Follow-up (separate/optional): correct the stale VS Code/headers finding in `specs/134516-sonarqube-mcp-server/plan.md` on `main` | 15 min |

## Verification Steps

1. **Registry correctness** — ✅ Confirmed. JSON validates; live curl against the published Pages URL showed `mcp/agentcontext` present with correct schema.
2. **No secrets committed** — ✅ Confirmed on every commit so far via grep against the real token/email values seen during local testing. Worth one final check before merge.
3. **Functional connection (Copilot)** — ✅ **Confirmed, fully.** In `mcr.net` (single-folder window), the output log showed `mcp/agentcontext` starting and discovering 11 tools — itself notable, since Copilot never even offered to start this server before the registry entry existed (see the earlier live-test section). Then a real Copilot Chat prompt ("What does get_layered_context say about this repo?") triggered an actual `get_layered_context` call with `repo_id: "mcr-net"` and returned correct, repo-specific content (MCR.net's real architecture, the ADO 93877 follow-up bug, its no-real-auth finding, org/project/repo rule layers, zero conflicts) — a genuine tool call with a correct answer, not just a tool-discovery listing. This closes the loop the SonarQube plan was careful to distinguish (a raw handshake isn't the same as a real client getting a real result) — here we have the real result.
4. **Appendix A reflects reality** — ✅ Confirmed. Walter updated the wiki page directly with the drafted content (table row + full section, including the Zero-Training carve-out).

**All four verification steps pass. AgentContext is confirmed working end-to-end for GitHub Copilot via this registry.** Remaining before merge: task 8 (optional SonarQube plan.md correction, separate from this issue) and deciding when/how to merge this branch to `main` and point Pages back.
