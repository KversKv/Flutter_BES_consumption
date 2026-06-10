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
    python update_serve.py                 # 前端 + 后端 + 数据 全量更新（默认用仓库数据覆盖服务器）
    python update_serve.py --frontend-only # 只更新前端静态
    python update_serve.py --backend-only  # 只更新后端（含数据）
    python update_serve.py --skip-build    # 跳过 flutter build（用已有 build/web）
    python update_serve.py --skip-data     # 更新后端但不上传 assets，保留线上 admin 编辑的数据
    python update_serve.py --pull-data     # 把服务器上线编辑的 chips 数据拉回本地仓库（单独用时只拉取）

数据策略：
    后端 chips 数据落地于服务器 {BACKEND_DIR}/assets/data/chips/**.json。
    默认部署会用本地仓库的 assets 覆盖服务器（chip_server 写回时会自动备份原文件）；
    若想保留线上 admin 编辑的数据，加 --skip-data；
    若想把线上编辑同步回仓库，先 --pull-data 再提交。
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


def update_backend(push_data=True):
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

    print("[update] 上传后端源码 ...")
    # 后端源码（pubspec / bin）
    scp(os.path.join(src_dir, "pubspec.yaml"), f"{BACKEND_DIR}/")
    scp(os.path.join(src_dir, "bin"), f"{BACKEND_DIR}/")

    if push_data:
        # 默认覆盖：用仓库 assets 覆盖服务器（chip_server 写回时会自动备份原文件）。
        # 若只想更新代码、保留线上 admin 编辑的数据，部署时加 --skip-data。
        print("[update] 上传 assets（覆盖服务器数据）...")
        scp(assets_dir, f"{BACKEND_DIR}/")
    else:
        print("[update] 跳过 assets 上传（--skip-data），保留服务器上线数据。")

    print("[update] 服务器编译后端二进制并安装 systemd 服务 ...")
    # 用 printf 拼 systemd 单元，避免 heredoc 在跨平台 SSH 单行命令中被截断；
    # 用 \n 作为换行写入临时文件后再 sudo mv，规避 here-document 结束符问题。
    unit_lines = [
        "[Unit]",
        "Description=BES chip_server",
        "After=network.target",
        "",
        "[Service]",
        f"WorkingDirectory={BACKEND_DIR}",
        f"Environment=CHIP_SERVER_PORT={BACKEND_PORT}",
        f"Environment=CHIP_PROJECT_ROOT={BACKEND_DIR}",
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
        f"set -e; cd {BACKEND_DIR}; "
        # 关键修复：先停止可能在跑的旧服务，避免 'Text file busy' 导致 dart compile 失败
        f"sudo systemctl stop {SERVICE_NAME} 2>/dev/null || true; "
        # 编译：需服务器已装 Dart SDK
        f"dart pub get; "
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


def pull_data():
    """把服务器上线编辑的 chips 数据拉回本地仓库（覆盖本地 assets/data/chips）。"""
    local_chips = os.path.join(PROJECT_ROOT, "assets", "data")
    remote_chips = f"{BACKEND_DIR}/assets/data/chips"
    print(f"[update] 从服务器拉取数据 -> {local_chips} ...")
    os.makedirs(local_chips, exist_ok=True)
    run(["scp", "-r", f"{SSH_TARGET}:{remote_chips}", f"{local_chips}/"])
    print("[update] 数据拉取完成。")


def main():
    parser = argparse.ArgumentParser(description="一键更新服务器（前端静态 + 后端服务 + 数据）")
    parser.add_argument("--frontend-only", action="store_true", help="只更新前端静态")
    parser.add_argument("--backend-only", action="store_true", help="只更新后端")
    parser.add_argument("--skip-build", action="store_true", help="跳过 flutter build，用已有 build/web")
    parser.add_argument(
        "--skip-data", action="store_true",
        help="后端更新时不上传 assets，保留服务器上线编辑的数据",
    )
    parser.add_argument(
        "--pull-data", action="store_true",
        help="把服务器上线编辑的 chips 数据拉回本地仓库（与其他更新可叠加；单独使用时只拉取）",
    )
    args = parser.parse_args()

    # --pull-data 单独使用：只拉数据，不做其他更新
    only_pull = args.pull_data and not (args.frontend_only or args.backend_only)

    if args.pull_data:
        pull_data()
        if only_pull:
            # 纯拉数据时无需构建/上传，直接结束
            print("\n[update] 数据已拉回本地仓库。")
            return

    do_frontend = not args.backend_only
    do_backend = not args.frontend_only

    if do_frontend and not args.skip_build:
        build_web()

    if do_frontend:
        update_frontend()

    if do_backend:
        update_backend(push_data=not args.skip_data)

    print("\n[update] 全部完成。")
    print(f"[update] 访问前端：http://{SSH_HOST}:{WEB_PORT}/")
    print(f"[update] admin 入口：http://{SSH_HOST}:{WEB_PORT}/admin")
    print(f"[update] 后端 API：http://{SSH_HOST}:{WEB_PORT}/api/chips （经 Nginx 反代到 :{BACKEND_PORT}）")
    print("[update] 提示：Nginx 需配置 location /api/ { proxy_pass http://127.0.0.1:%d; }（见部署流程.md）。" % BACKEND_PORT)


if __name__ == "__main__":
    main()
