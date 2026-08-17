#!/usr/bin/env python3
"""Validate Orbit's canonical project manifest against current source material."""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = ROOT / "orbit/project-manifest.json"
NOTES = ROOT / "Documents/Obsidian/MainVault/phleg"
MATRIX = NOTES / "Orbit - Test Matrix.md"
SCRATCHPAD = NOTES / "Orbit - Session Scratchpad.md"
ISSUES = NOTES / "Orbit - Issues and Corrections.md"
BACKLOG = NOTES / "Orbit - Refactor Backlog.md"
QUEUE = NOTES / "Orbit - Validation Queue.md"
CONTRACT = ROOT / "tests/orbit/contract/test_contract.py"

REQUIRED_RECORD_FIELDS = {
    "id": str,
    "source": list,
    "source_ids": list,
    "type": str,
    "summary": str,
    "milestone": str,
    "priority": str,
    "risk": str,
    "implementation_state": str,
    "validation_state": str,
    "required_gates": list,
    "model_route": str,
    "queue_source": list,
    "evidence": list,
}
SOURCE_ID_PATTERN = re.compile(
    r"\b(?:ORB-[A-Z0-9-]+|(?:APP|APPEARANCE|DOCK|INPUT|LIVE|MON|POWER|SEC|SET|START|STATE|STATIC|SYSTEM|THEME|UI)-\d{3}|(?:OBS|DES)-\d{8}-\d{2}|VQ-\d{8}-\d{2})\b"
)


class Diagnostics:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, code: str, message: str) -> None:
        self.errors.append(f"ERROR {code}: {message}")

    def warning(self, code: str, message: str) -> None:
        self.warnings.append(f"WARNING {code}: {message}")

    def emit(self) -> None:
        for message in self.errors:
            print(message)
        for message in self.warnings:
            print(message)
        print(
            f"SUMMARY errors={len(self.errors)} migration_warnings={len(self.warnings)}"
        )


def read_text(path: Path, diagnostics: Diagnostics) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        diagnostics.error("SOURCE_READ", f"cannot read {path}: {error}")
        return ""


def load_manifest(path: Path, diagnostics: Diagnostics) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        diagnostics.error("MANIFEST_READ", f"cannot read {path}: {error}")
        return None
    except json.JSONDecodeError as error:
        diagnostics.error(
            "JSON_SYNTAX",
            f"{path}:{error.lineno}:{error.colno}: {error.msg}",
        )
        return None
    if not isinstance(value, dict):
        diagnostics.error("SCHEMA_ROOT", "manifest root must be a JSON object")
        return None
    return value


def strings_only(value: list[Any]) -> bool:
    return all(isinstance(item, str) and item for item in value)


