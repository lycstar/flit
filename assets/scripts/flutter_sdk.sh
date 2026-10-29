#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 子任务 3-1: Flutter SDK 本体(自建 aarch64, 明文 tar.xz 分发)。
# 中断与重试:
#   下载中断 → .part 断点续传;
#   解压/解释器重写中断 → 无标记 → 整个 $FLUTTER_DIR 清掉重解压(自己的目录, 可整删),
#   安装包留到标记落盘才删, 所以这种重试不重下;
#   目录存在不算装好: bin/ 在归档顺序里很早出来, 单看 bin/flutter 会被半截解压骗过。
. "$(dirname "$0")/lib.sh"
init_stage flutter_sdk

FLUTTER_DIR="$PREFIX/opt/flutter"

probe() {
  if installed_ok "$FLUTTER_DIR" "$FLUTTER_SHA256"; then
    st "$STAGE" DONE
    if [ -f "$FLUTTER_DIR/version" ]; then echo "__VER__$STAGE:$(cat "$FLUTTER_DIR/version")"; fi
  else
    st "$STAGE" PENDING
  fi
}

install() {
  if installed_ok "$FLUTTER_DIR" "$FLUTTER_SHA256"; then
    ok "[flutter] SDK 已安装，跳过下载与解压"
    return 0
  fi
  if [ ! -f "$FLUTTER_DIR/.flit-complete" ] &&
     [ -x "$FLUTTER_DIR/bin/flutter" ] && [ -d "$FLUTTER_DIR/packages/flutter_tools" ]; then
    # 旧版脚本装的没有标记: 结构性认领一次并补标记, 避免给已装好的设备重下 1.2GB。
    # 只限"没有标记"; 标记在但 sha 不一致 = 清单升级, 必须走下面的重装
    ok "[flutter] 旧安装补记完整性标记"
    mark_installed "$FLUTTER_DIR" "$FLUTTER_SHA256"
    return 0
  fi

  mkdir -p "$TMPDIR" "$PREFIX/opt"
  T="$TMPDIR/flutter-sdk.tar.xz"
  if [ -f "$T" ]; then
    info "[flutter] 检查缓存安装包：$T"
    if echo "$FLUTTER_SHA256  $T" | sha256sum -c -; then
      ok "[flutter] 已找到通过校验的安装包，跳过下载"
    else
      warn "[flutter] 缓存校验失败，将重新下载"
      rm -f "$T"
      dl "$FLUTTER_SHA256" "$T" ${FLUTTER_URLS[@]+"${FLUTTER_URLS[@]}"}
    fi
  else
    dl "$FLUTTER_SHA256" "$T" ${FLUTTER_URLS[@]+"${FLUTTER_URLS[@]}"}
  fi

  info "[flutter] 解压（$(du -m "$T" | cut -f1) MB，需数分钟）…"
  rm -rf "$FLUTTER_DIR"
  tar -xJvf "$T" -C "$PREFIX/opt" || {
    rm -rf "$FLUTTER_DIR"
    die "[flutter] ✗ 解压失败，请查看上方 tar 错误"
  }
  [ -x "$FLUTTER_DIR/bin/flutter" ] || die "[flutter] ✗ 解压后组件不完整"

  # Android 无 /usr/bin/env 与 /bin/sh：重写整个 bin/树的脚本解释器。
  # 只改 bin/flutter 不够——internal/update_engine_version.sh 等会以自身 shebang 被直接执行。
  { grep -rlI '^#!/usr/bin/env \(ba\)\{0,1\}sh' "$FLUTTER_DIR/bin" || [ "$?" -eq 1 ]; } |
  while IFS= read -r f; do
    info "[flutter] 配置脚本解释器：$f"
    sed -i '1s|^#!/usr/bin/env \(ba\)\{0,1\}sh.*|#!'"$PREFIX"'/bin/bash|' "$f"
  done
  [ -x "$FLUTTER_DIR/bin/flutter" ] || die "[flutter] ✗ 脚本解释器配置失败"

  mark_installed "$FLUTTER_DIR" "$FLUTTER_SHA256"
  rm -f "$T"
  if [ -f "$FLUTTER_DIR/version" ]; then echo "__VER__$STAGE:$(cat "$FLUTTER_DIR/version")"; fi
  ok "[flutter] ✓ $FLUTTER_DIR"
}

stage_main "$@"
