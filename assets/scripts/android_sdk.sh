#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# SDK 使用标准目录；按版本合并，保留已安装的其他工具链版本。
. "$(dirname "$0")/lib.sh"
init_stage android_sdk

_latest_build_tools() {
  ls -1 "$ANDROID_HOME/build-tools" 2>/dev/null | sort -V | tail -1 || true
}

# 显示已安装的最高 Android API
version() {
  __api=$(ls -1 "$ANDROID_HOME/platforms" 2>/dev/null | grep -oE '[0-9]+$' | sort -n | tail -1 || true)
  if [ -n "$__api" ]; then echo "API $__api"; fi
}

probe() {
  if installed_ok "$ANDROID_HOME"; then
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

  # 落位前执行安装包中的工具，避免错误架构覆盖当前可用版本。
  for _tool in "$_stage"/*/build-tools/*/aapt2; do
    [ -x "$_tool" ] && timeout 10 "$_tool" version >/dev/null 2>&1 ||
      die "[sdk] ✗ 安装包缺少可运行的 AAPT2，保留当前 SDK"
  done

  # platforms/build-tools/ndk/cmake/cmdline-tools 按子版本替换，其余目录整体替换。
  mkdir -p "$ANDROID_HOME"
  _found=0
  for _top in "$_stage"/*/; do
    [ -d "$_top" ] || continue
    _found=1
    for _entry in "$_top"* "$_top".[!.]*; do
      [ -e "$_entry" ] || continue
      _name=$(basename "$_entry")
      case "$_name" in
        platforms|build-tools|ndk|cmake|cmdline-tools)
          mkdir -p "$ANDROID_HOME/$_name"
          for _version in "$_entry"/*; do
            [ -e "$_version" ] || continue
            _dest="$ANDROID_HOME/$_name/$(basename "$_version")"
            rm -rf "$_dest"
            mv "$_version" "$_dest"
          done
          ;;
        *)
          rm -rf "${ANDROID_HOME:?}/$_name"
          mv "$_entry" "$ANDROID_HOME/$_name"
          ;;
      esac
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