def validate_schema(
    manifest: dict[str, Any], diagnostics: Diagnostics
) -> tuple[list[dict[str, Any]], set[str]]:
    for field, expected in (
        ("format", str),
        ("version", int),
        ("allowed_values", dict),
        ("milestones", dict),
        ("contract_registry", dict),
        ("evidence_aliases", list),
        ("records", list),
    ):
        if not isinstance(manifest.get(field), expected):
            diagnostics.error(
                "SCHEMA_ROOT", f"root field {field!r} must be {expected.__name__}"
            )
    if manifest.get("format") != "orbit-project-manifest":
        diagnostics.error(
            "SCHEMA_FORMAT", "format must be 'orbit-project-manifest'"
        )
    if manifest.get("version") != 1:
        diagnostics.error("SCHEMA_VERSION", "only manifest version 1 is supported")

    allowed = manifest.get("allowed_values", {})
    for field in (
        "type",
        "milestone",
        "priority",
        "risk",
        "implementation_state",
        "validation_state",
        "required_gates",
        "model_route",
    ):
        values = allowed.get(field)
        if not isinstance(values, list) or not values or not strings_only(values):
            diagnostics.error(
                "SCHEMA_ALLOWED", f"allowed_values.{field} must be a nonempty string list"
            )

    records_value = manifest.get("records")
    records = records_value if isinstance(records_value, list) else []
    ids: list[str] = []
    source_index: set[str] = set()
    for index, record in enumerate(records):
        label = f"records[{index}]"
        if not isinstance(record, dict):
            diagnostics.error("SCHEMA_RECORD", f"{label} must be an object")
            continue
        for field, expected in REQUIRED_RECORD_FIELDS.items():
            if field not in record:
                diagnostics.error("SCHEMA_FIELD", f"{label} is missing {field!r}")
            elif not isinstance(record[field], expected):
                diagnostics.error(
                    "SCHEMA_FIELD",
                    f"{label}.{field} must be {expected.__name__}",
                )
        record_id = record.get("id")
        if isinstance(record_id, str) and record_id:
            ids.append(record_id)
            source_index.add(record_id)
        else:
            diagnostics.error("SCHEMA_ID", f"{label}.id must be a nonempty string")
        for field in ("source", "source_ids", "required_gates", "queue_source", "evidence"):
            value = record.get(field)
            if isinstance(value, list) and not strings_only(value) and value:
                diagnostics.error(
                    "SCHEMA_LIST", f"{label}.{field} must contain only nonempty strings"
                )
        for field in ("source_ids", "queue_source"):
            value = record.get(field)
            if isinstance(value, list):
                source_index.update(item for item in value if isinstance(item, str))
        for field in (
            "type",
            "milestone",
            "priority",
            "risk",
            "implementation_state",
            "validation_state",
            "model_route",
        ):
            value = record.get(field)
            choices = allowed.get(field, [])
            if isinstance(value, str) and isinstance(choices, list) and value not in choices:
                diagnostics.error(
                    "ALLOWED_VALUE",
                    f"{label}.{field}={value!r} is not in allowed_values.{field}",
                )
        gates = record.get("required_gates")
        if isinstance(gates, list):
            unknown = sorted(set(gates) - set(allowed.get("required_gates", [])))
            if unknown:
                diagnostics.error(
                    "ALLOWED_VALUE", f"{label}.required_gates has unknown values {unknown}"
                )
        if record.get("risk") == "high":
            if record.get("model_route") != "sol-manual":
                diagnostics.error(
                    "RISK_ROUTE",
                    f"{record_id}: high-risk work must route to sol-manual",
                )
            if isinstance(gates, list) and "manual-sol" not in gates:
                diagnostics.error(
                    "RISK_GATE",
                    f"{record_id}: high-risk work must require manual-sol",
                )
        if record.get("model_route") == "luna" and record.get("risk") == "high":
            diagnostics.error(
                "LUNA_RISK", f"{record_id}: Luna may own only low/medium-risk work"
            )

    for record_id, count in sorted(Counter(ids).items()):
        if count > 1:
            diagnostics.error(
                "DUPLICATE_ID", f"manifest ID {record_id!r} occurs {count} times"
            )

    orbit_scope = manifest.get("milestones", {}).get("orbit-1.0", {})
    scope = orbit_scope.get("scope", []) if isinstance(orbit_scope, dict) else []
    for required_scope in ("full-session-scratchpad-vision", "three-repository-split"):
        if required_scope not in scope:
            diagnostics.error(
                "MILESTONE_SCOPE",
                f"milestones.orbit-1.0.scope must include {required_scope!r}",
            )

    required_decisions = {
        "DEC-ORBIT-1.0-SCRATCHPAD",
        "DEC-ORBIT-1.0-REPOSITORIES",
        "DEC-STABILIZATION-FIRST",
        "DEC-LUNA-WORKER",
        "DEC-HIGH-RISK-SOL",
        "DEC-PHASE-AUDIT",
        "DEC-MUTATION-DISPOSABLE",
        "DEC-AUTONOMOUS-MAIN",
        "DEC-SAFE-INSTALLS",
    }
    for missing in sorted(required_decisions - set(ids)):
        diagnostics.error("DECISION_MISSING", f"required user decision {missing} is absent")
    return [item for item in records if isinstance(item, dict)], source_index


