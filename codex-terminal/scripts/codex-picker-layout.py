#!/usr/bin/env python3

import sys
import unicodedata


def cell_width(value: str) -> int:
    width = 0
    for char in value:
        if unicodedata.combining(char):
            continue
        width += 2 if unicodedata.east_asian_width(char) in {"F", "W"} else 1
    return width


def fit(value: str, width: int) -> str:
    width = max(width, 1)
    if cell_width(value) > width:
        kept: list[str] = []
        used = 0
        for char in value:
            char_width = 0 if unicodedata.combining(char) else (
                2 if unicodedata.east_asian_width(char) in {"F", "W"} else 1
            )
            if used + char_width > max(width - 1, 0):
                break
            kept.append(char)
            used += char_width
        value = "".join(kept) + "…"
    return value + (" " * max(width - cell_width(value), 0))


def main() -> None:
    box_width = int(sys.argv[1])
    banner_count = int(sys.argv[2])
    item_count = int(sys.argv[3])
    args = sys.argv[4:]
    separator = args.index("--")
    banners = args[:banner_count]
    titles = args[banner_count:separator]
    descriptions = args[separator + 1 :]

    if len(titles) != item_count or len(descriptions) != item_count:
        raise SystemExit("număr greșit de texte pentru meniu")

    for text in banners:
        print(fit(text, box_width - 2))
    for text in titles:
        print(fit(text, box_width - 7))
    for text in descriptions:
        print(fit(text, box_width - 6))


if __name__ == "__main__":
    main()
