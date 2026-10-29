#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# Flutter 按版本并存，current 是所有工具统一使用的入口。
. "$(dirname "$0")/lib.sh"
init_stage flutter_sdk

FLUTTER_BASE="$PREFIX/opt/flutter"

probe() {
  if installed_ok "$FLUTTER_BASE/current" && [ -x "$FLUTTER_BASE/current/bin/flutter" ]; then
    st "$STAGE" DONE
    echo "__VER__$STAGE:$(basename "$(readlink "$FLUTTER_BASE/current")")"
  else
    st "$STAGE" PENDING
  fi
}

install() {
  # 旧的单版本目录整体搬入版本目录，保留 SDK 和缓存，不重新下载。
  if [ -d "$FLUTTER_BASE/bin" ]; then
    _old_version=$(cat "$FLUTTER_BASE/version" 2>/dev/null || true)
    case "$_old_version" in ''|*[!a-zA-Z0-9.+_-]*) _old_version="$FLUTTER_VERSION" ;; esac
    mv "$FLUTTER_BASE" "$PREFIX/opt/flutter.previous"
    mkdir -p "$FLUTTER_BASE"
    mv "$PREFIX/opt/flutter.previous" "$FLUTTER_BASE/$_old_version"
    ln -s "$_old_version" "$FLUTTER_BASE/current"
  fi
  # 默认初始化保留用户选择的完整版本，不随应用清单变化切回默认。
  if [ "${1:-}" != --release ] && installed_ok "$FLUTTER_BASE/current"; then
    ok '[flutter] 当前版本已安装，跳过下载与解压'
    return
  fi
  case "$FLUTTER_VERSION" in ''|current|*[!a-zA-Z0-9.+_-]*|.*) die '[flutter] 无效的版本号' ;; esac
  FLUTTER_DIR="$FLUTTER_BASE/$FLUTTER_VERSION"
  if ! installed_ok "$FLUTTER_DIR" "$FLUTTER_SHA256"; then
    mkdir -p "$TMPDIR" "$PREFIX/opt"
    T="$TMPDIR/flutter-sdk.tar.xz"
    if [ -f "$T" ] && echo "$FLUTTER_SHA256  $T" | sha256sum -c -; then
      ok '[flutter] 已找到通过校验的安装包，跳过下载'
    else
      rm -f "$T"
      dl "$FLUTTER_SHA256" "$T" ${FLUTTER_URLS[@]+"${FLUTTER_URLS[@]}"}
    fi
    _stage="$TMPDIR/flutter-sdk.extract"
    rm -rf "$_stage"
    mkdir -p "$_stage"
    info "[flutter] 解压 Flutter ${FLUTTER_VERSION}…"
    tar -xJvf "$T" -C "$_stage" || { rm -rf "$_stage"; die '[flutter] 解压失败'; }
    [ -x "$_stage/flutter/bin/flutter" ] || die '[flutter] 安装包缺少 Flutter 命令'
    { grep -rlI '^#!/usr/bin/env \(ba\)\{0,1\}sh' "$_stage/flutter/bin" || [ "$?" -eq 1 ]; } |
    while IFS= read -r f; do
      info "[flutter] 配置脚本解释器：$f"
      sed -i '1s|^#!/usr/bin/env \(ba\)\{0,1\}sh.*|#!'"$PREFIX"'/bin/bash|' "$f"
    done
    mark_installed "$_stage/flutter" "$FLUTTER_SHA256"
    mkdir -p "$FLUTTER_BASE"
    rm -rf "$FLUTTER_DIR"
    mv "$_stage/flutter" "$FLUTTER_DIR"
    rm -rf "$_stage"
    rm -f "$T"
  else
    ok "[flutter] $FLUTTER_VERSION 已安装，跳过下载与解压"
  fi
  ln -sfn "$FLUTTER_VERSION" "$FLUTTER_BASE/.current-next"
  mv -Tf "$FLUTTER_BASE/.current-next" "$FLUTTER_BASE/current"
  echo "__VER__$STAGE:$FLUTTER_VERSION"
  ok "[flutter] 已切换到 $FLUTTER_VERSION"
}

stage_main "$@"
