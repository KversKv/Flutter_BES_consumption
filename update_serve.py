#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一键更新服务器：构建并上传 Flutter Web 静态 + chip_server 后端，编译并重启服务。

架构（与 docs/admin 文档一致）：
    浏览器 -> Nginx(:5174 静态 build/web) ──/api──> 反代到 chip_server(:8088)
    admin 的 Save 经 /api/chips 写回服务器 /opt/chip_server/assets/data/chips/**.json

前置条件：
    1. 本地已装 Flutter（用于 flutter build web）；
    2. 本地到服务器已配置 SSH 免密登录；
    3. 服务器已装 Dart SDK（用于 dart compile exe），Nginx 已按文档配好；
    4. 服务器已存在静态站点目录与后端目录（脚本会用 sudo 自动创建/授权）。

用法（项目根目录）：
    python update_serve.py                 # 前端 + 后端 全量更新
    python update_serve.py --frontend-only # 只更新前端静态
    python update_serve.py --backend-only  # 只更新后端
    python update_serve.py --skip-build    # 跳过 flutter build（用已有 build/web）
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
BACKEND_DIR = "/opt/chip_server"      # 后端代码 + assets + JSON 落地目录
SERVICE_NAME = "chip_server"          # systemd 服务名
# =================================

SSH_TARGET = f"{SSH_USER}@{SSH_HOST}"
IS_WINDOWS = os.name == "nt"


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


def build_web():
    print("[update] 构建 Flutter Web（release）...")
    run(
        [
            flutter_cmd(), "build", "web", "--release",
            "--no-tree-shake-icons", "--pwa-strategy=none",
        ],
        cwd=PROJECT_ROOT,
    )


def update_frontend():
    build_dir = os.path.join(PROJECT_ROOT, "build", "web")
    if not os.path.isdir(build_dir):
        print(f"[update] 未找到 {build_dir}，请先构建（去掉 --skip-build）。")
        sys.exit(1)

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
    print("[update] 前端更新完成。")


def update_backend():
    src_dir = os.path.join(PROJECT_ROOT, "tool", "chip_server")
    assets_dir = os.path.join(PROJECT_ROOT, "assets")
    if not os.path.isdir(src_dir):
        print(f"[update] 未找到后端源码 {src_dir}。")
        sys.exit(1)

    print("[update] 准备服务器后端目录 ...")
    ssh(
        f"sudo mkdir -p {BACKEND_DIR} "
        f"&& sudo chown -R {SSH_USER}:{SSH_USER} {BACKEND_DIR}"
    )

    print("[update] 上传后端源码 + assets ...")
    # 后端源码（pubspec / bin / lib）
    scp(os.path.join(src_dir, "pubspec.yaml"), f"{BACKEND_DIR}/")
    scp(os.path.join(src_dir, "bin"), f"{BACKEND_DIR}/")
    # assets/data/chips 为 admin Save 的落地目标，首次部署需带上种子；
    # 之后线上编辑的内容以服务器为准，重复部署默认不覆盖（见下方提示）。
    scp(assets_dir, f"{BACKEND_DIR}/")

    print("[update] 服务器编译后端二进制并安装 systemd 服务 ...")
    remote_setup = (
        f"set -e; cd {BACKEND_DIR}; "
        # 编译：需服务器已装 Dart SDK
        f"~/.pub-cache/bin/dart --version >/dev/null 2>&1 || true; "
        f"dart pub get; "
        f"dart compile exe bin/server.dart -o {BACKEND_DIR}/chip_server; "
        # 写 systemd 单元
        f"echo '[Unit]\\nDescription=BES chip_server\\nAfter=network.target\\n\\n"
        f"[Service]\\nWorkingDirectory={BACKEND_DIR}\\n"
        f"Environment=CHIP_SERVER_PORT={BACKEND_PORT}\\n"
        f"Environment=CHIP_PROJECT_ROOT={BACKEND_DIR}\\n"
        f"ExecStart={BACKEND_DIR}/chip_server\\nRestart=always\\nUser={SSH_USER}\\n\\n"
        f"[Install]\\nWantedBy=multi-user.target' "
        f"| sudo tee /etc/systemd/system/{SERVICE_NAME}.service >/dev/null; "
        f"sudo systemctl daemon-reload; "
        f"sudo systemctl enable {SERVICE_NAME}; "
        f"sudo systemctl restart {SERVICE_NAME}; "
        f"sleep 2; sudo systemctl --no-pager status {SERVICE_NAME} | head -n 12"
    )
    ssh(remote_setup)
    print("[update] 后端更新完成。")


def main():
    parser = argparse.ArgumentParser(description="一键更新服务器（前端静态 + 后端服务）")
    parser.add_argument("--frontend-only", action="store_true")
    parser.add_argument("--backend-only", action="store_true")
    parser.add_argument("--skip-build", action="store_true")
    args = parser.parse_args()

    do_frontend = not args.backend_only
    do_backend = not args.frontend_only

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
