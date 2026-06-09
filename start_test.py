#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""本地一键 DEBUG：同时启动 chip_server 后端 + Flutter Chrome 前端。

用法（在项目根目录）：
    python start_test.py
    python start_test.py --backend-port 8088 --web-port 5174

按 Ctrl+C 一次即可同时停止前端与后端。

约定：
    - 后端：tool/chip_server/bin/server.dart，监听 BACKEND_PORT（默认 8088）
    - 前端：flutter run -d chrome --web-port WEB_PORT
            并注入 --dart-define=CHIP_API_BASE=http://localhost:BACKEND_PORT
    - 前端连上后端后，admin 的 Save / Sync Excel / Reset 会写回
      assets/data/chips/**.json，写前自动备份到 .chip_backups/。
"""

import argparse
import os
import shutil
import socket
import subprocess
import sys
import threading
import time
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
CHIP_SERVER_DIR = os.path.join(PROJECT_ROOT, "tool", "chip_server")

IS_WINDOWS = os.name == "nt"


def _require(cmd):
    found = shutil.which(cmd)
    if not found:
        print(f"[start_test] 找不到命令：{cmd}，请确认已安装并加入 PATH。")
        sys.exit(1)
    return found


def _popen(args, cwd=None, env=None):
    """启动子进程；Windows 下用 CREATE_NEW_PROCESS_GROUP 以便单独发送 Ctrl 信号。

    Windows 上 flutter/dart 通常是 .bat/.BAT，必须经 shell 执行，
    故传 shell=True 并把参数拼成字符串（路径含空格用引号包裹）。
    """
    kwargs = {"cwd": cwd, "env": env}
    if IS_WINDOWS:
        kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
        kwargs["shell"] = True
        cmd = subprocess.list2cmdline(args)
        return subprocess.Popen(cmd, **kwargs)
    kwargs["start_new_session"] = True
    return subprocess.Popen(args, **kwargs)


def _terminate(proc, name):
    if proc is None or proc.poll() is not None:
        return
    print(f"[start_test] 正在停止 {name} ...")
    try:
        if IS_WINDOWS:
            # Windows 下 shell=True 时真正占端口的是孙子进程（dart VM / flutter web server），
            # 仅向 shell 包装进程发 CTRL_BREAK 往往杀不掉它们，必须按进程树强杀。
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
        else:
            proc.terminate()
        proc.wait(timeout=8)
    except Exception:
        try:
            proc.kill()
        except Exception:
            pass


def _is_port_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("127.0.0.1", port))
            return True
        except OSError:
            return False


def _pids_on_port(port):
    """返回监听/占用指定端口的 PID 集合（Windows 用 netstat）。"""
    pids = set()
    if not IS_WINDOWS:
        return pids
    try:
        out = subprocess.run(
            ["netstat", "-ano", "-p", "TCP"],
            capture_output=True,
            text=True,
            check=False,
        ).stdout
    except Exception:
        return pids
    needle = f":{port}"
    for line in out.splitlines():
        parts = line.split()
        if len(parts) < 5:
            continue
        local_addr = parts[1]
        if local_addr.endswith(needle):
            pid = parts[-1]
            if pid.isdigit() and pid != "0":
                pids.add(pid)
    return pids


def _free_port(port, label):
    """启动前清理残留占用：若端口被占，强杀其进程树并等待释放。"""
    if _is_port_free(port):
        return True
    pids = _pids_on_port(port)
    if not pids:
        print(f"[start_test] 端口 {port}（{label}）被占用，但未定位到 PID，请手动检查。")
        return False
    print(f"[start_test] 端口 {port}（{label}）被残留进程占用：{', '.join(sorted(pids))}，正在清理 ...")
    for pid in pids:
        subprocess.run(
            ["taskkill", "/PID", pid, "/T", "/F"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    deadline = time.time() + 10
    while time.time() < deadline:
        if _is_port_free(port):
            print(f"[start_test] 端口 {port}（{label}）已释放。")
            return True
        time.sleep(0.5)
    print(f"[start_test] 端口 {port}（{label}）清理后仍被占用，请手动检查。")
    return False


def _wait_backend_ready(port, timeout=30):
    url = f"http://localhost:{port}/api/chips"
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=2) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            time.sleep(0.5)
    return False


def _wait_web_ready(port, timeout=120):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=2):
                return True
        except OSError:
            time.sleep(0.5)
    return False


def _find_chrome():
    found = shutil.which("chrome")
    if found:
        return found
    candidates = []
    if IS_WINDOWS:
        for var in ("PROGRAMFILES", "PROGRAMFILES(X86)", "LOCALAPPDATA"):
            base = os.environ.get(var)
            if base:
                candidates.append(
                    os.path.join(base, "Google", "Chrome", "Application", "chrome.exe")
                )
    else:
        candidates += [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/usr/bin/google-chrome",
            "/usr/bin/chromium-browser",
            "/usr/bin/chromium",
        ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def _open_in_chrome(web_port):
    """前端 Web 就绪后，用 Chrome 打开首页与 admin 页。"""
    if not _wait_web_ready(web_port):
        print(f"[start_test] 前端 Web :{web_port} 在超时时间内未就绪，跳过自动打开页面。")
        return
    urls = [
        f"http://localhost:{web_port}/",
        f"http://localhost:{web_port}/admin",
    ]
    chrome = _find_chrome()
    if not chrome:
        print("[start_test] 未找到 Chrome，可手动打开：" + " , ".join(urls))
        return
    for idx, url in enumerate(urls):
        print(f"[start_test] 用 Chrome 打开 {url}")
        try:
            # chrome.exe 是真实可执行文件，直接调用即可；不要走 _popen 的 shell=True
            # 路径（含空格的 exe 经 cmd.exe 转义常静默失败，导致页面不弹出）。
            subprocess.Popen([chrome, url])
        except Exception as exc:
            print(f"[start_test] 打开 {url} 失败：{exc}")
        if idx == 0:
            # 让首个 Chrome 实例先起来，第二个 URL 才能稳定作为新标签合入同一窗口。
            time.sleep(1.5)


def main():
    parser = argparse.ArgumentParser(description="本地一键启动后端 + Flutter Chrome")
    parser.add_argument("--backend-port", type=int, default=8088)
    parser.add_argument("--web-port", type=int, default=5174)
    parser.add_argument(
        "--flutter-mode",
        choices=("debug", "profile", "release"),
        default="debug",
        help="Flutter Web run mode. Use profile/release for local startup performance checks.",
    )
    args = parser.parse_args()

    dart = _require("dart")
    flutter = _require("flutter")

    backend_port = args.backend_port
    web_port = args.web_port
    api_base = f"http://localhost:{backend_port}"

    backend = None
    frontend = None

    try:
        # 0) 启动前清理残留占用，避免上次未彻底退出导致端口被占
        _free_port(backend_port, "后端")
        _free_port(web_port, "前端")

        # 1) 启动后端
        backend_env = dict(os.environ)
        backend_env["CHIP_SERVER_PORT"] = str(backend_port)
        backend_env["CHIP_PROJECT_ROOT"] = PROJECT_ROOT
        print(f"[start_test] 启动后端 chip_server :{backend_port} ...")
        backend = _popen(
            [dart, "run", "bin/server.dart"],
            cwd=CHIP_SERVER_DIR,
            env=backend_env,
        )

        if not _wait_backend_ready(backend_port):
            print("[start_test] 后端在超时时间内未就绪，仍继续启动前端（请检查后端日志）。")
        else:
            print(f"[start_test] 后端就绪：{api_base}/api/chips")

        # 2) 启动前端（注入后端地址）。
        # 用 web-server 设备：不依赖 flutter 自行拉起 Chrome（在 shell 子进程下常卡在
        # "Waiting for connection from debug service on Chrome"），改由本脚本主动开 Chrome。
        print(f"[start_test] 启动 Flutter Web :{web_port}（CHIP_API_BASE={api_base}）...")
        flutter_args = [flutter, "run"]
        if args.flutter_mode != "debug":
            flutter_args.append(f"--{args.flutter_mode}")
        flutter_args += [
            "-d", "web-server",
            "--no-web-resources-cdn",
            "--web-hostname", "localhost",
            "--web-port", str(web_port),
            "--dart-define", f"CHIP_API_BASE={api_base}",
        ]
        frontend = _popen(flutter_args, cwd=PROJECT_ROOT)

        # 3) 前端就绪后用 Chrome 打开首页与 admin 页（后台线程，避免阻塞监控循环）
        threading.Thread(
            target=_open_in_chrome, args=(web_port,), daemon=True
        ).start()

        print("[start_test] 前后端已启动。按 Ctrl+C 停止全部。")
        # 任一进程退出则收尾
        while True:
            if backend.poll() is not None:
                print("[start_test] 后端进程已退出。")
                break
            if frontend.poll() is not None:
                print("[start_test] 前端进程已退出。")
                break
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n[start_test] 收到 Ctrl+C，正在停止前后端 ...")
    finally:
        _terminate(frontend, "前端 flutter")
        _terminate(backend, "后端 chip_server")
        print("[start_test] 已全部停止。")


if __name__ == "__main__":
    main()
