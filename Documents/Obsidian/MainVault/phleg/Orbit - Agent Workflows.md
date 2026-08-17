---
title: Orbit - Agent Workflows
type: operating-procedure
status: active
tags: [orbit, agents, workflow, validation]
---

# Orbit Agent Workflows

Orbit uses a supervised, one-item pipeline. Selection/planning is separate
from execution, and execution is separate from independent verification. A
worker never derives work from contradictory priority prose and never
publishes its own changes.

## Roles And Risk

### Luna selector

`orbit-selector` reads the current project evidence and Prompt 3 ordering. It
writes exactly one `.local/state/orbit/item-manifest.json` and does not
implement anything. The manifest identifies one source, exact allowed file
paths, deterministic test IDs, acceptance conditions, plan, and risk. The
supervisor stamps the source-file SHA-256, starting worktree tree, and base
commit before execution.

The starting-dirty manifest is authoritative. A selected source file or
allowed path that was dirty at item start is rejected because it cannot be
independently staged and committed without absorbing earlier work. Unrelated
dirty paths may remain and are protected by the baseline tree.

### Luna worker

`orbit-worker` receives only a sealed `READY` manifest. It executes that one
low- or medium-risk item, edits only exact allowed paths, runs the listed
tests, updates directly necessary tracking, and writes one structured result.
It does not select work, change the manifest, start another session, or use
Git publication commands.

### Sol auditors

`orbit-sol-phase-auditor` is started manually at the boundaries between
stabilization, feature implementation, repository split, and release. It
reviews the complete phase and returns `ADVANCE`, `REMAIN`, or `BLOCKED`.
Routine low/medium-risk Luna items do not consume a Sol review; their scope and
publication are gated by deterministic supervisor checks. This preserves Sol
for the cross-cutting decisions where deeper reasoning materially reduces
risk, within the existing subscription.

`orbit-sol-auditor` is the strict read-only verifier for a manually implemented
high-risk item. It returns `APPROVE`, `REJECT`, or `MANUAL_REQUIRED` before that
item can be published.

### Manual Sol implementer

`orbit-sol-implementation` is never launched by the autonomous loop. A high-
risk or manual-only manifest stops the loop and prints a command for a user to
start an attended Sol session. That session confirms the boundary, implements
one item, writes the same structured result, and stops. The user then runs the
printed `--resume-sol` command for independent validation, a second read-only
Sol audit, and publication.

Risk rules:

- `low`: narrow, deterministic, reversible code/docs/tests with no privilege
  or active-runtime mutation.
- `medium`: bounded multi-component work, judged-safe package installation, or
  disposable fixtures with deterministic recovery.
- `high`: security, authentication, secrets, destructive or broad migration,
  boot/system service policy, uncertain privilege, or mutation of active
  display, graphical/login session, network, audio, Bluetooth, or power.

Luna handles only low and medium risk. High risk always halts for manually
started Sol. Runtime mutation of the active display, graphical/login session,
network, audio, Bluetooth, or power is prohibited for every role, even if it
appears reversible. It is allowed only in a disposable environment whose
failure or destruction cannot affect the active environment.

## Manifest Contract

The selector writes one strict JSON object with:

- `schema_version: 1`;
- `selection_state`: `READY`, `QUEUE_EMPTY`, `BLOCKED`, or `MANUAL_ONLY`;
- item ID, title, source file, source reference, and sealed source SHA-256;
- `risk`: `low`, `medium`, or `high`, plus a manual reason when applicable;
- exact repository-relative file paths, without globs or directories;
- deterministic project test IDs;
- acceptance conditions and a bounded plan;
- supervisor-owned base commit, baseline tree, and run directory.

Only this manifest authorizes execution. Markdown status, issue, backlog, or
priority text remains source evidence and cannot broaden or replace it.

## Result Contract

The executor's final operation is writing
`.local/state/orbit/worker-result.json`. It is strict JSON containing:

- schema version, `COMPLETED` or `BLOCKED`, item ID, source hash, and risk;
- every and only changed repository file;
- all manifest test IDs;
- evidence entries with exact command, exit code, and concise result;
- queue state `NONE` or `READY_ADDED`, source reference, and entry ID;
- every package change with manager, operation, package, resolved version,
  exact command, and result;
- every sudo command verbatim;
- null for a completed blocker or an exact blocker for `BLOCKED`.

Missing, malformed, mismatched, or incomplete results stop the run. A blocked
result is inspected but never committed.

## Validation Queue

The queue lives in [[Orbit - Validation Queue]]. A worker may append one READY
handoff only when an attended, visual, hardware, causal, or recovery gate
remains. Each new entry contains the manifest `source_ref` and
`source_sha256`, work/test IDs, environment and prerequisites, exact numbered
steps, safe reset, expected behavior, automated evidence, remaining gate,
evidence to capture, and result state.

