---
title: Orbit - Prompt Repository
type: session-prompt-repository
status: active
tags: [orbit, opencode, prompts]
---

# Orbit Prompt Repository

This page contains standardized prompts for starting new OpenCode sessions. Each prompt is intentionally self-contained and directs the session to current repository evidence rather than relying on prior conversation context.

## Startup Intake

The project-level `opencode.json` selects the `orbit-session` primary agent. On a new session, that agent asks one question, `What do you want to do?`, with responses mapped to Prompts 1 through 6 below plus `Something Else`. The agent reads this Session Contract and the selected prompt after the response; it does not repeat the intake question on later turns or after compaction.

## Session Contract

Paste this block before any task-specific prompt.

```text
You are working on the Orbit QuickShell replacement for Noctalia in the Phleg Hyprland dotfiles repository.

Use the repository and the linked Orbit documentation as the source of truth. Do not rely on another session's conclusions, claims, screenshots, or implied plan without verifying them in the current worktree.

Before changing files:
1. Inspect git status, recent history, and the relevant files.
2. Read the applicable Orbit documentation pages, especially Orbit - Status, Orbit - Architecture, Orbit - Testing Strategy, Orbit - Issues and Corrections, and Orbit - Refactor Backlog.
3. Identify unrelated user changes and preserve them.
4. State the smallest implementation boundary and the verification you will run.

When a feature needs an external capability, first search for existing repository, distribution, desktop, QuickShell, Hyprland, or protocol tooling that already provides it. Prefer integrating and documenting an existing tool over creating a replacement. Record the exact source, version or commit, runtime/build dependencies, enablement method, ownership boundary, and fallback behavior. Do not add a new dependency until its necessity and validation path are clear.

If live Hyprland checks fail, compare `HYPRLAND_INSTANCE_SIGNATURE` with `hyprctl instances` before diagnosing Orbit. A terminal inherited from an older compositor instance may need the current signature exported for that test command.

While working:
- Prefer the smallest correct change.
- Do not mark behavior complete based only on generated configuration.
- Keep current evidence separate from historical notes.
- In normal interactive sessions, do not commit, amend, reset, or push unless
  explicitly requested. Prompt 7 is the exception: it explicitly authorizes
  `orbit-run-workers` (not an agent) to commit and push one independently
  verified manifest item directly to `main`. Agents still never stage, commit,
  amend, reset, stash, switch branches, or push.
- Use the project's existing test and documentation conventions.

At the end:
- Run the relevant deterministic checks.
- Run live or attended checks when the behavior requires them, or state exactly why they are blocked.
- Update the appropriate Orbit documentation page.
- Report changed files, verification results, unresolved risks, and any manual follow-up.
```

## Prompt 1: Parse Scratchpad Into Work

Use this to turn freeform observations into actionable project work.

```text
Read [[Orbit - Session Scratchpad]] and convert its current entries into actionable Orbit work.

For each observation:
1. Classify it as bug, feature, behavior clarification, test gap, documentation gap, refactor, or rejected idea.
2. Remove duplicates and distinguish symptoms from suspected causes.
3. Define the expected behavior and a reproducible observation or acceptance condition.
4. Assign an appropriate priority using the existing Orbit project order.
5. Add or update an issue in [[Orbit - Issues and Corrections]] when behavior is defective or uncertain.
6. Add implementation work to [[Orbit - Refactor Backlog]] or the relevant project status section.
7. Add or update a test-matrix entry when validation is needed.
8. Preserve the original scratchpad wording unless it is explicitly marked resolved.

Do not implement the work in this session unless I explicitly ask for implementation. Return a concise triage summary showing the source entry, classification, resulting documentation location, priority, and next action.
```

## Prompt 2: Work On One Feature

Use this when a specific feature should be implemented even if unrelated tests remain open.

```text
Before asking for a feature description, inspect the current Orbit backlog, open issues, test matrix, and desired behaviors. Present a concise numbered choice list of the open feature or correction items that are actionable, including each item's source ID, priority, and whether its contract must be defined before implementation. Let me choose one item, or describe a different feature.

Work only on this feature:

FEATURE:
[Describe one feature and the desired user-visible behavior.]

BOUNDARY:
[List what must not be changed in this session.]

Implement the feature independently of unrelated outstanding tests. Do not use unrelated failures as a reason to expand scope, and do not claim the entire Orbit project is complete because this feature works.

Follow the Orbit documentation standard:
1. Read the current status, architecture, issue, testing, and refactor pages relevant to this feature.
2. Inspect the current implementation and worktree before editing.
3. Define the feature's acceptance behavior and add or update its test-matrix entry.
4. Implement the smallest coherent change.
5. Add deterministic tests where practical.
6. Record manual, live, hardware, or blocked validation explicitly.
7. Update [[Orbit - Status]], [[Orbit - Issues and Corrections]], [[Orbit - Test Matrix]], or [[Orbit - Visual Validation Log]] as appropriate.

Do not fix unrelated issues discovered during inspection. Record them in [[Orbit - Session Scratchpad]] or the issue tracker and continue within the boundary.
```

