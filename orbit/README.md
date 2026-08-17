# Orbit Project Manifest

`project-manifest.json` is the canonical machine-readable owner of Orbit scope,
work state, risk routing, gates, queue links, and evidence. The Obsidian Test
Matrix, Session Scratchpad, issue tracker, backlog, and validation queue remain
human-oriented source and audit material; they must not introduce an ID that is
absent from the manifest.

Update the source note and manifest together. Preserve source IDs and use
`evidence_aliases` for repeated evidence rather than creating a second
requirement. Do not mark uncertain implementation or validation complete.
Register each contract function in the runner, or add a reasoned temporary
exclusion. Evidence-only PASS exceptions are migration debt and are reported on
every validation run.

Validate from `/home/josh` with:

```sh
python3 tests/orbit/validate-project-manifest.py
```

Errors are structural and return nonzero. Migration warnings identify source
collisions, duplicate READY handoffs, exclusions, and evidence-only PASS claims
without making the canonical JSON invalid.
