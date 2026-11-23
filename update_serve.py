#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一键更新服务器：Git 推送项目仓库，上传 Flutter Web，编译并重启后端。

架构（与 docs/admin 文档一致）：
    浏览器 -> Nginx(:5174 静态 build/web) ──/api──> chip_server(:8088)
    项目与芯片数据经 git push server HEAD:main 发布到 /opt/chip_server/repo
    admin 的 Save 写回该仓库，并由 chip_server 创建 Git 提交

前置条件：
    1. 本地已装 Flutter（用于 flutter build web）；
    2. 本地到服务器已配置 SSH 免密登录；
    3. 服务器已装 Git 与 Dart SDK，Nginx 已按文档配好；
    4. 已按部署文档初始化 /opt/chip_server/repo 与静态站点目录。

用法（项目根目录）：
    python update_serve.py                 # 推送仓库，更新前端与后端
    python update_serve.py --frontend-only # 只更新前端静态，不推送仓库
    python update_serve.py --backend-only  # 推送仓库，只更新后端
    python update_serve.py --skip-build    # 跳过 flutter build（用已有 build/web）

芯片数据不再通过 scp 上传或拉回；服务器改动用 sync_from_server.py 合并回本地。
"""

import argparse
import os
import subprocess
import sys

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

# ===== 服务器配置（按需修改）=====
SSH_USER = "mingyuanli"
SSH_HOST = "172.25.10.143"
WEB_PORT = 5174                       # Nginx 暴露的前端端口（与文档一致）
BACKEND_PORT = 8088                   # chip_server 监听端口
WEB_ROOT = "/var/www/flutter_web"     # Nginx 静态根目录
BACKEND_DIR = "/opt/chip_server"      # 后端二进制目录
REPO_DIR = "/opt/chip_server/repo"    # 项目与芯片数据 Git 仓库
SERVICE_NAME = "chip_server"          # systemd 服务名
# =================================

SSH_TARGET = f"{SSH_USER}@{SSH_HOST}"
IS_WINDOWS = os.name == "nt"
WEB_REQUIRED_FILES = (
    "index.html",
    "main.dart.js",
    "manifest.json",
    os.path.join("assets", "AssetManifest.bin.json"),
    os.path.join("assets", "FontManifest.json"),
)


def run(cmd, cwd=None, check=True):
    printable = cmd if isinstance(cmd, str) else subprocess.list2cmdline(cmd)
    print(f"[update] $ {printable}")
    # Windows 上 flutter/dart 多为 .bat，需经 shell 执行；list 命令统一转字符串。
    if IS_WINDOWS and isinstance(cmd, list):
        result = subprocess.run(printable, cwd=cwd, shell=True)
    else:
        result = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str))
    if check and result.returncode != 0:
        print(f"[update] 命令失败（exit={result.returncode}），中止。")
        sys.exit(result.returncode)
    return result.returncode


def run_git(args, check=True, quiet=False):
    cmd = ["git"] + args
    print(f"[update] $ {subprocess.list2cmdline(cmd)}")
    result = subprocess.run(
        cmd,
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if not quiet:
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
    if check and result.returncode != 0:
        print(f"[update] Git 命令失败（exit={result.returncode}），中止。")
        sys.exit(result.returncode)
    return result


def ssh(remote_cmd, check=True):
    return run(["ssh", SSH_TARGET, remote_cmd], check=check)


def scp(local, remote, recursive=True):
    args = ["scp"]
    if recursive:
        args.append("-r")
    args += [local, f"{SSH_TARGET}:{remote}"]
    return run(args)


def flutter_cmd():
    return "flutter.bat" if IS_WINDOWS else "flutter"


def push_repo():
    status = run_git(
        ["status", "--porcelain", "--", "assets/data/chips"],
        check=False,
    )
    if status.returncode != 0:
        print("[update] 无法检查芯片数据状态，中止。")
        sys.exit(status.returncode)
    if status.stdout.strip():
        print("[update] assets/data/chips 有未提交改动，请先提交再发布。")
        sys.exit(1)

    checker = os.path.join(PROJECT_ROOT, "tool", "chip_data_check.py")
    run([sys.executable, checker], cwd=PROJECT_ROOT)

    remote = run_git(["remote", "get-url", "server"], check=False, quiet=True)
    if remote.returncode != 0:
        remote_url = f"ssh://{SSH_USER}@{SSH_HOST}{REPO_DIR}"
        run_git(["remote", "add", "server", remote_url])

    pushed = run_git(["push", "server", "HEAD:main"], check=False)
    if pushed.returncode != 0:
        print("[update] 服务器上有未同步的改动，请先运行 python sync_from_server.py")
        sys.exit(1)


def build_web():
    print("[update] 构建 Flutter Web（release）...")
    run(
        [
            flutter_cmd(), "build", "web", "--release",
            "--no-web-resources-cdn",
            "--no-tree-shake-icons", "--pwa-strategy=none",
        ],
        cwd=PROJECT_ROOT,
    )


def validate_web_build(build_dir):
    missing = [
        rel_path for rel_path in WEB_REQUIRED_FILES
        if not os.path.isfile(os.path.join(build_dir, rel_path))
    ]
    if missing:
        print("[update] build/web is incomplete; missing required files:")
        for rel_path in missing:
            print(f"[update]   - {rel_path}")
        print("[update] Please run flutter build web again before deploying.")
        sys.exit(1)

    manifest_path = os.path.join(build_dir, "manifest.json")
    with open(manifest_path, "rb") as file:
        prefix = file.read(1)
    if prefix != b"{":
        print("[update] build/web/manifest.json does not look like JSON.")
        sys.exit(1)


def verify_frontend_on_server():
    remote_check = (
        "set -e; "
        f"test -s {WEB_ROOT}/manifest.json; "
        f"test -s {WEB_ROOT}/assets/FontManifest.json; "
        f"head -c 1 {WEB_ROOT}/manifest.json | grep -q '{{'; "
        "manifest_code=$(curl -s -o /tmp/flutter_manifest_check "
        f"-w '%{{http_code}}' http://127.0.0.1:{WEB_PORT}/manifest.json); "
        "font_code=$(curl -s -o /dev/null "
        f"-w '%{{http_code}}' http://127.0.0.1:{WEB_PORT}/assets/FontManifest.json); "
        "first_char=$(head -c 1 /tmp/flutter_manifest_check); "
        "rm -f /tmp/flutter_manifest_check; "
        "if [ \"$manifest_code\" != \"200\" ] || [ \"$first_char\" != \"{\" ]; then "
        "echo \"manifest.json is not being served as JSON; check Nginx root/try_files.\"; "
        "exit 1; "
        "fi; "
        "if [ \"$font_code\" != \"200\" ]; then "
        "echo \"assets/FontManifest.json is not reachable; check uploaded build/web/assets.\"; "
        "exit 1; "
        "fi; "
        "echo \"frontend static checks passed\""
    )
    ssh(remote_check)


def update_frontend():
    build_dir = os.path.join(PROJECT_ROOT, "build", "web")
    if not os.path.isdir(build_dir):
        print(f"[update] 未找到 {build_dir}，请先构建（去掉 --skip-build）。")
        sys.exit(1)
    validate_web_build(build_dir)

    print("[update] 准备服务器静态目录 ...")
    ssh(
        f"sudo mkdir -p {WEB_ROOT} "
        f"&& sudo chown -R {SSH_USER}:{SSH_USER} {WEB_ROOT} "
        f"&& rm -rf {WEB_ROOT}/*"
    )
    print("[update] 上传 build/web/* ...")
    # 注意：只传目录内容，避免在目标多套一层 web 目录；
    # Windows 下 scp 通配不便，改为逐项拷贝更稳妥。
    for name in os.listdir(build_dir):
        scp(os.path.join(build_dir, name), f"{WEB_ROOT}/", recursive=True)
    # 清理 sourcemap
    ssh(f'sudo find {WEB_ROOT} -name "*.map" -delete', check=False)
    # reload nginx，确保新静态立即生效
    ssh("sudo nginx -t && sudo systemctl reload nginx", check=False)
    verify_frontend_on_server()
    print("[update] 前端更新完成。")


def update_backend():
    print("[update] 准备服务器后端目录 ...")
    ssh(
        f"sudo mkdir -p {BACKEND_DIR} "
        f"&& sudo chown -R {SSH_USER}:{SSH_USER} {BACKEND_DIR}"
    )

    print("[update] 从服务器 Git 仓库编译后端并安装 systemd 服务 ...")
    # 用 printf 拼 systemd 单元，避免 heredoc 在跨平台 SSH 单行命令中被截断；
    # 用 \n 作为换行写入临时文件后再 sudo mv，规避 here-document 结束符问题。
    unit_lines = [
        "[Unit]",
        "Description=BES chip_server",
        "After=network.target",
        "",
        "[Service]",
        f"WorkingDirectory={REPO_DIR}",
        f"Environment=CHIP_SERVER_PORT={BACKEND_PORT}",
        f"Environment=CHIP_PROJECT_ROOT={REPO_DIR}",
        "Environment=CHIP_GIT_COMMIT=1",
        f"ExecStart={BACKEND_DIR}/chip_server",
        "Restart=always",
        f"User={SSH_USER}",
        "",
        "[Install]",
        "WantedBy=multi-user.target",
    ]
    # 用单引号包裹，shell 不会展开内部 \n；交给 printf 解释为真正换行。
    unit_payload = "\\n".join(unit_lines) + "\\n"
    remote_setup = (
        "set -e; "
        # 关键修复：先停止可能在跑的旧服务，避免 'Text file busy' 导致 dart compile 失败
        f"sudo systemctl stop {SERVICE_NAME} 2>/dev/null || true; "
        f"cd {REPO_DIR}/tool/chip_server; "
        "dart pub get; "
        f"dart compile exe bin/server.dart -o {BACKEND_DIR}/chip_server; "
        # 用 printf 写入临时文件，再 sudo mv 到 systemd 目录，避免 heredoc 跨平台问题
        f"printf '{unit_payload}' > /tmp/{SERVICE_NAME}.service; "
        f"sudo mv /tmp/{SERVICE_NAME}.service /etc/systemd/system/{SERVICE_NAME}.service; "
        f"sudo chmod 644 /etc/systemd/system/{SERVICE_NAME}.service; "
        f"sudo systemctl daemon-reload; "
        f"sudo systemctl enable {SERVICE_NAME}; "
        f"sudo systemctl restart {SERVICE_NAME}; "
        f"sleep 2; sudo systemctl --no-pager status {SERVICE_NAME} | head -n 12; "
        f"echo '--- 自测 /api/chips ---'; "
        f"curl -s -o /dev/null -w 'api http_code=%{{http_code}}\\n' "
        f"http://127.0.0.1:{BACKEND_PORT}/api/chips"
    )
    ssh(remote_setup)
    print("[update] 后端更新完成。")


def main():
    parser = argparse.ArgumentParser(description="一键更新服务器（Git + 前端静态 + 后端服务）")
    parser.add_argument("--frontend-only", action="store_true", help="只更新前端静态")
    parser.add_argument("--backend-only", action="store_true", help="只更新后端")
    parser.add_argument("--skip-build", action="store_true", help="跳过 flutter build，用已有 build/web")
    args = parser.parse_args()

    do_frontend = not args.backend_only
    do_backend = not args.frontend_only

    if do_backend:
        push_repo()

    if do_frontend and not args.skip_build:
        build_web()

    if do_frontend:
        update_frontend()

    if do_backend:
        update_backend()

    print("\n[update] 全部完成。")
    print(f"[update] 访问前端：http://{SSH_HOST}:{WEB_PORT}/")
    print(f"[update] admin 入口：http://{SSH_HOST}:{WEB_PORT}/admin")
    print(f"[update] 后端 API：http://{SSH_HOST}:{WEB_PORT}/api/chips （经 Nginx 反代到 :{BACKEND_PORT}）")
    print("[update] 提示：Nginx 需配置 location /api/ { proxy_pass http://127.0.0.1:%d; }（见部署流程.md）。" % BACKEND_PORT)


if __name__ == "__main__":
    main()