## Prompt 3: Work The Ordered Development Backlog

Use this to process development work in deliberate priority order.

```text
Review [[Orbit - Status]], [[Orbit - Issues and Corrections]], [[Orbit - Refactor Backlog]], and [[Orbit - Test Matrix]]. Build the next-work queue using this order:

1. Safety, startup, session lifecycle, data loss, and recovery defects.
2. Reproducible behavior bugs that block a core Orbit surface.
3. Required validation and test gaps for already implemented behavior.
4. Structural refactors that reduce duplicated state ownership or runtime risk.
5. User-facing feature work.
6. Visual polish, cleanup, and showcase work.

Choose the highest-priority item that has enough evidence to act on. If the highest item is blocked, document the blocker and move to the next actionable item without silently reordering the backlog.

For the selected item:
- State why it is next.
- Define the smallest implementation boundary.
- Implement and verify it end to end.
- Update the issue, status, test matrix, and refactor backlog as appropriate.
- Stop after the selected item unless the next item is a direct prerequisite and I approve continuing.
```

## Prompt 4: Interactive And Stress Testing

Use this for attended validation, including deliberate user stress tests.

```text
Run an interactive validation session for this Orbit behavior:

BEHAVIOR:
[Name the surface and behavior to validate.]

SCENARIO:
[Describe the normal user flow.]

STRESS CASES:
[List rapid input, repeated open/close, focus changes, monitor changes, cancellation, failure, or recovery actions to attempt.]

Do not modify configuration or system state beyond the stated test scenario. Before testing, read the relevant test-matrix entry and issue history, inspect the current session prerequisites, and confirm how to return to a safe state.

For every case record:
- exact steps;
- expected result;
- actual result;
- timing or repetition count when relevant;
- logs, screenshots, client/workspace state, or service state;
- PASS, FAIL, BLOCKED, or SKIP;
- a new issue or correction when the result is not an unambiguous pass.

Include user stress tests such as rapid repeated input, interruption during animation, focus changes during launch, repeated cancellation, and recovery after an intentional safe failure when applicable. Do not convert an observed quirk into a fix during the same test run unless explicitly requested.

Update [[Orbit - Test Matrix]], [[Orbit - Issues and Corrections]], and [[Orbit - Visual Validation Log]] with the results.
```

## Prompt 5: Documentation, Testing, Git, And Tracking Cleanup

Use this for a bounded maintenance session.

```text
Clean up the Orbit project's documentation, testing records, Git state, and tracking without changing product behavior unless required to correct documentation or test infrastructure.

Inspect:
- git status and diff, including unrelated dirty files;
- all Orbit documentation pages;
- test runners, contract tests, live tests, soak tests, and manual test definitions;
- issue, status, test-matrix, refactor, and change-log consistency.

Perform these steps:
1. Find stale claims, duplicate entries, obsolete paths, invalid test IDs, and evidence that is recorded in the wrong place.
2. Separate historical evidence from current evidence.
3. Normalize terminology and PASS/FAIL/BLOCKED/MANUAL/SKIP states.
4. Ensure every open defect has a clear next action and every completed claim has evidence.
5. Repair documentation or test tracking only; do not opportunistically refactor product code.
6. Preserve unrelated user changes and do not discard or normalize them.
7. Run the deterministic tests and any safe static checks.

Do not commit or alter Git history. Report any dirty files that appear unrelated, any claims that cannot be verified, and any remaining tracking inconsistencies.
```

## Prompt 6: Interactive Session Scratchpad Logging

Use this for an attended session where the user reports observed Orbit behavior one item at a time and the session records it in the Session Scratchpad.

```text
Run an interactive observation-logging session for Orbit.

Use [[Orbit - Session Scratchpad]] as the recording format and source of truth for the observations collected in this session. Do not implement fixes, assign root causes, or triage observations into the issue tracker unless I explicitly ask.

For each behavior I describe:
1. Decide whether it is one observation or needs to be separated into multiple independently reproducible observations.
2. Ask only the focused follow-up questions needed to fill the Scratchpad template: surface, trigger or steps, expected behavior, actual behavior, frequency, severity impression, evidence, and related issue or test ID when known.
3. Keep current evidence separate from historical notes and preserve the user's original meaning.
4. Append the completed observation to [[Orbit - Session Scratchpad]] using its established format.
5. Perform a structural/documentation check of the new entry. Do not run product tests unless a behavior is being actively validated.
6. After logging it, ask for the next observed behavior.

Do not ask the user to provide every template field up front. Use a short, sequential dialogue. Do not infer an implementation cause from symptoms. Preserve existing Scratchpad entries and unrelated dirty-worktree changes. If the user supplies evidence such as a recording, screenshot, log, timestamp, or command output, reference it directly in the entry.
```

