#!/bin/bash

set -e

root="${1:-${CODEX_HOME:-$HOME/.codex}/skills}"

if [ ! -d "$root" ]; then
    echo "No skills directory found: $root"
    exit 0
fi

python3 - "$root" <<'PY'
import pathlib
import sys
import yaml

root = pathlib.Path(sys.argv[1])
failed = False

for skill_file in sorted(root.glob("*/SKILL.md")):
    text = skill_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        print(f"FAIL: {skill_file}: missing YAML frontmatter")
        failed = True
        continue
    try:
        _, frontmatter, _ = text.split("---", 2)
        data = yaml.safe_load(frontmatter) or {}
    except Exception as exc:
        print(f"FAIL: {skill_file}: invalid YAML: {exc}")
        failed = True
        continue

    missing = [key for key in ("name", "description") if not data.get(key)]
    if missing:
        print(f"FAIL: {skill_file}: missing {', '.join(missing)}")
        failed = True
        continue

    print(f"OK: {skill_file.parent.name}")

sys.exit(1 if failed else 0)
PY
