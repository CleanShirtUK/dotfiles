#!/usr/bin/env python3
"""Small persistence boundary shared by the Orbit settings CLI."""

from __future__ import annotations

import json
import os
import tempfile
import tomllib
from pathlib import Path


def atomic_write(path: Path, content: str) -> None:
    """Replace a settings file without exposing a partially written file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as stream:
        stream.write(content)
        temporary = Path(stream.name)
    os.replace(temporary, path)


def read_toml(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open("rb") as stream:
        return tomllib.load(stream)


def read_json(path: Path, fallback: dict) -> dict:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def toml_value(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'