## Prompt 7: Autonomous Single-Item Worker

Use this only through `orbit-run-workers`. Selection/planning, execution,
deterministic verification, and publication are separate phases and every
agent invocation is a fresh session. Sol audits project phase boundaries and
manually implemented high-risk work, not every routine Luna item.

```text
Read [[Orbit - Agent Workflows]] and obey the sealed `.local/state/orbit/item-manifest.json`.

The selector, not the worker, uses Prompt 3 and the current Orbit pages to choose one item. The supervisor stamps the source-file SHA-256, baseline tree, base commit, exact allowed paths, test IDs, risk, acceptance conditions, and plan. Execute exactly that preselected item. Do not infer a different priority from Markdown, choose another item, broaden scope, or edit a path that is not explicitly allowed.

Luna may execute only bounded low- or medium-risk work. High-risk or manual-only work must halt for a manually started `orbit-sol-implementation` session. Preserve the supervisor's starting dirty manifest. Do not stage, commit, push, reset, stash, or switch branches; the supervisor owns Git after independent verification.

Never mutate the active display, graphical/login session, network configuration, audio, Bluetooth, or power state, including reload/restart/toggle/apply/logout/suspend/reboot paths. Such mutation is permitted only in a disposable environment that cannot affect the active environment. Deterministic and read-only checks are preferred; attended, visual, hardware, causal, and recovery gates go to [[Orbit - Validation Queue]].

A judged-safe package install is allowed for medium-risk work. Record the package manager, exact command, package, operation, resolved version, and result before and after the change. Record every sudo command verbatim. Never use an external paid model provider or extra credits.

If a manual gate remains, append exactly one complete READY entry whose source is `source_ref` and which includes `source_sha256`. Never refresh or duplicate an existing READY source. Include the exact environment, prerequisites, safe reset, numbered steps, expected result, automated evidence, remaining gate, and evidence to capture.

As the final operation, write strict JSON to `.local/state/orbit/worker-result.json`. It must contain schema version, `COMPLETED` or `BLOCKED`, item ID, source SHA-256, risk, every and only changed file, all manifest test IDs, exact command/exit/evidence records, queue state/source/entry ID, exact package changes, every sudo command, and a blocker or null. Do not start another item or session.
```

## Prompt 8: Sequential Validation Approval

Use this in a fresh session to consume the validation queue.

```text
Read [[Orbit - Agent Workflows]], [[Orbit - Validation Queue]], [[Orbit - Test Matrix]], [[Orbit - Issues and Corrections]], and [[Orbit - Visual Validation Log]]. Process exactly one READY queue entry at a time.

Present only the next entry's environment, prerequisites, safe reset, exact steps, expected result, and evidence to capture. Wait for my response. Accept exactly one outcome: PASS (works as intended), PASS-WITH-NOTE (works but record an improvement), FAIL (does not work), or BLOCKED (cannot safely test). Do not implement fixes, infer causes, or run unrelated tests during this approval session.

Record the result in the queue and update the applicable test matrix, issue tracker, visual log, status, backlog, or scratchpad. Preserve the user's wording and evidence. Then present the next READY entry. Stop when the queue is empty or a destructive/safety decision needs explicit confirmation.
```

## Prompt 9: Manual High-Risk Sol Implementation

Use this only after the supervisor emits `MANUAL_ONLY` and prints the manual
Sol entrypoint.

```text
Use the `orbit-sol-implementation` agent with the explicitly selected, locally included Sol model. Read the sealed item manifest and confirm its item ID, exact allowed paths, risk, rollback, and verification boundary with me before editing.

Implement only that manifest. Active display, graphical/login session, network, audio, Bluetooth, and power mutation remains prohibited and may occur only in an explicitly disposable environment that cannot affect the active environment. Record every package and sudo change exactly. Do not use a paid external provider or extra credits. Do not stage, commit, reset, stash, switch branches, or push.

Write the same strict `worker-result.json` required by Prompt 7 with `risk: high`. Then stop and tell me to run the exact `orbit-run-workers --auto --resume-sol ...` command printed during selection. The supervisor will independently run deterministic project validation, request a second read-only Sol audit, inspect scope, and only then commit and push the one item to `main`.
```

## Prompt Maintenance Rules

- Keep stable context in the Session Contract, not in individual prompts.
- Keep task-specific facts in repository documents, not in prompt text.
- Never include a previous session transcript as background by default.
- Add a new prompt only when a recurring workflow cannot be expressed by the existing templates.
- Version meaningful prompt changes in [[Orbit - Change Log]].
