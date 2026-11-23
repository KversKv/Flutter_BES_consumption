#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]


class SyncFromServerTest(unittest.TestCase):
    def setUp(self):
        self.temp_path = Path(tempfile.mkdtemp())
        self.server = self.temp_path / "server"
        self.local = self.temp_path / "local"
        self.server.mkdir()

        self.git(self.server, "init", "-b", "main")
        self.configure_git(self.server)
        self.write_chip(self.server, "A", 0)
        self.write_chip(self.server, "B", 0)
        self.write_json(
            self.server,
            "assets/data/chips/earbuds/index.json",
            {"version": 1, "order": ["A", "B"]},
        )
        self.commit_chips(self.server, "initial chips")

        subprocess.run(
            ["git", "clone", str(self.server), str(self.local)],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        self.configure_git(self.local)
        self.copy_scripts()

    def tearDown(self):
        # Windows Git integrations can recreate hooks during directory cleanup.
        shutil.rmtree(str(self.temp_path), ignore_errors=True)

    def git(self, repo, *args, check=True):
        result = subprocess.run(
            ["git"] + list(args),
            cwd=str(repo),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if check and result.returncode != 0:
            self.fail(
                f"Git command failed: {args}\n{result.stdout}\n{result.stderr}"
            )
        return result

    def configure_git(self, repo):
        self.git(repo, "config", "user.name", "Sync Test")
        self.git(repo, "config", "user.email", "sync-test@example.com")

    def copy_scripts(self):
        (self.local / "tool").mkdir()
        for name in ("sync_from_server.py", "update_serve.py"):
            shutil.copy2(PROJECT_ROOT / name, self.local / name)
        shutil.copy2(
            PROJECT_ROOT / "tool" / "chip_data_check.py",
            self.local / "tool" / "chip_data_check.py",
        )

    def write_json(self, repo, relative_path, document):
        path = repo / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(document, indent=2) + "\n",
            encoding="utf-8",
        )

    def write_chip(self, repo, chip_id, value):
        self.write_json(
            repo,
            f"assets/data/chips/earbuds/{chip_id}.json",
            {"id": chip_id, "value": value},
        )

    def read_chip(self, repo, chip_id):
        path = repo / f"assets/data/chips/earbuds/{chip_id}.json"
        return json.loads(path.read_text(encoding="utf-8"))

    def commit_chips(self, repo, message):
        self.git(repo, "add", "--", "assets/data/chips")
        self.git(repo, "commit", "-m", message)

    def run_sync(self, *args):
        return subprocess.run(
            [
                sys.executable,
                str(self.local / "sync_from_server.py"),
                "--remote-url",
                str(self.server),
            ] + list(args),
            cwd=str(self.local),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )

    def assert_success(self, result):
        self.assertEqual(
            result.returncode,
            0,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )

    def test_merges_server_chip_a_with_local_chip_b(self):
        self.write_chip(self.local, "B", 1)
        self.commit_chips(self.local, "local: chip B")
        self.write_chip(self.server, "A", 2)
        self.commit_chips(self.server, "admin: chip A")

        result = self.run_sync()

        self.assert_success(result)
        self.assertEqual(self.read_chip(self.local, "A")["value"], 2)
        self.assertEqual(self.read_chip(self.local, "B")["value"], 1)
        conflicts = self.git(self.local, "diff", "--name-only", "--diff-filter=U")
        self.assertEqual(conflicts.stdout.strip(), "")

    def test_same_field_conflict_returns_two(self):
        self.write_chip(self.local, "A", 1)
        self.commit_chips(self.local, "local: chip A")
        self.write_chip(self.server, "A", 2)
        self.commit_chips(self.server, "admin: chip A")

        result = self.run_sync()

        self.assertEqual(
            result.returncode,
            2,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        output = result.stdout + result.stderr
        self.assertIn("A.json", output)
        self.assertIn("sync_from_server.py --check", output)
        conflicts = self.git(self.local, "diff", "--name-only", "--diff-filter=U")
        self.assertIn("A.json", conflicts.stdout)

    def test_dry_run_does_not_change_head(self):
        self.write_chip(self.server, "A", 2)
        self.commit_chips(self.server, "admin: chip A")
        old_head = self.git(self.local, "rev-parse", "HEAD").stdout.strip()

        result = self.run_sync("--dry-run")

        self.assert_success(result)
        new_head = self.git(self.local, "rev-parse", "HEAD").stdout.strip()
        self.assertEqual(new_head, old_head)
        self.assertEqual(self.read_chip(self.local, "A")["value"], 0)
        self.assertIn("A.json", result.stdout)


if __name__ == "__main__":
    unittest.main()
