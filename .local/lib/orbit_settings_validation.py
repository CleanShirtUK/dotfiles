#!/usr/bin/env python3
"""Validation boundary for the Orbit settings contract."""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from pathlib import Path


def validate_application_policies(values: dict) -> None:
    if not isinstance(values, dict):
        raise ValueError("Application policies must be an object")
    defaults = values.get("defaults", {})
    rules = values.get("rules", [])
    if not isinstance(defaults, dict) or not isinstance(rules, list):
        raise ValueError("Application policies need defaults and rules")

    allowed = {
        "monitor_role": {"focused", "home", "gaming"},
        "workspace_policy": {"dedicated", "inherit", "transient", "floating", "ignore"},
        "children": {"inherit", "dedicated", "ignore"},
    }

    def validate_fields(item: dict, required: bool) -> None:
        for key, choices in allowed.items():
            value = str(item.get(key, ""))
            if not value and not required:
                continue
            if value not in choices:
                raise ValueError(f"Invalid application policy {key}: {value}")
        for key in ("match_pattern", "match_value", "inherit_exclude"):
            value = str(item.get(key, ""))
            if not value:
                continue
            try:
                re.compile(value)
            except re.error as error:
                raise ValueError(f"Invalid application policy pattern: {error}") from error

    validate_fields(defaults, True)
    for rule in rules:
        if not isinstance(rule, dict) or not str(rule.get("name", "")).strip():
            raise ValueError("Each application rule needs a name")
        kind = str(rule.get("kind", "simple"))
        if kind not in {"simple", "custom"}:
            raise ValueError(f"Invalid application rule kind: {rule.get('kind')}")
        if kind == "simple" and not str(rule.get("application", "")).strip():
            raise ValueError(f"Rule {rule['name']} needs an application")
        match_type = str(rule.get("match_type", ""))
        if kind == "simple" and match_type not in {"class", "title", "xwayland", "floating", "fullscreen", "pin", "workspace"}:
            raise ValueError(f"Invalid application rule match type: {rule.get('match_type')}")
        if kind == "simple" and match_type in {"class", "title"} and not str(rule.get("match_value", "")).strip():
            raise ValueError(f"Rule {rule['name']} needs a match value")
        if kind == "custom":
            source = str(rule.get("custom_source", "")).strip()
            if not source:
                raise ValueError(f"Custom rule {rule['name']} needs Lua source")
            if "hl.window_rule" not in source:
                raise ValueError(f"Custom rule {rule['name']} must contain hl.window_rule")
            luac = shutil.which("luac")
            if luac:
                with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False) as stream:
                    stream.write(source)
                    temporary = Path(stream.name)
                try:
                    result = subprocess.run([luac, "-p", str(temporary)], capture_output=True, text=True)
                    if result.returncode != 0:
                        raise ValueError(result.stderr.strip() or f"Invalid Lua in custom rule {rule['name']}")
                finally:
                    temporary.unlink(missing_ok=True)
        validate_fields(rule, False)


def validate_appearance(values: dict) -> None:
    if not isinstance(values, dict):
        raise ValueError("Appearance settings must be an object")
    style = values.get("style", {})
    transparency = values.get("transparency", {})
    effects = values.get("effects", {})
    if style.get("button_shape", "rounded") not in {"rounded", "square", "pill"}:
        raise ValueError("Invalid appearance button shape")
    radius = int(style.get("corner_radius", 10))
    if radius < 0 or radius > 32:
        raise ValueError("Appearance corner radius must be between 0 and 32")
    for key in ("active_opacity", "inactive_opacity", "shell_opacity"):
        value = float(transparency.get(key, 1.0))
        if value < 0 or value > 1:
            raise ValueError(f"Appearance {key} must be between 0 and 1")
    blur_type = str(effects.get("hyprglass_blur_type", "glass"))
    if blur_type not in {"glass", "soft", "clear"}:
        raise ValueError("Invalid Hyprglass blur type")
    animations = effects.get("animations", {})
    for group in ("global", "windows", "fades", "layers", "workspaces", "movement"):
        item = animations.get(group, {})
        speed = float(item.get("speed", 1))
        if speed <= 0 or speed > 100:
            raise ValueError(f"Invalid animation speed for {group}")
        if str(item.get("type", "fade")) not in {"default", "fade", "slide", "popin", "slidefade", "slidefadevert"}:
            raise ValueError(f"Invalid animation type for {group}")


def validate_display_profiles(profiles: list[dict]) -> None:
    if not isinstance(profiles, list):
        raise ValueError("Display profiles must be a list")
    for profile in profiles:
        if not isinstance(profile, dict) or not profile.get("connector"):
            raise ValueError("Each display profile needs a connector")
        if int(profile.get("width", 0)) <= 0 or int(profile.get("height", 0)) <= 0:
            raise ValueError(f"Invalid resolution for {profile['connector']}")
        if float(profile.get("refresh_rate", 0)) <= 0:
            raise ValueError(f"Invalid refresh rate for {profile['connector']}")