def parse_matrix(text: str, diagnostics: Diagnostics) -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    for line_number, line in enumerate(text.splitlines(), 1):
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 5 or cells[0] in {"ID", "----------"} or set(cells[0]) <= {"-"}:
            continue
        row_id = cells[0]
        if row_id in rows:
            diagnostics.error(
                "MATRIX_DUPLICATE", f"{MATRIX}:{line_number}: duplicate row {row_id}"
            )
        rows[row_id] = {
            "requirement": cells[1],
            "automation": cells[2],
            "state": cells[3],
            "evidence": cells[4],
        }
    return rows


def validate_matrix(
    manifest: dict[str, Any],
    records: list[dict[str, Any]],
    source_index: set[str],
    diagnostics: Diagnostics,
) -> dict[str, dict[str, str]]:
    rows = parse_matrix(read_text(MATRIX, diagnostics), diagnostics)
    aliases_value = manifest.get("evidence_aliases", [])
    aliases: dict[str, str] = {}
    if isinstance(aliases_value, list):
        for index, alias in enumerate(aliases_value):
            if not isinstance(alias, dict):
                diagnostics.error(
                    "ALIAS_SCHEMA", f"evidence_aliases[{index}] must be an object"
                )
                continue
            source_id = alias.get("source_id")
            target = alias.get("requirement_id")
            if not isinstance(source_id, str) or not isinstance(target, str):
                diagnostics.error(
                    "ALIAS_SCHEMA",
                    f"evidence_aliases[{index}] needs string source_id and requirement_id",
                )
                continue
            if source_id in aliases:
                diagnostics.error("ALIAS_DUPLICATE", f"duplicate alias {source_id}")
            aliases[source_id] = target
            if target not in source_index:
                diagnostics.error(
                    "ALIAS_TARGET", f"alias {source_id} targets missing requirement {target}"
                )

    expected_aliases = {"START-006 refresh", "START-006 fresh refresh"}
    if set(aliases) != expected_aliases:
        diagnostics.error(
            "MATRIX_ALIAS",
            "the two START-006 refresh rows must be the complete evidence alias set; "
            f"found {sorted(aliases)}",
        )
    substantive = set(rows) - set(aliases)
    for missing in sorted(substantive - source_index):
        diagnostics.error(
            "MATRIX_COVERAGE",
            f"Test Matrix row {missing} has no manifest record; add it before implementation",
        )
    record_ids = {record.get("id") for record in records}
    for alias_id in sorted(expected_aliases & record_ids):
        diagnostics.error(
            "MATRIX_ALIAS_RECORD",
            f"{alias_id} must be evidence for START-006, not a separate record",
        )
    return rows


def parse_scratchpad(text: str) -> list[tuple[str, str]]:
    heading = re.compile(r"^### ((?:OBS|DES)-\S+)", re.MULTILINE)
    matches = list(heading.finditer(text))
    entries: list[tuple[str, str]] = []
    for index, match in enumerate(matches):
        source_id = match.group(1)
        if "YYYY" in source_id:
            continue
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        block = text[match.end() : end]
        canonical_match = re.search(
            r"- Canonical (?:observation|triage) ID: `((?:OBS|DES)-\d{8}-\d{2})`",
            block,
        )
        canonical = canonical_match.group(1) if canonical_match else source_id
        entries.append((source_id, canonical))
    return entries


