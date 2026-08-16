#!/usr/bin/env python3
"""Keyboard and mouse driven PS3/XMB-inspired launcher."""

from __future__ import annotations

import curses
import shlex
import subprocess
import sys
import tomllib
from pathlib import Path


CONFIG = Path.home() / ".config/phleg/xmb.toml"
DEFAULT_CATEGORIES = ["System", "Utilities", "Graphics", "Games", "Web", "Social"]


def load_menu() -> tuple[list[str], dict[str, list[dict[str, str]]]]:
    try:
        with CONFIG.open("rb") as stream:
            config = tomllib.load(stream)
    except (OSError, tomllib.TOMLDecodeError) as error:
        return DEFAULT_CATEGORIES, {"System": [{"id": "error", "label": f"Config error: {error}"}]}

    menu = config.get("menu", {})
    categories = [str(value) for value in menu.get("categories", DEFAULT_CATEGORIES)]
    excluded = {str(value) for value in menu.get("exclude", [])}
    entries: dict[str, list[dict[str, str]]] = {category: [] for category in categories}
    for raw in config.get("entry", []):
        entry = {str(key): str(value) for key, value in raw.items()}
        category = entry.get("category", "")
        if entry.get("id") in excluded or entry.get("enabled", "true").lower() == "false":
            continue
        if category in entries and entry.get("label"):
            entries[category].append(entry)

    for category in categories:
        entries[category].sort(key=lambda item: item["label"].lower())
        if not entries[category]:
            entries[category].append({"id": "empty", "label": "No entries configured"})
    return categories, entries


def launch(entry: dict[str, str]) -> str:
    try:
        if entry.get("command"):
            subprocess.Popen(shlex.split(entry["command"]), start_new_session=True)
        elif entry.get("desktop"):
            subprocess.Popen(["gtk-launch", entry["desktop"]], start_new_session=True)
        else:
            return "No launch command configured"
    except (OSError, ValueError) as error:
        return f"Launch failed: {error}"
    return f"Launching {entry['label']}"


def add_text(window: curses.window, y: int, x: int, text: str, width: int, attribute: int = 0) -> None:
    if width > 0:
        window.addnstr(y, x, text[:width], width, attribute)


def draw(window: curses.window, categories: list[str], entries: dict[str, list[dict[str, str]]],
         category_index: int, entry_index: int, monitor: str, status: str):
    window.erase()
    height, width = window.getmaxyx()
    category_hits = []
    entry_hits = []
    cyan = curses.color_pair(1)
    blue = curses.color_pair(2)
    selected = curses.color_pair(3) | curses.A_BOLD
    muted = curses.color_pair(4)

    add_text(window, 1, 3, "XMB // PHLEG SESSION HUB", width - 6, cyan | curses.A_BOLD)
    add_text(window, 2, 3, f"{monitor}   arrows navigate   Enter launch   Esc quit", width - 6, muted)
    add_text(window, 4, 3, "<", 2, cyan)
    x = 6
    for index, category in enumerate(categories):
        label = f"  {category}  "
        if x < width - 4:
            add_text(window, 4, x, label, width - x - 3, selected if index == category_index else blue)
            category_hits.append((x, min(width - 1, x + len(label)), index))
        x += len(label) + 1
    add_text(window, 4, width - 4, ">", 2, cyan)

    current_category = categories[category_index]
    current_entries = entries[current_category]
    card_width = max(18, min(28, (width - 8) // max(1, min(4, len(current_entries)))))
    visible = max(1, (width - 6) // (card_width + 2))
    start = max(0, min(entry_index - visible // 2, len(current_entries) - visible))
    y = 8
    for visible_index, item in enumerate(current_entries[start:start + visible]):
        index = start + visible_index
        card_x = 3 + visible_index * (card_width + 2)
        attribute = selected if index == entry_index else blue
        add_text(window, y, card_x, "+" + "-" * (card_width - 2) + "+", card_width, attribute)
        add_text(window, y + 1, card_x, "|", 1, attribute)
        add_text(window, y + 1, card_x + 2, item["label"], card_width - 4, attribute)
        add_text(window, y + 1, card_x + card_width - 1, "|", 1, attribute)
        add_text(window, y + 2, card_x, "+" + "-" * (card_width - 2) + "+", card_width, attribute)
        entry_hits.append((card_x, card_x + card_width, y, y + 3, index))

    selected_item = current_entries[entry_index]
    add_text(window, y + 6, 3, f"{current_category.upper()} / {selected_item['label']}", width - 6, cyan | curses.A_BOLD)
    add_text(window, y + 8, 3, "Mouse: click a category or tile", width - 6, muted)
    add_text(window, height - 2, 3, status, width - 6, muted)
    window.refresh()
    return category_hits, entry_hits


def run(window: curses.window, monitor: str) -> None:
    curses.curs_set(0)
    curses.mousemask(curses.ALL_MOUSE_EVENTS)
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    curses.init_pair(2, curses.COLOR_WHITE, -1)
    curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_CYAN)
    curses.init_pair(4, curses.COLOR_BLUE, -1)
    window.keypad(True)
    categories, entries = load_menu()
    category_index = 0
    entry_index = 0
    status = "Ready"

    while True:
        category_hits, entry_hits = draw(window, categories, entries, category_index, entry_index, monitor, status)
        key = window.getch()
        if key in (27, ord("q"), ord("Q")):
            return
        if key in (curses.KEY_LEFT, ord("h")):
            category_index = (category_index - 1) % len(categories)
            entry_index = 0
        elif key in (curses.KEY_RIGHT, ord("l")):
            category_index = (category_index + 1) % len(categories)
            entry_index = 0
        elif key in (curses.KEY_UP, ord("k")):
            entry_index = (entry_index - 1) % len(entries[categories[category_index]])
        elif key in (curses.KEY_DOWN, ord("j")):
            entry_index = (entry_index + 1) % len(entries[categories[category_index]])
        elif key in (curses.KEY_ENTER, 10, 13):
            status = launch(entries[categories[category_index]][entry_index])
        elif key == curses.KEY_MOUSE:
            try:
                _, mouse_x, mouse_y, _, button_state = curses.getmouse()
            except curses.error:
                continue
            if button_state & curses.BUTTON1_CLICKED:
                for left, right, index in category_hits:
                    if left <= mouse_x < right and mouse_y == 4:
                        category_index = index
                        entry_index = 0
                        break
                else:
                    for left, right, top, bottom, index in entry_hits:
                        if left <= mouse_x < right and top <= mouse_y < bottom:
                            entry_index = index
                            status = launch(entries[categories[category_index]][entry_index])
                            break


def main() -> None:
    monitor = sys.argv[1] if len(sys.argv) > 1 else "reserved"
    curses.wrapper(run, monitor)


if __name__ == "__main__":
    main()