The supervisor counts READY entries for the source before execution and after
execution. It refuses to execute a source that is already READY and accepts
`READY_ADDED` only when the count changes from zero to exactly one. Workers do
not refresh or duplicate a READY source.

Prompt 8 consumes one READY entry at a time. The user records `PASS`,
`PASS-WITH-NOTE`, `FAIL`, or `BLOCKED`; the approval session does not implement
fixes.

## Supervisor Gates

`orbit-run-workers` performs these gates in order:

1. Acquire a non-blocking `flock`; only one supervisor may run.
2. Require exact root `/home/josh`, branch `main`, and fetch/push remote
   `https://github.com/CleanShirtUK/dotfiles.git` named `origin`.
3. Refuse an in-progress Git operation, staged changes, or any local/remote
   `main` mismatch.
4. Record a starting-dirty JSON manifest and a full worktree tree using a
   temporary Git index; the user's real index is untouched.
5. Run Luna selection and seal the source hash.
6. Refuse dirty source/selected paths, duplicate READY sources, invalid plans,
   manual-only work, and high risk. High risk prints the manual Sol entrypoint.
7. Run one fresh Luna worker under a timeout.
8. Parse the strict result, compare its files exactly with the baseline delta,
   enforce allowed paths, run `git diff --check`, and verify queue uniqueness.
9. Run the independent non-mutating project validator `tests/orbit/run-all`
   and require every manifest test ID to pass in `summary.json`.
10. For manually implemented high-risk work only, give the manifest, result,
    diff, validator evidence, queue counts, and package/sudo records to the
    strict read-only Sol auditor.
11. Recheck that the worktree did not change during verification, stage only
    the verified paths, commit one item, push `HEAD:main`, and verify the
    remote commit ID.

Any failure stops before the next item. If a commit succeeds but push fails,
the local commit is preserved and the run stops; the supervisor never resets
or rewrites history.

## Starting The Loop

Agent definitions do not hard-pin a model, so the same workflow remains usable
if subscription model names change. `opencode models` currently exposes
`openai/gpt-5.6-luna` and `openai/gpt-5.6-sol` through the configured OpenAI
subscription. Set `ORBIT_LUNA_MODEL` and `ORBIT_SOL_MODEL` to those exact IDs;
re-check the model list before a long run and do not substitute an external
paid provider or credit-backed model.

Default bounded run:

```sh
orbit-run-workers --auto \
  --luna-model "$ORBIT_LUNA_MODEL"
```

Explicit long run (up to 1000 independently verified items):

```sh
orbit-run-workers --auto --long-run \
  --timeout 14400 \
  --luna-model "$ORBIT_LUNA_MODEL"
```

Use `--max-items N` for another explicit bound. The default is 10 items and
the default per-agent/per-validator timeout is 7200 seconds. `--auto` is
mandatory but cannot override explicit agent denials or supervisor gates.

At the end of stabilization and each later project phase, manually start
`orbit-sol-phase-auditor` with the included Sol model. Do not advance the
manifest's phase while its decision is `REMAIN` or `BLOCKED`.

When high risk halts, run the exact manual Sol command printed by the
supervisor. After that attended session writes its result, run the printed
`--resume-sol` command. Do not launch the high-risk agent through the
autonomous loop.

## Package And Sudo Policy

A medium-risk worker may perform a judged-safe package installation through
an explicitly permitted package-manager install command. It must inspect and
record before/after state and preserve exact manager, operation, package,
resolved version, command, and result. Every sudo command is recorded
verbatim. Uncertain privilege, removals, broad upgrades, service policy, or
unbounded install scripts are high risk and halt for manual Sol.

Package permission never authorizes active display/session/network/audio/
Bluetooth/power mutation. The same prohibition applies to tests, reloads,
restarts, and recovery exercises.

## Commit Policy

Agents never stage, commit, amend, reset, stash, switch branches, or push. The
supervisor is explicitly authorized to commit and push each independently
verified item directly to `main`; this is the sole autonomous exception to the
normal Session Contract. There is no batch commit and no unverified carryover
to another item.

## Idle Inhibition

For a deliberately long run, an external inhibitor may prevent idle lock or
suspend without changing Hypridle configuration:

```sh
systemd-inhibit \
  --what=idle:sleep \
  --mode=block \
  --why="Orbit autonomous workers" \
  orbit-run-workers --auto --long-run \
    --timeout 14400 \
    --luna-model "$ORBIT_LUNA_MODEL"
```

The inhibitor is released when the supervisor exits. It prevents an external
idle action; it does not authorize an agent to change power or session state.
