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
: "${CMAKE_VERSION:=3.22.1}"
: "${TMPDIR:=$PREFIX/tmp}"
: "${FLIT_APT_SOURCE:=}"
# 阶段变量兜底(旧版 env.sh 缺字段时防 set -u 中断; 正常由 app 生成完整 env.sh)
: "${SDK_SHA256:=}"; : "${NDK_SHA256:=}"
: "${CMAKE_SHA256:=}"
: "${FLUTTER_SHA256:=}"
: "${FLUTTER_VERSION:=3.47.8}"

# curl 的证书查找路径编译期烧死外部前缀, 重定向到本环境证书(HTTPS 必需)
if [ -f "$PREFIX/etc/tls/cert.pem" ]; then
  export CURL_CA_BUNDLE="$PREFIX/etc/tls/cert.pem"
  export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
fi

# 阶段状态标记: app 侧以此驱动步骤面板
st() { echo "__STAGE__$1:$2"; }

# 安装完整性标记: 解压与后处理全部成功后才写入(内容=来源 tarball 的 sha256)。
# 不传摘要时只检测完整安装状态；指定摘要时判断是否为本次要安装的产物。
# 版本目录可以安装非默认版本，状态探测不能强制要求内置清单的摘要。
installed_ok() {
  [ -s "$1/.flit-complete" ] &&
    { [ -z "${2:-}" ] || [ "$(cat "$1/.flit-complete" 2>/dev/null)" = "$2" ]; }
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

# 上次安装中断后先完成包配置；失败输出必须保留。
apt_repair() {
  dpkg --configure -a || die '[apt] 软件包配置失败，请查看上方具体错误'
}

# 子任务脚本骨架: 脚本定义 probe()(零副作用探测: 发 __STAGE__/__VER__, 恒退出 0)
# 与 install()(幂等安装, 成功结尾由这里发 DONE), 文件末尾 stage_main "$@"。
#   bash x.sh --check → 只探测(check.sh 循环调用)
#   bash x.sh         → 安装
stage_main() {
  case "${1:-}" in
    --check) probe ;;
    --release)
      [ "$#" -ge 3 ] || die '安装版本需要下载地址和 SHA-256'
      case "$STAGE" in
        android_sdk) SDK_URLS=("$2"); SDK_SHA256=$3 ;;
        android_cmake) CMAKE_URLS=("$2"); CMAKE_SHA256=$3; CMAKE_VERSION=${4:?缺少版本号} ;;
        flutter_sdk) FLUTTER_URLS=("$2"); FLUTTER_SHA256=$3; FLUTTER_VERSION=${4:?缺少版本号} ;;
        *) die '该组件不支持版本切换' ;;
      esac
      st "$STAGE" RUNNING
      install --release
      st "$STAGE" DONE
      ;;
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
    # 校验失败后，同一地址只从头重下一个完整文件；不能跳过校验。
    for _dl_attempt in 1 2; do
      if curl -fsSL -C - --retry 3 --connect-timeout 30 -o "$_dl_dest.part" "$_dl_url"; then
        _dl_bytes=$(wc -c < "$_dl_dest.part" | tr -d ' ')
        _dl_actual=$(sha256sum "$_dl_dest.part" | cut -d' ' -f1)
        info "[dl] 文件大小：${_dl_bytes} 字节"
        info "[dl] SHA-256 期望：${_dl_sha}"
        info "[dl] SHA-256 实际：${_dl_actual}"
        if [ "$_dl_actual" = "$_dl_sha" ]; then
          mv "$_dl_dest.part" "$_dl_dest"
          kill "$_dl_pid" 2>/dev/null
          wait "$_dl_pid" 2>/dev/null || true
          printf '\n'
          ok "[dl] 下载并校验通过"
          return 0
        fi
        rm -f "$_dl_dest.part"
        if [ "$_dl_attempt" = 1 ]; then
          warn '[dl] 文件校验失败，清除下载内容后从头重试同一地址'
          continue
        fi
        warn '[dl] 重新下载后校验仍失败，请核对发行清单，或检查代理/下载服务是否改变文件内容'
      else
        warn '[dl] 下载失败，保留断点；下次安装可继续下载'
        break
      fi
    done

  done
  kill "$_dl_pid" 2>/dev/null
  wait "$_dl_pid" 2>/dev/null || true
  printf '\n'
  bad "[dl] ✗ 所有下载源均失败，请检查下载地址、网络和校验信息后重试"
  return 1
}
