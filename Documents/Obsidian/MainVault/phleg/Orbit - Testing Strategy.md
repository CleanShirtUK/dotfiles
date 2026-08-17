---
title: Orbit - Testing Strategy
type: testing-methodology
tags: [orbit, testing]
---

# Testing Strategy

## Evidence States

- `OPEN`: current evidence is incomplete or contradicts an earlier pass; correction or revalidation is required.
- `PASS`: all applicable evidence currently recorded for the requirement passed.
- `FAIL`: reproducible assertion failed.
- `BLOCKED`: required fixture, device, or recovery path does not exist.
- `MANUAL`: visual, causal, or hardware behavior requires attendance.
- `SKIP`: optional prerequisite was unavailable.

The newest directly observed evidence for a requirement takes precedence over older aggregate or worker runs. Keep older runs as historical evidence, but do not use them to preserve `PASS` when a current direct check fails or cannot reproduce the behavior.

## Test Layers

1. Contract tests: deterministic parsing, persistence, schema, and policy behavior.
2. Live tests: read-only Hyprland, Orbit, monitor, and service snapshots.
3. Soak tests: unattended repeated state paths, service health, memory, and logs.
4. Attended tests: visual interaction, focus, animations, application routing, and recovery.
5. Hardware tests: monitor reconnect, VRR, Bluetooth, audio devices, and failed display apply.

## Commands

```sh
tests/orbit/run-all
tests/orbit/run-all --live
tests/orbit/run-soak --minutes 2 --interval 5 --snapshot-every 1
tests/orbit/run-soak --hours 8 --interval 30
```

Run live and soak tests as the desktop user with the graphical session environment intact. Do not use unattended tests to mutate displays, network, audio, Bluetooth, or application state.

## Recording Rule

Every manual result records date, environment, exact steps, expected result, actual result, evidence path, and follow-up issue. Use [[Orbit - Issues and Corrections]] for anything that is not an unambiguous pass.

`orbit/project-manifest.json` is the canonical machine-readable source. Validate the Markdown status, test matrix, backlog, and queue views against it whenever work-item state or evidence changes.

## Per-Item Integration Rule

Stabilization precedes feature work. Each item is independently verified with its deterministic checks and all applicable live, attended, hardware, or recovery gates before integration. After that independent verification, update the Orbit documentation, make one item-scoped commit directly to `main`, and push it; do not batch unrelated items. Open, blocked, or unvalidated changes remain documented as such and are not described as complete or pushed as confirmed work.
