# Evaluate Form.io MCP for the Registry

> Tracked by NWOW work item **#150241 - Add Form.io MCP**, with the actual work tracked via GitHub issue **[#15](https://github.com/ComplianceLineLLC/mcp-registry/issues/15)** in this repo. Follows the `specs/<work-item-id>-<slug>/` folder convention established for SonarQube (`specs/134516-sonarqube-mcp-server/`).

## Context

The development team requested a Form.io MCP server. The GitHub issue carries no further detail on which server, why it's needed, or what it would be used for — this is a request, not a scoped, approved piece of work.

Per [Appendix A: MCP Server Registry & Status Definitions](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/636/Appendix-A-MCP-Server-Registry-Status-Definitions), Form.io's current governance status is **`New`** — not even `Under Review` yet. **No implementation work should start on this branch until governance status moves to `Approved`.** This plan.md is deliberately an evaluation checklist, not a build plan — mirroring how the wiki itself documents an in-progress evaluation (see the Postman section of Appendix A for the shape a completed "Under Review → pending items" writeup takes).

## Before this can move to `Approved`

Per the [AI Context Integration (MCP) Governance Policy](https://dev.azure.com/Ethico/NWOW/_wiki/wikis/NWOW.wiki/634/AI-Context-Integration-(MCP)-Governance-Policy) §3, every item below must be verified and documented — not assumed — before Form.io can be added to the live registry:

- [ ] **Zero-Training Guarantee** — find and cite Form.io's (or the specific MCP server implementation's) terms of service / privacy policy stating our data (code, file structure, prompts, query results) will not be used to train/retrain any model.
- [ ] **Data Protection & HIPAA/BAA** — determine whether the intended use touches PHI or sensitive compliance data. If it does (e.g. an MCP that reads live Form.io form submissions rather than just form *schema*/design-time definitions), a Business Associate Agreement is required before approval.
- [ ] **Local-First Execution** — determine whether a Form.io MCP implementation exists that runs as a local process (npx/docker) vs. one that calls Form.io's cloud API directly. Local-first is a stated preference, not an absolute requirement, but the cloud-API case (like Postman's) needs the BAA question answered first.
- [ ] **Least Privilege** — if approved, confirm the server can be run read-only (schema/definition access only, no write access to live form data) unless a specific use case justifies more.
- [ ] **What is this actually for?** — the issue has no stated use case. Before spending further evaluation effort, get a concrete answer from whoever requested it (the development team, per the issue body) — this determines which Form.io MCP implementation (if more than one exists) is even the right candidate, and whether the requested capability is design-time (Form Builder / AUF schema authoring — see `mycm.net`'s `template-builder` / AUF domain) or data-access (submitted disclosure responses).

## Decisions confirmed so far

- None. This item has had no research beyond the raw feature request.

## Task List & Estimates

| # | Task | Estimate |
|---|---|---|
| 1 | Get a concrete use case from the requesting team | — (blocking, not effort-estimable) |
| 2 | Identify candidate Form.io MCP server implementation(s) | 0.5 day |
| 3 | Research and document the governance checklist above | 0.5–1 day |
| 4 | Update Appendix A's Form.io section with findings (status stays `New`/`Under Review` until resolved, or moves to `Approved`/`Rejected`) | 15–30 min |
| 5 | **Only if approved:** scope actual registry/implementation work — not estimated here, since it depends entirely on which server and which network boundary (local subprocess vs. remote) the evaluation lands on | TBD |

## Verification Steps

Not applicable yet — no implementation exists to verify. Re-visit once the governance checklist above is resolved.
