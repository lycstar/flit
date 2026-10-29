#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 环境状态检查: 逐个子任务调 --check(各脚本的 probe, 零副作用)。
# "算不算装好"的判据与安装逻辑写在同一个脚本里, 这里不再维护第二套。
set -uo pipefail
umask 022
DIR="$(cd "$(dirname "$0")" && pwd)"
for _id in android_jdk android_sdk android_ndk android_gradle \
           flutter_tools flutter_sdk flutter_warmup; do
  bash "$DIR/$_id.sh" --check ||
    printf '\033[1;31m%s\033[0m\n' "[check] ✗ $_id 探测脚本异常退出（$?）"
done
