# flit setup 公共库: 状态标记协议 + 多源下载校验。
# 被各阶段脚本 source; 也可在 Termux 里独立 source 后复用 dl()。
set -Eeuo pipefail
umask 022

# 环境注入(app 生成; 独立运行时有内置默认值)
if [ -f "$HOME/.flit/env.sh" ]; then
  . "$HOME/.flit/env.sh" || {
    printf '\033[1;31m%s\033[0m\n' '[env] ✗ 加载环境变量失败，已停止当前步骤'
    exit 1
  }
fi
: "${PREFIX:=/data/data/cc.lycstar.flit/files/usr}"
: "${ANDROID_HOME:=$HOME/android-sdk}"
: "${JAVA_HOME:=$PREFIX/lib/jvm/java-17-openjdk}"
: "${GRADLE_USER_HOME:=$HOME/.gradle}"
: "${NDK_VERSION:=28.2.13676358}"
: "${TMPDIR:=$PREFIX/tmp}"
: "${FLIT_APT_SOURCE:=}"
# 阶段变量兜底(旧版 env.sh 缺字段时防 set -u 中断; 正常由 app 生成完整 env.sh)
: "${SDK_SHA256:=}"; : "${NDK_SHA256:=}"
: "${FLUTTER_SHA256:=}"

# curl 的证书查找路径编译期烧死外部前缀, 重定向到本环境证书(HTTPS 必需)
if [ -f "$PREFIX/etc/tls/cert.pem" ]; then
  export CURL_CA_BUNDLE="$PREFIX/etc/tls/cert.pem"
  export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
fi

# 阶段状态标记: app 侧以此驱动步骤面板
st() { echo "__STAGE__$1:$2"; }

# 安装完整性标记: 解压与后处理全部成功后才写入(内容=来源 tarball 的 sha256)。
# 目录存在 ≠ 装好——解压中途被停也有目录; 标记在且 sha 一致 = 完整且为当前清单版本,
# sha 不一致 = manifest 升级 → 视为未装, 重试清目录重解压(缓存包在则免下载)。
installed_ok() {
  [ -f "$1/.flit-complete" ] &&
    [ "$(cat "$1/.flit-complete" 2>/dev/null)" = "$2" ]
}
mark_installed() { printf '%s\n' "$2" > "$1/.flit-complete"; }

# 终端着色(ANSI, app 终端原样渲染): 成功绿/失败红/警示黄/次要灰
ok() { printf '\033[1;32m%s\033[0m\n' "$*"; }
bad() { printf '\033[1;31m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*"; }
info() { printf '\033[36m%s\033[0m\n' "$*"; }
dim() { printf '\033[2m%s\033[0m\n' "$*"; }

# 显式失败退出(会补发 FAILED 标记; exit 不触发 ERR trap)
die() {
  bad "$*"
  st "${STAGE:-unknown}" FAILED
  exit 1
}

# 用法: init_stage <id>  —— 声明阶段 id 与错误陷阱(失败发 FAILED 后退出)。
# RUNNING 由 stage_main 在真正安装时才发: --check 只探测, 不许翻转面板状态。
init_stage() {
  STAGE=$1
  trap '_flit_error=$?; bad "[$STAGE] ✗ 命令失败（退出码 ${_flit_error}，第 ${LINENO} 行）：$BASH_COMMAND"; st "$STAGE" FAILED; exit "$_flit_error"' ERR
}

# 旧 bootstrap 收进了构建时顺带生成的 dpkg 开发子包，却没有 clang。
# 仅迁移这个已知版本；不删除 dpkg，也不强制绕过其他包的依赖检查。
apt_repair() {
  if [ "$(dpkg-query -W -f='${Version}' dpkg-perl 2>/dev/null || true)" = '1.22.6-5' ] &&
     ! command -v clang >/dev/null 2>&1; then
    warn '[apt] 修复旧基础环境：移除误装的 dpkg 开发子包（保留 dpkg）'
    dpkg --remove dpkg-scanpackages dpkg-perl ||
      die '[apt] 旧基础环境修复失败，请查看上方依赖信息'
  fi
  dpkg --configure -a || die '[apt] 软件包配置失败，请查看上方具体错误'
}

# 子任务脚本骨架: 脚本定义 probe()(零副作用探测: 发 __STAGE__/__VER__, 恒退出 0)
# 与 install()(幂等安装, 成功结尾由这里发 DONE), 文件末尾 stage_main "$@"。
#   bash x.sh --check → 只探测(check.sh 循环调用)
#   bash x.sh         → 安装
stage_main() {
  case "${1:-}" in
    --check) probe ;;
    *)
      st "$STAGE" RUNNING
      install
      st "$STAGE" DONE
      ;;
  esac
}

