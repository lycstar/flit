#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 子任务 2-4: CMake(aarch64 android 静态构建, bin 内置 ninja)。
# AGP 对 externalNativeBuild 默认请求 cmake;3.22.1(flutter_pty 等原生插件);
# 缺包时 AGP 会自动下载官方 Linux x86_64 版(设备上 Exec format error),
# 这里预置正确架构, AGP 检测到已安装即不再下载。
# 中断与重试: 下载 .part 断点续传; 解压中断无标记则整目录清掉重解压。
. "$(dirname "$0")/lib.sh"
init_stage android_cmake

CMAKE_DIR="$ANDROID_HOME/cmake/$CMAKE_VERSION"

version() {
  [ -x "$CMAKE_DIR/bin/cmake" ] &&
    timeout 10 "$CMAKE_DIR/bin/cmake" --version 2>/dev/null | awk 'NR==1 { print $3 }'
}

tools_work() {
  _actual=$(version) && [ "${_actual%-dirty}" = "$CMAKE_VERSION" ] &&
    timeout 10 "$CMAKE_DIR/bin/ninja" --version >/dev/null 2>&1
}

verify_tools() {
  info '[cmake] 检查 CMake…'
  if _output=$(timeout 10 "$CMAKE_DIR/bin/cmake" --version 2>&1); then
    printf '%s\n' "$_output"
  else
    _rc=$?
    printf '%s\n' "$_output"
    die "[cmake] ✗ CMake 无法执行（退出码 $_rc），请查看上方错误"
  fi
  _actual=$(printf '%s\n' "$_output" | awk 'NR==1 { print $3 }')
  # CMake 为经过 Android 移植补丁修改的源码自动追加 -dirty。
  # 仅移除此构建标记；其他版本及 rc 等后缀仍不得冒充要求的正式版本。
  [ "${_actual%-dirty}" = "$CMAKE_VERSION" ] ||
    die "[cmake] ✗ CMake 版本不匹配：需要 ${CMAKE_VERSION}，实际 $_actual"
  info '[cmake] 检查 Ninja…'
  if _output=$(timeout 10 "$CMAKE_DIR/bin/ninja" --version 2>&1); then
    printf '%s\n' "$_output"
  else
    _rc=$?
    printf '%s\n' "$_output"
    die "[cmake] ✗ Ninja 无法执行（退出码 $_rc），请查看上方错误"
  fi
}

probe() {
  if installed_ok "$CMAKE_DIR" "$CMAKE_SHA256" && [ -s "$CMAKE_DIR/source.properties" ] && tools_work; then
    st "$STAGE" DONE
    echo "__VER__$STAGE:$(version)"
  else
    st "$STAGE" PENDING
  fi
}

install() {
  [[ "$CMAKE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die '[cmake] ✗ 无效的版本号'
  CMAKE_DIR="$ANDROID_HOME/cmake/$CMAKE_VERSION"
  if installed_ok "$CMAKE_DIR" "$CMAKE_SHA256" && tools_work; then
    printf 'Pkg.Revision=%s\n' "$CMAKE_VERSION" > "$CMAKE_DIR/source.properties"
    ok "[cmake] 已安装，跳过"
    return 0
  fi
  mkdir -p "$TMPDIR" "$ANDROID_HOME/cmake"
  T="$TMPDIR/cmake.tar.xz"
  dl "$CMAKE_SHA256" "$T" ${CMAKE_URLS[@]+"${CMAKE_URLS[@]}"}

  info "[cmake] 解压（$(du -m "$T" | cut -f1) MB）…"
  rm -rf "$CMAKE_DIR"
  # 包内顶层就是 <version>/, 解到 cmake/ 下即成标准 SDK 布局
  tar -xJf "$T" -C "$ANDROID_HOME/cmake" || {
    rm -rf "$CMAKE_DIR"
    die "[cmake] ✗ 解压失败，请查看上方 tar 错误"
  }
  [ -x "$CMAKE_DIR/bin/cmake" ] || die "[cmake] ✗ 解压后缺少 cmake"
  [ -x "$CMAKE_DIR/bin/ninja" ] || die "[cmake] ✗ 解压后缺少 ninja"
  verify_tools
  # 自家构建包没有 source.properties, 补一份供 AGP 按 Pkg.Revision 识别
  [ -f "$CMAKE_DIR/source.properties" ] ||
    printf 'Pkg.Revision=%s\n' "$CMAKE_VERSION" > "$CMAKE_DIR/source.properties"

  mark_installed "$CMAKE_DIR" "$CMAKE_SHA256"
  rm -f "$T"
  echo "__VER__$STAGE:$(version)"
  ok "[cmake] ✓ $CMAKE_DIR"
}

stage_main "$@"
