#!/usr/bin/env python3
"""Lightweight lint for the bundled Home Assistant skill."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def parse_frontmatter(text: str) -> dict[str, str]:
    match = FRONTMATTER_RE.match(text)
    if not match:
        return {}
    data: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data


def local_markdown_target(target: str) -> str | None:
    if target.startswith(("http://", "https://", "mailto:", "#")):
        return None
    path = target.split("#", 1)[0]
    if not path or not path.endswith(".md"):
        return None
    return path


def lint_skill(root: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    if (root / "inventory.yaml").exists():
        errors.append("inventory.yaml must not exist; use /data/ha-context/rename_memory.json")

    skill_file = root / "SKILL.md"
    if not skill_file.exists():
        errors.append("missing SKILL.md")
    else:
        data = parse_frontmatter(skill_file.read_text(encoding="utf-8"))
        for key in ("name", "description"):
            if not data.get(key):
                errors.append(f"SKILL.md missing frontmatter key: {key}")

    for md_file in sorted(root.rglob("*.md")):
        text = md_file.read_text(encoding="utf-8")
        rel = md_file.relative_to(root)

        if rel.parts[0] != "references" and md_file.name != "SKILL.md":
            line_count = len(text.splitlines())
            if line_count > 160:
                warnings.append(f"{rel}: entrypoint is {line_count} lines; keep it compact")

        if "inventory.yaml" in text and rel.as_posix() != "references/rename-memory.md":
            warnings.append(f"{rel}: mentions inventory.yaml")

        if re.search(r"^\s*action:\s*notify\.mobile_app", text, re.MULTILINE):
            warnings.append(f"{rel}: contains direct notify.mobile_app action; prefer notify.send_message")

        if re.search(r"^\s*-\s*platform:\s*template\s*$", text, re.MULTILINE):
            warnings.append(f"{rel}: contains legacy platform template syntax")

        for target in LINK_RE.findall(text):
            local = local_markdown_target(target)
            if local is None:
                continue
            if not (md_file.parent / local).resolve().exists():
                errors.append(f"{rel}: broken markdown link: {target}")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skill_root", type=Path)
    args = parser.parse_args()

    errors, warnings = lint_skill(args.skill_root)
    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"FAIL: {error}")
    if not errors:
        print(f"OK: {args.skill_root.name} lint")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
