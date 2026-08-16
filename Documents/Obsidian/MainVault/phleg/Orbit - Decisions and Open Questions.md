---
title: Orbit - Decisions and Open Questions
type: decision-log
tags: [orbit, decisions]
---

# Decisions And Open Questions

## Decisions

| Decision | Rationale |
| --- | --- |
| Orbit is the only shell autostart | Avoid duplicate shell ownership and stale IPC races. |
| XMB is focused-monitor layer-shell | It must not consume or own a workspace. |
| Stable monitor identity is preferred | Connector names are hardware fallback data only. |
| Dynamic workspaces remain policy-driven | One application/process tree per workspace is the current model. |
| Tests separate generated state from observed behavior | Configuration success is not runtime proof. |

## Open Questions

- Should the historical `noctalia.*` theme adapter filenames be renamed now or in a dedicated compatibility migration?
- Which notification and top-bar responsibilities must Orbit replace before Noctalia can be removed entirely?
- Should application grouping support multiple meaningful windows per desktop entry?
- Which settings can be safely exposed without Lua rules?
- How should conflicting desktop-entry and observed classes be presented?
- What is the safe display rollback design?
