#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验芯片 JSON 可解析，且 index.json 引用的文件均存在。"""

import argparse
import json
import sys
from pathlib import Path
from typing import List


def check(root) -> List[str]:
    chips_root = Path(root)
    if not chips_root.is_dir():
        return [f"芯片目录不存在：{chips_root}"]

    errors = []
    documents = {}
    for path in sorted(chips_root.rglob("*.json")):
        try:
            with path.open("r", encoding="utf-8") as file:
                documents[path] = json.load(file)
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            errors.append(f"{path}: JSON 解析失败：{exc}")

    for index_path, document in documents.items():
        if index_path.name != "index.json" or not isinstance(document, dict):
            continue

        references = []
        order = document.get("order")
        items = document.get("items")
        if isinstance(order, list):
            references.extend(
                f"{name}.json" for name in order if isinstance(name, str)
            )
        elif isinstance(items, list):
            references.extend(
                item["file"]
                for item in items
                if isinstance(item, dict) and isinstance(item.get("file"), str)
            )

        for reference in references:
            target = index_path.parent / reference
            if not target.is_file():
                errors.append(f"{index_path}: 引用的文件不存在：{reference}")

    return errors


def main() -> int:
    default_root = Path(__file__).resolve().parents[1] / "assets" / "data" / "chips"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=default_root, type=Path)
    args = parser.parse_args()

    errors = check(args.root)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"芯片数据校验通过：{args.root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