def validate_scratchpad(
    records: list[dict[str, Any]], source_index: set[str], diagnostics: Diagnostics
) -> None:
    entries = parse_scratchpad(read_text(SCRATCHPAD, diagnostics))
    by_id = {record.get("id"): record for record in records}
    for source_id, canonical in entries:
        if source_id not in source_index:
            diagnostics.error(
                "SCRATCHPAD_SOURCE",
                f"scratchpad source ID {source_id} is not preserved in source_ids",
            )
        if canonical not in source_index:
            diagnostics.error(
                "SCRATCHPAD_COVERAGE",
                f"scratchpad entry {source_id} (canonical {canonical}) has no manifest record",
            )
        record = by_id.get(canonical)
        if record is None:
            diagnostics.error(
                "SCRATCHPAD_CANONICAL",
                f"canonical scratchpad ID {canonical} must be a record ID, not only an alias",
            )
        elif record.get("milestone") != "orbit-1.0":
            diagnostics.error(
                "SCRATCHPAD_MILESTONE",
                f"{canonical} must be in orbit-1.0 because the full scratchpad vision is in scope",
            )


def markdown_blocks(text: str, heading_pattern: re.Pattern[str]) -> list[tuple[str, str]]:
    matches = list(heading_pattern.finditer(text))
    blocks: list[tuple[str, str]] = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        blocks.append((match.group(1), text[match.end() : end]))
    return blocks


def validate_open_work(source_index: set[str], diagnostics: Diagnostics) -> None:
    issue_text = read_text(ISSUES, diagnostics)
    issue_heading = re.compile(r"^### (ORB-[A-Z0-9-]+)\b", re.MULTILINE)
    for issue_id, block in markdown_blocks(issue_text, issue_heading):
        status = re.search(r"^- Status: (.+)$", block, re.MULTILINE)
        if issue_id == "ORB-YYYYMMDD-01":
            continue
        if status and (
            status.group(1).startswith("Open")
            or "follow-up correction open" in status.group(1).lower()
        ) and issue_id not in source_index:
            diagnostics.error(
                "OPEN_ISSUE", f"open issue {issue_id} has no manifest representation"
            )

    backlog_text = read_text(BACKLOG, diagnostics)
    open_blocks = re.findall(
        r"^- \[ \] (.*?)(?=^- \[[ xX]\] |^## |\Z)",
        backlog_text,
        re.MULTILINE | re.DOTALL,
    )
    for block in open_blocks:
        ids = set(SOURCE_ID_PATTERN.findall(block))
        if not ids:
            summary = " ".join(block.split())[:100]
            diagnostics.warning(
                "BACKLOG_UNIDENTIFIED",
                f"open backlog item has no source ID and cannot be keyed: {summary!r}; assign an ID",
            )
        for source_id in sorted(ids - source_index):
            diagnostics.error(
                "OPEN_BACKLOG",
                f"open backlog source {source_id} has no manifest representation",
            )


def parse_contract(
    diagnostics: Diagnostics,
) -> tuple[set[str], dict[str, str]]:
    text = read_text(CONTRACT, diagnostics)
    if not text:
        return set(), {}
    try:
        tree = ast.parse(text, filename=str(CONTRACT))
    except SyntaxError as error:
        diagnostics.error(
            "CONTRACT_SYNTAX", f"{CONTRACT}:{error.lineno}:{error.offset}: {error.msg}"
        )
        return set(), {}
    functions = {
        node.name
        for node in tree.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
        and node.name.startswith("test_")
    }
    registrations: dict[str, str] = {}
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        if not any(isinstance(target, ast.Name) and target.id == "TESTS" for target in node.targets):
            continue
        if not isinstance(node.value, (ast.Tuple, ast.List)):
            diagnostics.error(
                "CONTRACT_REGISTRY_SHAPE", "TESTS must be a literal tuple or list"
            )
            continue
        for entry in node.value.elts:
            if not isinstance(entry, (ast.Tuple, ast.List)) or len(entry.elts) != 2:
                diagnostics.error(
                    "CONTRACT_REGISTRY_SHAPE",
                    "each TESTS entry must be (result_id, test_function)",
                )
                continue
            result_node, function_node = entry.elts
            result_id = result_node.value if isinstance(result_node, ast.Constant) else None
            function = function_node.id if isinstance(function_node, ast.Name) else None
            if not isinstance(result_id, str) or not isinstance(function, str):
                diagnostics.error(
                    "CONTRACT_REGISTRY_SHAPE",
                    "each TESTS entry needs a literal string ID and named function",
                )
                continue
            if function in registrations:
                diagnostics.error(
                    "CONTRACT_DUPLICATE_FUNCTION",
                    f"{function} is registered more than once",
                )
            registrations[function] = result_id
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        if not isinstance(node.func, ast.Name) or node.func.id != "check":
            continue
        if len(node.args) < 2:
            continue
        result_id = node.args[0].value if isinstance(node.args[0], ast.Constant) else None
        function = node.args[1].id if isinstance(node.args[1], ast.Name) else None
        if isinstance(result_id, str) and isinstance(function, str):
            if function in registrations:
                diagnostics.error(
                    "CONTRACT_DUPLICATE_FUNCTION",
                    f"{function} is registered more than once",
                )
            registrations[function] = result_id
    return functions, registrations