# APT configuration belongs to installation, not to env.sh. Sourcing an
# environment file must never rewrite package-manager state as a side effect.
configure_apt() {
  [ -n "$FLIT_APT_SOURCE" ] || die "[apt] 未配置适配 Flit 的软件源"
  rm -f "$PREFIX/etc/apt/sources.list"
  mkdir -p "$PREFIX/etc/apt/sources.list.d"
  printf 'deb [trusted=yes] %s\n' "$FLIT_APT_SOURCE" \
    > "$PREFIX/etc/apt/sources.list.d/flit.list"
  info "[apt] 软件源：$FLIT_APT_SOURCE"
}

# 用法: dl <sha256> <dest> <url...>  逐源尝试, sha256 通过才收货
dl() {
  _dl_sha=$1; _dl_dest=$2
  shift 2
  mkdir -p "$(dirname "$_dl_dest")"

  # 单行进度: 每秒采样 .part 实际体积, \r 原地刷新。
  # 不用 curl 的进度条——它在 PTY 里对终端宽度探测和 \r 重绘都不可靠,
  # 续传/重试时动辄退化成满屏换行。
  (
    # kill -0 $$: 父脚本退出(如 die)后采样自动退出, 不留孤儿占用输出管道
    while kill -0 "$$" 2>/dev/null; do
      if [ -f "$_dl_dest.part" ]; then
        printf '\r[dl] 已下载 %s MB' "$(du -m "$_dl_dest.part" 2>/dev/null | cut -f1)"
      fi
      sleep 1
    done
  ) &
  _dl_pid=$!

  _dl_ok=1
  for _dl_url in "$@"; do
    # -C -: 无半成品从头下, 有 .part 则从断点续传(多镜像字节相同, sha256 终审)
    if [ -f "$_dl_dest.part" ]; then
      info "[dl] 从断点续传：$_dl_url"
    else
      info "[dl] 下载：$_dl_url"
    fi
    # -sS: curl 自己的进度输出全关, 错误照常可见
    if curl -fsS -C - --retry 3 --connect-timeout 30 -o "$_dl_dest.part" "$_dl_url"; then
      info "[dl] 校验 SHA-256（期望：${_dl_sha}）"
      if echo "$_dl_sha  $_dl_dest.part" | sha256sum -c -; then
        mv "$_dl_dest.part" "$_dl_dest"
        kill "$_dl_pid" 2>/dev/null
        wait "$_dl_pid" 2>/dev/null || true
        printf '\n'
        ok "[dl] 下载并校验通过"
        return 0
      fi
      warn "[dl] 文件校验失败，正在尝试下一个下载源"
    else
      warn "[dl] 下载失败，正在尝试下一个下载源"
    fi
    rm -f "$_dl_dest.part"
  done
  kill "$_dl_pid" 2>/dev/null
  wait "$_dl_pid" 2>/dev/null || true
  printf '\n'
  bad "[dl] ✗ 所有下载源均失败，请检查下载地址、网络和校验信息后重试"
  return 1
}
