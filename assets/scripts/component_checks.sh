# 安装前验收、环境检测、已安装列表和构建前检查共用这套只读判据。
# 这里不要求 .flit-complete：暂存目录尚未写标记，官方安装的 Platform 也可检查。
# 调用方负责根据场景检查安装标记；任何检测都不能执行会自行下载的 flutter。
tool_works() { [ -x "$1" ] && timeout 10 "$@" >/dev/null 2>&1; }
package_revision() {
  sed -n 's/^Pkg\.Revision[[:space:]]*=[[:space:]]*//p' "$1/source.properties" 2>/dev/null | head -1 | tr -d ' \r'
}
component_usable() {
  local component=$1 root=$2 expected=${3:-} actual
  case "$component" in
    platforms) [ -s "$root/android.jar" ] && [ -s "$root/source.properties" ] ;;
    build-tools)
      [ "$(package_revision "$root")" = "$expected" ] &&
        [ -s "$root/lib/d8.jar" ] && [ -f "$root/d8" ] && [ -f "$root/apksigner" ] &&
        [ -x "$root/aidl" ] && [ -x "$root/zipalign" ] &&
        tool_works "$root/aapt" version && tool_works "$root/aapt2" version ;;
    platform-tools) tool_works "$root/adb" version ;;
    cmdline-tools)
      [ -s "$root/bin/sdkmanager" ] &&
        [ -d "$root/lib" ] && [ -n "$(ls -A "$root/lib" 2>/dev/null)" ] ;;
    ndk)
      [ "$(package_revision "$root")" = "$expected" ] &&
        tool_works "$root/toolchains/llvm/prebuilt/linux-arm64/bin/clang" --version &&
        [ "$(readlink "$root/toolchains/llvm/prebuilt/linux-x86_64")" = linux-arm64 ] ;;
    cmake)
      actual=$(timeout 10 "$root/bin/cmake" --version 2>/dev/null | awk 'NR==1 {print $3}') || return 1
      [ "${actual%-dirty}" = "$expected" ] && [ "$(package_revision "$root")" = "$expected" ] &&
        tool_works "$root/bin/ninja" --version ;;
    *) return 1 ;;
  esac
}
