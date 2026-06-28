#!/usr/bin/env python3
"""Scan Home Assistant config files for entity_id references."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable


TEXT_SUFFIXES = {
    ".yaml",
    ".yml",
    ".json",
    ".md",
    ".txt",
    ".jinja",
    ".j2",
    ".py",
    ".js",
    ".ts",
}
SKIP_DIRS = {".git", "__pycache__", "deps", "tts"}
SKIP_SUFFIXES = {".db", ".db-shm", ".db-wal", ".log", ".gz", ".zip", ".png", ".jpg", ".jpeg", ".webp"}


def iter_files(root: Path, include_storage: bool) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        parts = set(path.parts)
        if SKIP_DIRS & parts:
            continue
        if not include_storage and ".storage" in parts:
            continue
        if path.suffix.lower() in SKIP_SUFFIXES:
            continue
        if path.suffix.lower() in TEXT_SUFFIXES or ".storage" in parts:
            yield path


def scan_file(path: Path, needles: list[str]) -> list[dict[str, object]]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        try:
            text = path.read_text(encoding="latin-1")
        except Exception:
            return []
    except OSError:
        return []

    matches: list[dict[str, object]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        found = [needle for needle in needles if needle in line]
        if found:
            matches.append(
                {
                    "file": str(path),
                    "line": line_number,
                    "entities": found,
                    "text": line.strip(),
                }
            )
    return matches


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("entity_id", nargs="+", help="One or more entity_ids to search")
    parser.add_argument("--root", type=Path, default=Path("/config"), help="Config root to scan")
    parser.add_argument("--include-storage", action="store_true", default=True, help="Scan .storage files")
    parser.add_argument("--exclude-storage", action="store_false", dest="include_storage", help="Skip .storage")
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    args = parser.parse_args()

    if not args.root.exists():
        raise SystemExit(f"FAIL: root does not exist: {args.root}")

    matches: list[dict[str, object]] = []
    for path in iter_files(args.root, args.include_storage):
        matches.extend(scan_file(path, args.entity_id))

    if args.json:
        print(json.dumps(matches, ensure_ascii=False, indent=2))
        return 0

    if not matches:
        print("No references found.")
        return 0

    for match in matches:
        entities = ", ".join(match["entities"])  # type: ignore[arg-type]
        print(f"{match['file']}:{match['line']}: {entities}: {match['text']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
