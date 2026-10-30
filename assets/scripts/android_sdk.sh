#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 固定 SDK 根目录，平台和 Build Tools 按版本累加；NDK/CMake 独立管理。
. "$(dirname "$0")/lib.sh"
init_stage android_sdk

component_complete() {
  local path=$1
  installed_ok "$ANDROID_HOME/$path" || return 1
  case "$path" in
    platforms/*) [ -s "$ANDROID_HOME/$path/android.jar" ] ;;
    build-tools/*) [ -x "$ANDROID_HOME/$path/aapt2" ] ;;
    platform-tools) [ -x "$ANDROID_HOME/$path/adb" ] ;;
    cmdline-tools/*) [ -f "$ANDROID_HOME/$path/bin/sdkmanager" ] ;;
    *) return 1 ;;
  esac
}
version() {
  ls -1 "$ANDROID_HOME/platforms" 2>/dev/null | sort -V | tail -1 || true
}
probe() {
  local platform=0 tools=0
  for dir in "$ANDROID_HOME"/platforms/*; do
    if component_complete "platforms/$(basename "$dir")"; then platform=1; fi
  done
  for dir in "$ANDROID_HOME"/build-tools/*; do
    if component_complete "build-tools/$(basename "$dir")"; then tools=1; fi
  done
  if [ "$platform$tools" = 11 ] && [ "$(readlink "$ANDROID_HOME/ndk")" = ../ndk ] &&
     [ "$(readlink "$ANDROID_HOME/cmake")" = ../cmake ]; then
    st "$STAGE" DONE
    echo "__VER__$STAGE:$(version)"
  else
    st "$STAGE" PENDING
  fi
}
install() {
  link_android_tools
  _receipt="$ANDROID_HOME/.flit-bundles/$SDK_SHA256"
  if [ -s "$_receipt" ]; then
    _complete=1
    while IFS= read -r _path; do
      component_complete "$_path" || _complete=0
    done < "$_receipt"
    if [ "$_complete" = 1 ]; then ok '[sdk] 该发行包的组件已安装，跳过'; return; fi
  fi
  T=$(archive_path "$SDK_SHA256")
  dl "$SDK_SHA256" "$T" "${SDK_URLS[@]}"
  _stage="$FLIT_TOOLCHAINS/.staging/android-sdk"
  rm -rf "$_stage"
  mkdir -p "$_stage"
  info "[sdk] 解压（$(du -m "$T" | cut -f1) MB）…"
  tar -xJvf "$T" -C "$_stage" || die '[sdk] 解压失败，已保留当前 SDK'
  _sdk="$_stage/android-sdk"
  [ -d "$_sdk/platforms" ] && [ -d "$_sdk/build-tools" ] || die '[sdk] 安装包缺少 platforms 或 build-tools'
  # 先验证全部组件，再写入正式目录。
  for dir in "$_sdk"/build-tools/*; do
    timeout 10 "$dir/aapt2" version || die '[sdk] 安装包缺少可运行的 AAPT2，保留当前 SDK'
  done
  for dir in "$_sdk"/platforms/*; do
    [ -s "$dir/android.jar" ] || die '[sdk] 安装包缺少 android.jar'
  done
  if [ -d "$_sdk/platform-tools" ]; then
    timeout 10 "$_sdk/platform-tools/adb" version || die '[sdk] ADB 无法执行，保留当前 SDK'
  fi
  # 自建归档的扁平 cmdline-tools 规范化为官方的 cmdline-tools/latest。
  if [ -d "$_sdk/cmdline-tools/bin" ]; then
    mv "$_sdk/cmdline-tools" "$_stage/command-line"
    mkdir -p "$_sdk/cmdline-tools"
    mv "$_stage/command-line" "$_sdk/cmdline-tools/latest"
  fi
  for dir in "$_sdk"/cmdline-tools/*; do
    [ ! -d "$dir" ] || [ -f "$dir/bin/sdkmanager" ] || die '[sdk] Command-line Tools 不完整'
  done
  : > "$_stage/receipt"
  for category in platforms build-tools cmdline-tools; do
    for dir in "$_sdk/$category"/*; do
      [ -d "$dir" ] || continue
      _path="$category/$(basename "$dir")"
      if component_complete "$_path"; then
        ok "[sdk] 保留已安装组件 $_path"
      else
        mark_installed "$dir" "$SDK_SHA256"
        publish_directory "$dir" "$ANDROID_HOME/$_path"
      fi
      echo "$_path" >> "$_stage/receipt"
    done
  done
  if [ -d "$_sdk/platform-tools" ]; then
    if ! component_complete platform-tools; then
      mark_installed "$_sdk/platform-tools" "$SDK_SHA256"
      publish_directory "$_sdk/platform-tools" "$ANDROID_HOME/platform-tools"
    fi
    echo platform-tools >> "$_stage/receipt"
  fi
  # licenses 不参与版本选择；SDK 包中的 ndk/cmake 不得覆盖统一链接。
  if [ -d "$_sdk/licenses" ]; then
    mkdir -p "$ANDROID_HOME/licenses"
    cp -a "$_sdk/licenses/." "$ANDROID_HOME/licenses/"
  fi
  mkdir -p "$(dirname "$_receipt")"
  mv "$_stage/receipt" "$_receipt"
  rm -rf "$_stage"
  rm -f "$T"
  echo "__VER__$STAGE:$(version)"
  ok "[sdk] ✓ $ANDROID_HOME"
}

stage_main "$@"
