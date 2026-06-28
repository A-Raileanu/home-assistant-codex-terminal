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

try:
    import yaml
except ModuleNotFoundError:
    yaml = None

root = pathlib.Path(sys.argv[1])
failed = False


def load_frontmatter(frontmatter):
    if yaml is not None:
        return yaml.safe_load(frontmatter) or {}
    data = {}
    for line in frontmatter.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise ValueError(f"cannot parse frontmatter line without PyYAML: {line!r}")
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data

for skill_file in sorted(root.glob("*/SKILL.md")):
    text = skill_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        print(f"FAIL: {skill_file}: missing YAML frontmatter")
        failed = True
        continue
    try:
        _, frontmatter, _ = text.split("---", 2)
        data = load_frontmatter(frontmatter)
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

for md_file in sorted(root.glob("*/*.md")):
    if md_file.name == "SKILL.md":
        continue
    text = md_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        continue
    try:
        _, frontmatter, _ = text.split("---", 2)
        data = load_frontmatter(frontmatter)
    except Exception as exc:
        print(f"FAIL: {md_file}: invalid YAML frontmatter: {exc}")
        failed = True
        continue

    missing = [key for key in ("name", "description") if not data.get(key)]
    if missing:
        print(f"FAIL: {md_file}: missing {', '.join(missing)}")
        failed = True

sys.exit(1 if failed else 0)
PY

for skill_path in "$root"/*; do
    [ -d "$skill_path" ] || continue
    lint_script="$skill_path/scripts/ha_skill_lint.py"
    if [ -f "$lint_script" ]; then
        python3 "$lint_script" "$skill_path"
    fi
done
