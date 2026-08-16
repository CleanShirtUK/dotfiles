---
title: Orbit - Prompt Repository
type: session-prompt-repository
status: active
tags: [orbit, opencode, prompts]
---

# Orbit Prompt Repository

This page contains standardized prompts for starting new OpenCode sessions. Each prompt is intentionally self-contained and directs the session to current repository evidence rather than relying on prior conversation context.

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

If live Hyprland checks fail, compare `HYPRLAND_INSTANCE_SIGNATURE` with `hyprctl instances` before diagnosing Orbit. A terminal inherited from an older compositor instance may need the current signature exported for that test command.

While working:
- Prefer the smallest correct change.
- Do not mark behavior complete based only on generated configuration.
- Keep current evidence separate from historical notes.
- Do not commit, amend, reset, or push unless explicitly requested.
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

## Prompt Maintenance Rules

- Keep stable context in the Session Contract, not in individual prompts.
- Keep task-specific facts in repository documents, not in prompt text.
- Never include a previous session transcript as background by default.
- Add a new prompt only when a recurring workflow cannot be expressed by the existing templates.
- Version meaningful prompt changes in [[Orbit - Change Log]].
