#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""拉取并合并服务器 main 分支上的芯片数据改动。"""

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Optional, Sequence

from tool.chip_data_check import check
from update_serve import REPO_DIR, SSH_HOST, SSH_USER

PROJECT_ROOT = Path(__file__).resolve().parent
CHIPS_PATH = "assets/data/chips"
CHIPS_ROOT = PROJECT_ROOT / CHIPS_PATH


def run_git(args):
    cmd = ["git"] + list(args)
    try:
        result = subprocess.run(
            cmd,
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError as exc:
        print(
            f"[sync] Git 命令失败：{subprocess.list2cmdline(cmd)}",
            file=sys.stderr,
        )
        print(str(exc), file=sys.stderr)
        return subprocess.CompletedProcess(cmd, 1, "", str(exc))

    if result.returncode != 0:
        print(
            f"[sync] Git 命令失败：{subprocess.list2cmdline(cmd)}",
            file=sys.stderr,
        )
        if result.stdout:
            print(result.stdout, end="", file=sys.stderr)
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
    return result


def validate_chips():
    errors = check(CHIPS_ROOT)
    if not errors:
        print("[sync] 芯片数据校验通过。")
        return True

    print("[sync] 芯片数据校验失败：", file=sys.stderr)
    for error in errors:
        print(f"[sync]   - {error}", file=sys.stderr)
    print("[sync] 请修复上述问题后提交。", file=sys.stderr)
    return False


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="只查看服务器改动，不合并")
    mode.add_argument("--check", action="store_true", help="冲突解决后校验芯片数据")
    parser.add_argument("--remote-url", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)

    if args.check:
        return 0 if validate_chips() else 1

    status = run_git(["status", "--porcelain", "--", CHIPS_PATH])
    if status.returncode != 0:
        print("[sync] 无法检查芯片数据状态。", file=sys.stderr)
        return 1
    if status.stdout.strip():
        print("[sync] assets/data/chips 有未提交改动：", file=sys.stderr)
        print(status.stdout, end="", file=sys.stderr)
        print("[sync] 请先提交本地芯片改动，再运行同步。", file=sys.stderr)
        return 1

    old_head_result = run_git(["rev-parse", "HEAD"])
    if old_head_result.returncode != 0:
        return 1
    old_head = old_head_result.stdout.strip()

    remote_url = args.remote_url or f"ssh://{SSH_USER}@{SSH_HOST}{REPO_DIR}"
    remote = run_git(["remote", "get-url", "server"])
    if remote.returncode != 0:
        added = run_git(["remote", "add", "server", remote_url])
        if added.returncode != 0:
            return 1
    elif args.remote_url and remote.stdout.strip() != args.remote_url:
        updated = run_git(["remote", "set-url", "server", args.remote_url])
        if updated.returncode != 0:
            return 1

    fetched = run_git(["fetch", "server", "main"])
    if fetched.returncode != 0:
        return 1

    log = run_git([
        "log",
        "--format=%h%x09%aI%x09%an%x09%s",
        "HEAD..server/main",
        "--",
        CHIPS_PATH,
    ])
    if log.returncode != 0:
        return 1
    if not log.stdout.strip():
        print("[sync] 已是最新，服务器没有新的芯片提交。")
        return 0

    print("[sync] 服务器新增芯片提交（时间 · 操作人 · 说明）：")
    print(log.stdout, end="")

    if args.dry_run:
        stat = run_git(["diff", "--stat", "HEAD..server/main", "--", CHIPS_PATH])
        if stat.returncode != 0:
            return 1
        print("[sync] 变更统计（--dry-run，未合并）：")
        print(stat.stdout, end="")
        return 0

    merged = run_git(["merge", "--no-edit", "server/main"])
    if merged.returncode != 0:
        conflicts = run_git(["diff", "--name-only", "--diff-filter=U"])
        if conflicts.returncode != 0:
            return 1
        if conflicts.stdout.strip():
            print("\n[sync] 合并冲突，涉及文件：", file=sys.stderr)
            print(conflicts.stdout, end="", file=sys.stderr)
            print(
                "[sync] 请在编辑器中解决冲突，执行 git add、git commit，"
                "然后运行 python sync_from_server.py --check。",
                file=sys.stderr,
            )
            return 2
        print("[sync] 合并失败，请根据上述 Git 输出处理后重试。", file=sys.stderr)
        return 1

    if merged.stdout:
        print(merged.stdout, end="")
    if not validate_chips():
        return 1

    changed = run_git([
        "diff",
        "--name-only",
        f"{old_head}..HEAD",
        "--",
        CHIPS_PATH,
    ])
    if changed.returncode != 0:
        return 1

    print("\n[sync] 同步汇总：")
    print("[sync] 合入提交：")
    print(log.stdout, end="")
    print("[sync] 改动的芯片文件：")
    if changed.stdout.strip():
        print(changed.stdout, end="")
    else:
        print("[sync]   （无文件内容变化）")
    print("[sync] 同步完成。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