def validate_contracts(
    manifest: dict[str, Any],
    matrix_rows: dict[str, dict[str, str]],
    diagnostics: Diagnostics,
) -> None:
    functions, registrations = parse_contract(diagnostics)
    registry = manifest.get("contract_registry", {})
    exclusions_value = registry.get("excluded_functions", []) if isinstance(registry, dict) else []
    exclusions: dict[str, str] = {}
    if not isinstance(exclusions_value, list):
        diagnostics.error(
            "CONTRACT_SCHEMA", "contract_registry.excluded_functions must be a list"
        )
        exclusions_value = []
    for index, item in enumerate(exclusions_value):
        if not isinstance(item, dict):
            diagnostics.error(
                "CONTRACT_SCHEMA", f"excluded_functions[{index}] must be an object"
            )
            continue
        function = item.get("function")
        reason = item.get("reason")
        if not isinstance(function, str) or not isinstance(reason, str) or not reason:
            diagnostics.error(
                "CONTRACT_SCHEMA",
                f"excluded_functions[{index}] needs nonempty function and reason strings",
            )
            continue
        exclusions[function] = reason
    for function in sorted(functions):
        if function not in registrations and function not in exclusions:
            diagnostics.error(
                "CONTRACT_UNREGISTERED",
                f"{function} is neither registered with check() nor explicitly excluded",
            )
    for function, reason in sorted(exclusions.items()):
        if function not in functions:
            diagnostics.error(
                "CONTRACT_EXCLUSION_UNKNOWN",
                f"excluded function {function} does not exist in {CONTRACT}",
            )
        elif function in registrations:
            diagnostics.error(
                "CONTRACT_EXCLUSION_STALE",
                f"{function} is registered; remove its exclusion",
            )
        else:
            diagnostics.warning(
                "CONTRACT_EXCLUDED",
                f"{function} is not run: {reason}",
            )

    exceptions_value = registry.get("evidence_only_exceptions", []) if isinstance(registry, dict) else []
    exceptions: dict[str, str] = {}
    if not isinstance(exceptions_value, list):
        diagnostics.error(
            "CONTRACT_SCHEMA", "contract_registry.evidence_only_exceptions must be a list"
        )
        exceptions_value = []
    for index, item in enumerate(exceptions_value):
        if not isinstance(item, dict):
            diagnostics.error(
                "CONTRACT_SCHEMA", f"evidence_only_exceptions[{index}] must be an object"
            )
            continue
        result_id = item.get("id")
        reason = item.get("reason")
        if not isinstance(result_id, str) or not isinstance(reason, str) or not reason:
            diagnostics.error(
                "CONTRACT_SCHEMA",
                f"evidence_only_exceptions[{index}] needs nonempty id and reason strings",
            )
            continue
        exceptions[result_id] = reason

    exact_results = set(registrations.values())
    used_exceptions: set[str] = set()
    for row_id, row in sorted(matrix_rows.items()):
        if row["state"] != "PASS" or "Contract" not in row["automation"]:
            continue
        if row_id in exact_results:
            continue
        if row_id in exceptions:
            used_exceptions.add(row_id)
            diagnostics.warning(
                "CONTRACT_EVIDENCE_ONLY",
                f"matrix PASS {row_id} has no exact registered result: {exceptions[row_id]}",
            )
        else:
            diagnostics.error(
                "CONTRACT_RESULT_MISSING",
                f"matrix PASS {row_id} includes Contract but check() emits no exact {row_id} result; "
                "register it or add a reasoned evidence-only exception",
            )
    for result_id in sorted(set(exceptions) - used_exceptions):
        diagnostics.warning(
            "CONTRACT_EXCEPTION_UNUSED",
            f"evidence-only exception {result_id} is not needed by a current Contract/PASS row; remove or update it",
        )


