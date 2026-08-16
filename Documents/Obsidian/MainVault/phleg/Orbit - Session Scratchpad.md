---
title: Orbit - Session Scratchpad
type: session-input
status: active
tags: [orbit, observations, scratchpad]
---

# Orbit Session Scratchpad

Use this page for raw observations before they are triaged. Write naturally. Do not spend time assigning IDs, choosing implementation details, or deciding whether something is a bug. A new session can parse these entries with the prompt in [[Orbit - Prompt Repository]].

## How To Use

- Add one observation per entry.
- Include the surface, action, and what seemed wrong or desirable when known.
- Mark an entry `Resolved` only after the behavior is verified and recorded elsewhere.
- Do not delete the original wording when an entry is triaged.
- Put screenshots, logs, timestamps, and reproduction clues directly in the entry.

## Entry Template

```markdown
### OBS-YYYYMMDD-## Short observation
- Status: New
- Surface: startup / dock / XMB / overview / settings / routing / appearance / wallpaper / other
- Observation:
- Trigger or steps:
  1.
- Expected behavior:
- Actual behavior:
- Frequency: once / occasional / repeatable / always / unknown
- Severity impression: blocking / disruptive / cosmetic / idea / unknown
- Evidence: screenshot, log, command output, or session timestamp
- Related issue or test ID:
- Notes:
```

## Untriaged Observations

### OBS-20260816-01 Scratchpad ready
- Status: Resolved
- Surface: tracking
- Observation: A dedicated freeform input area is available for future sessions.
- Expected behavior: New observations can be parsed into issues, features, tests, or documentation work without relying on conversation history.
- Actual behavior: This scratchpad and [[Orbit - Prompt Repository]] now define the workflow.
- Evidence: `Orbit - Prompt Repository.md`

## Desired Behaviors

Use this section for behavior that is not currently broken but should become an explicit product requirement.

### DES-YYYYMMDD-## Short desired behavior
- Status: New
- Surface:
- Desired behavior:
- Why it matters:
- Example flow:
- Acceptance condition:
- Related documentation:

## Quirks And Questions

Use this section for things that may be intentional, hardware-specific, or not yet understood. They still need triage.

### Q-YYYYMMDD-## Short quirk
- Status: New
- Context:
- What happens:
- Why it may be intentional:
- What would disambiguate it:
- Evidence:

## Resolved And Archived Entries

Move only the short reference here after the full result has been recorded in the issue tracker, test matrix, visual log, or change log.
