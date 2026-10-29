#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 子任务 2-2: Android SDK(Homu bionic aarch64 移植; tar 顶层无版本后缀, mv 兜底)。
# 中断与重试:
#   下载中断 → .part 断点续传(dl 内置);
#   解压中断 → 临时目录里的半成品整段丢弃重解压(缓存包还在, 不重下);
#   落位: 只覆盖 tarball 里有的顶层条目, 不整目录 rm -rf——$ANDROID_HOME 里还住着
#   NDK(2-3 装的), 重装 SDK 绝不能连带删掉它;
#   完整性: 标记在落位之后才写, 目录存在不算装好。
. "$(dirname "$0")/lib.sh"
init_stage android_sdk

_latest_build_tools() {
  ls -1 "$ANDROID_HOME/build-tools" 2>/dev/null | sort -V | tail -1 || true
}

# platforms 目录可由首次 Gradle 构建补装, 缺它不算未装
version() {
  __api=$(ls -1 "$ANDROID_HOME/platforms" 2>/dev/null | grep -oE '[0-9]+$' | sort -n | tail -1 || true)
  if [ -n "$__api" ]; then echo "API $__api"; fi
}

probe() {
  if installed_ok "$ANDROID_HOME" "$SDK_SHA256"; then
    st "$STAGE" DONE
    echo "__VER__$STAGE:$(version)"
  else
    st "$STAGE" PENDING
  fi
}

install() {
  if installed_ok "$ANDROID_HOME" "$SDK_SHA256"; then
    ok "[sdk] 已安装，跳过"
    return 0
  fi
  _bt=$(_latest_build_tools)
  if [ ! -f "$ANDROID_HOME/.flit-complete" ] &&
     [ -n "$_bt" ] && [ -x "$ANDROID_HOME/build-tools/$_bt/aapt2" ]; then
    # 旧版脚本装的没有标记: 结构性认领一次并补标记, 避免给已装好的设备重下。
    # 只限"没有标记"; 标记在但 sha 不一致 = 清单升级, 必须走下面的重装
    ok "[sdk] 旧安装补记完整性标记"
    mark_installed "$ANDROID_HOME" "$SDK_SHA256"
    return 0
  fi

  mkdir -p "$TMPDIR"
  T="$TMPDIR/android-sdk.tar.xz"
  dl "$SDK_SHA256" "$T" ${SDK_URLS[@]+"${SDK_URLS[@]}"}

  info "[sdk] 解压（$(du -m "$T" | cut -f1) MB，需 1–2 分钟）…"
  _stage="$TMPDIR/android-sdk.extract"
  rm -rf "$_stage"
  mkdir -p "$_stage"
  tar -xJvf "$T" -C "$_stage" || {
    rm -rf "$_stage"
    die "[sdk] ✗ 解压失败，请查看上方 tar 错误"
  }

  # 合并落位: 顶层 android-sdk/ 或 android-sdk-*/ 下的每个条目覆盖同名旧条目
  mkdir -p "$ANDROID_HOME"
  _found=0
  for _top in "$_stage"/*/; do
    [ -d "$_top" ] || continue
    _found=1
    for _entry in "$_top"* "$_top".[!.]*; do
      [ -e "$_entry" ] || continue
      _name=$(basename "$_entry")
      rm -rf "${ANDROID_HOME:?}/$_name"
      mv "$_entry" "$ANDROID_HOME/$_name"
    done
  done
  rm -rf "$_stage"
  [ "$_found" = 1 ] || die "[sdk] ✗ 安装包顶层目录不符合预期"
  [ -d "$ANDROID_HOME/build-tools" ] || die "[sdk] ✗ 解压后缺少 build-tools"
  _bt=$(_latest_build_tools)
  [ -n "$_bt" ] && [ -x "$ANDROID_HOME/build-tools/$_bt/aapt2" ] ||
    die "[sdk] ✗ 解压后缺少可执行的 aapt2"

  mark_installed "$ANDROID_HOME" "$SDK_SHA256"
  rm -f "$T"
  echo "__VER__$STAGE:$(version)"
  ok "[sdk] ✓ $ANDROID_HOME"
}

stage_main "$@"