def validate_queue(source_index: set[str], diagnostics: Diagnostics) -> None:
    text = read_text(QUEUE, diagnostics)
    heading = re.compile(r"^### (VQ-\S+) - (.+?) - .+$", re.MULTILINE)
    ready: list[tuple[str, str, set[str]]] = []
    matches = list(heading.finditer(text))
    for index, match in enumerate(matches):
        queue_id = match.group(1)
        item_id = match.group(2).strip()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        block = text[match.end() : end]
        if "YYYY" in queue_id:
            continue
        status = re.search(r"^- Status: (.+)$", block, re.MULTILINE)
        if status and status.group(1).strip() == "READY":
            source_line = re.search(
                r"^- Source issue / test / backlog: (.+)$", block, re.MULTILINE
            )
            source_ids = set(SOURCE_ID_PATTERN.findall(source_line.group(1))) if source_line else set()
            source_ids.add(item_id)
            ready.append((queue_id, item_id, source_ids))

    for queue_id, item_id, _ in ready:
        if queue_id not in source_index:
            diagnostics.error(
                "READY_QUEUE_COVERAGE",
                f"READY queue {queue_id} ({item_id}) is absent from manifest queue_source fields",
            )

    queue_counts = Counter(queue_id for queue_id, _, _ in ready)
    for queue_id, count in sorted(queue_counts.items()):
        if count > 1:
            diagnostics.warning(
                "READY_QUEUE_ID_DUPLICATE",
                f"READY queue ID {queue_id} occurs {count} times; assign unique VQ IDs",
            )
    by_item: dict[str, list[str]] = defaultdict(list)
    for queue_id, item_id, _ in ready:
        by_item[item_id].append(queue_id)
    for item_id, queue_ids in sorted(by_item.items()):
        if len(queue_ids) > 1:
            diagnostics.warning(
                "READY_QUEUE_SOURCE_DUPLICATE",
                f"READY item {item_id} has {len(queue_ids)} handoffs {queue_ids}; keep one current READY entry and retain others as audit history",
            )
    by_sources: dict[tuple[str, ...], list[str]] = defaultdict(list)
    for queue_id, _, source_ids in ready:
        by_sources[tuple(sorted(source_ids))].append(queue_id)
    for source_ids, queue_ids in sorted(by_sources.items()):
        if len(queue_ids) > 1:
            diagnostics.warning(
                "READY_QUEUE_SOURCES_DUPLICATE",
                f"READY source set {list(source_ids)} is repeated by {queue_ids}; mark superseded handoffs non-READY",
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help=f"manifest path (default: {DEFAULT_MANIFEST})",
    )
    args = parser.parse_args()
    diagnostics = Diagnostics()
    manifest = load_manifest(args.manifest, diagnostics)
    if manifest is None:
        diagnostics.emit()
        return 1

    records, source_index = validate_schema(manifest, diagnostics)
    matrix_rows = validate_matrix(manifest, records, source_index, diagnostics)
    validate_scratchpad(records, source_index, diagnostics)
    validate_open_work(source_index, diagnostics)
    validate_contracts(manifest, matrix_rows, diagnostics)
    validate_queue(source_index, diagnostics)
    diagnostics.emit()
    return 1 if diagnostics.errors else 0


if __name__ == "__main__":
    sys.exit(main())
