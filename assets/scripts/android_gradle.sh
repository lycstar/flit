#!/data/data/cc.lycstar.flit/files/usr/bin/bash
# 子任务 2-4: Gradle 全局配置——AGP 默认从 maven 拉 x86_64 的 aapt2, arm64 必败,
# 指向本机 build-tools 内的 aapt2(真机实测必须); 顺带 jvmargs 内存上限。
# 中断与重试: 全是对 gradle.properties 的幂等编辑(grep 判定/sed 原地/追加),
# 重跑结果相同; 用户自己加的其它配置项原样保留。依赖 2-2 的 build-tools。
. "$(dirname "$0")/lib.sh"
init_stage android_gradle

_props="$GRADLE_USER_HOME/gradle.properties"
_latest_build_tools() {
  ls -1 "$ANDROID_HOME/build-tools" 2>/dev/null | sort -V | tail -1 || true
}

probe() {
  _bt=$(_latest_build_tools)
  if [ -n "$_bt" ] && [ -x "$ANDROID_HOME/build-tools/$_bt/aapt2" ] &&
     grep -q "^android\.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/$_bt/aapt2\$" "$_props" 2>/dev/null; then
    st "$STAGE" DONE
  else
    st "$STAGE" PENDING
  fi
}

install() {
  _bt=$(_latest_build_tools)
  { [ -n "$_bt" ] && [ -x "$ANDROID_HOME/build-tools/$_bt/aapt2" ]; } ||
    die "[gradle] ✗ 缺少 Android SDK 的 build-tools/aapt2，请先完成 2-2"
  mkdir -p "$GRADLE_USER_HOME"
  touch "$_props"
  _aapt2="$ANDROID_HOME/build-tools/$_bt/aapt2"
  if grep -q '^android\.aapt2FromMavenOverride=' "$_props"; then
    sed -i "s|^android\.aapt2FromMavenOverride=.*|android.aapt2FromMavenOverride=$_aapt2|" "$_props"
  else
    printf '\nandroid.aapt2FromMavenOverride=%s\n' "$_aapt2" >> "$_props"
  fi
  if ! grep -q '^org\.gradle\.jvmargs=' "$_props"; then
    printf '\n%s\n' 'org.gradle.jvmargs=-Xmx4g' >> "$_props"
  fi
  grep -q "^android\.aapt2FromMavenOverride=$_aapt2\$" "$_props" ||
    die "[gradle] ✗ 配置写入后校验失败"
  info "[gradle] aapt2Override → build-tools/$_bt/aapt2"
}

stage_main "$@"
