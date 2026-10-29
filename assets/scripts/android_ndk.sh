#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 子任务 2-3: NDK r28(aarch64 包用 arm64 工具冒充 x86_64 查找路径, 解压后重建两处软链)。
# 中断与重试:
#   下载中断 → .part 断点续传;
#   解压/建链中断 → 无标记 → 整个 $NDK_DIR 清掉重解压(它是自己的目录, 可以整删);
#   安装包留到标记落盘才删, 后处理被打断时重试直接解压不重下。
. "$(dirname "$0")/lib.sh"
init_stage android_ndk

NDK_DIR="$ANDROID_HOME/ndk/$NDK_VERSION"

version() {
  __rev=$(sed -n 's/^Pkg.Revision[[:space:]]*=[[:space:]]*//p' "$NDK_DIR/source.properties" 2>/dev/null | cut -d. -f1,2)
  echo "${__rev:+r$__rev}"
}

probe() {
  if installed_ok "$NDK_DIR" "$NDK_SHA256"; then
    st "$STAGE" DONE
    echo "__VER__$STAGE:$(version)"
  else
    st "$STAGE" PENDING
  fi
}

install() {
  if installed_ok "$NDK_DIR" "$NDK_SHA256"; then
    ok "[ndk] 已安装，跳过"
    return 0
  fi
  if [ ! -f "$NDK_DIR/.flit-complete" ] && [ -f "$NDK_DIR/source.properties" ] &&
     [ -x "$NDK_DIR/toolchains/llvm/prebuilt/linux-arm64/bin/clang" ]; then
    # 只限"没有标记"; 标记在但 sha 不一致 = 清单升级, 走重装
    ok "[ndk] 旧安装补记完整性标记"
    mark_installed "$NDK_DIR" "$NDK_SHA256"
    return 0
  fi

  mkdir -p "$TMPDIR"
  T="$TMPDIR/ndk.tar.xz"
  dl "$NDK_SHA256" "$T" ${NDK_URLS[@]+"${NDK_URLS[@]}"}

  info "[ndk] 解压（$(du -m "$T" | cut -f1) MB）…"
  rm -rf "$NDK_DIR"
  mkdir -p "$NDK_DIR"
  # 包内 x86_64→arm64 的兼容软链与解压顺序冲突, 排除掉两处后统一重建;
  # 其它任何 tar 错误都视为失败, 不让半截安装冒充成功。
  tar -xJvf "$T" -C "$NDK_DIR" --strip-components=1 \
    --exclude='*/shader-tools/linux-x86_64*' \
    --exclude='*/toolchains/llvm/prebuilt/linux-x86_64*' || {
    rm -rf "$NDK_DIR"
    die "[ndk] ✗ 解压失败，请查看上方 tar 错误"
  }
  ln -sfn linux-arm64 "$NDK_DIR/shader-tools/linux-x86_64"
  ln -sfn linux-arm64 "$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
  [ -f "$NDK_DIR/source.properties" ] || die "[ndk] ✗ 解压后缺少 source.properties"
  [ -x "$NDK_DIR/toolchains/llvm/prebuilt/linux-arm64/bin/clang" ] ||
    die "[ndk] ✗ 解压后缺少 LLVM Clang"

  mark_installed "$NDK_DIR" "$NDK_SHA256"
  rm -f "$T"
  echo "__VER__$STAGE:$(version)"
  ok "[ndk] ✓ $NDK_DIR"
}

stage_main "$@"
