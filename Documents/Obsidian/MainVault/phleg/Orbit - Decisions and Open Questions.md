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
| Orbit 1.0 includes the full accepted scratchpad vision and the completed three-repository split | Product scope and repository ownership are both release requirements. |
| Stabilization precedes feature work | Current runtime regressions and applicable validation gates must be resolved before expanding behavior. |
| Display changes use prepare/apply/verify/rollback | Transactional file and observed-topology snapshots provide the implemented recovery boundary; real two-monitor recovery remains an attended gate. |
| Global menus use available transport with honest fallback | XWayland DBusMenu and native-Wayland AT-SPI paths are implemented; applications without a usable menu expose fallback actions rather than fabricated menu entries. |
| Verified items integrate directly to `main` one at a time | Independent verification precedes an item-scoped commit and push; unrelated work is not batched. |
| The machine-readable manifest is canonical | `orbit/project-manifest.json` owns project/work-item state; Markdown is the validated human view. |

## Open Questions

- Should the historical `noctalia.*` theme adapter filenames be renamed now or in a dedicated compatibility migration?
- Which notification and top-bar responsibilities must Orbit replace before Noctalia can be removed entirely?
- Should application grouping support multiple meaningful windows per desktop entry?
- Which settings can be safely exposed without Lua rules?
- How should conflicting desktop-entry and observed classes be presented?
- Which GTK4 and Electron applications can expose a usable accessibility menu, and which must retain fallback actions?
- What evidence and tooling are required to prove each repository is independently installable and reproducible before the Orbit 1.0 split is declared complete?
