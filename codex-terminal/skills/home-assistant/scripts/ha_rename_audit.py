#!/usr/bin/env python3
"""Query Home Assistant rename_memory.json without loading it into prompt context."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


DEFAULT_MEMORY = Path("/data/ha-context/rename_memory.json")


def load_memory(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"EROARE: memoria de redenumire nu există: {path}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"EROARE: JSON incorect în {path}: {exc}")


def searchable_text(item: dict[str, Any]) -> str:
    values: list[str] = []
    for key in (
        "device_id",
        "name",
        "registry_name",
        "name_by_user",
        "area_id",
        "area_name",
        "manufacturer",
        "model",
        "entity_id",
        "friendly_name",
        "platform",
        "domain",
        "device_class",
        "disabled_by",
    ):
        value = item.get(key)
        if value is not None:
            values.append(str(value))
    for label in item.get("labels") or []:
        values.append(str(label))
    for label in item.get("label_details") or []:
        if isinstance(label, dict):
            values.extend(str(v) for v in label.values() if v is not None)
    return " ".join(values).lower()


def pending_devices(memory: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        item
        for item in memory.get("devices", [])
        if not item.get("skip_rename_by_default") and not item.get("is_canonical_name")
    ]


def pending_entities(memory: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        item
        for item in memory.get("entities", [])
        if not item.get("skip_rename_by_default")
        and not item.get("is_canonical_friendly_name")
        and item.get("disabled_by") is None
    ]


def filter_query(items: list[dict[str, Any]], query: str | None) -> list[dict[str, Any]]:
    if not query:
        return items
    needle = query.lower()
    return [item for item in items if needle in searchable_text(item)]


def collect_items(memory: dict[str, Any], kind: str, pending_only: bool) -> dict[str, list[dict[str, Any]]]:
    if pending_only:
        devices = pending_devices(memory)
        entities = pending_entities(memory)
    else:
        devices = list(memory.get("devices", []))
        entities = list(memory.get("entities", []))

    if kind == "devices":
        entities = []
    elif kind == "entities":
        devices = []

    return {"devices": devices, "entities": entities}


def emit_summary(memory: dict[str, Any], items: dict[str, list[dict[str, Any]]], as_json: bool) -> None:
    summary = dict(memory.get("summary") or {})
    summary["pending_devices"] = len(pending_devices(memory))
    summary["pending_entities"] = len(pending_entities(memory))
    summary["selected_devices"] = len(items["devices"])
    summary["selected_entities"] = len(items["entities"])
    if as_json:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return
    print("Rezumatul memoriei de redenumire")
    for key in sorted(summary):
        print(f"- {key}: {summary[key]}")


def row(value: Any, width: int) -> str:
    text = "" if value is None else str(value)
    text = text.replace("\n", " ")
    return text if len(text) <= width else text[: max(width - 3, 0)] + "..."


def emit_table(items: dict[str, list[dict[str, Any]]], as_json: bool, limit: int) -> None:
    if as_json:
        print(json.dumps(items, ensure_ascii=False, indent=2))
        return

    if items["devices"]:
        print("Dispozitive")
        print("nume | cameră | producător | model | etichete")
        print("--- | --- | --- | --- | ---")
        for item in items["devices"][:limit]:
            labels = ", ".join(item.get("labels") or [])
            print(
                f"{row(item.get('name'), 42)} | {row(item.get('area_name'), 18)} | "
                f"{row(item.get('manufacturer'), 18)} | {row(item.get('model'), 24)} | {row(labels, 28)}"
            )

    if items["entities"]:
        if items["devices"]:
            print()
        print("Entități")
        print("entity_id | friendly_name | cameră | disabled_by")
        print("--- | --- | --- | ---")
        for item in items["entities"][:limit]:
            print(
                f"{row(item.get('entity_id'), 46)} | {row(item.get('friendly_name'), 48)} | "
                f"{row(item.get('area_name'), 18)} | {row(item.get('disabled_by'), 14)}"
            )

    if not items["devices"] and not items["entities"]:
        print("Nu există dispozitive sau entități potrivite.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--memory", type=Path, default=DEFAULT_MEMORY, help="Calea către rename_memory.json")
    parser.add_argument("--kind", choices=("all", "devices", "entities"), default="all")
    parser.add_argument("--query", help="Filtrează după nume, entity_id, cameră, etichetă, producător sau model")
    parser.add_argument("--summary", action="store_true", help="Arată numărul elementelor")
    parser.add_argument("--pending", action="store_true", help="Arată numai elementele care trebuie verificate")
    parser.add_argument("--json", action="store_true", help="Afișează JSON")
    parser.add_argument("--limit", type=int, default=80, help="Numărul maxim de rânduri din fiecare tabel")
    args = parser.parse_args()

    memory = load_memory(args.memory)
    selected = collect_items(memory, args.kind, args.pending)
    selected = {
        "devices": filter_query(selected["devices"], args.query),
        "entities": filter_query(selected["entities"], args.query),
    }

    if args.summary:
        emit_summary(memory, selected, args.json)
    else:
        emit_table(selected, args.json, max(args.limit, 1))

    return 0


if __name__ == "__main__":
    sys.exit(main())
