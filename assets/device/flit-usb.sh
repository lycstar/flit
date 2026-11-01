#!/system/bin/sh
# Flit USB 激活助手 —— 目标等价于电脑执行 `adb -d tcpip 5555`:
# 让本机 adbd 监听 TCP 5555, Flit 即可通过 127.0.0.1:5555 自连。
# 由 Flit 写入应用外部 files 目录, 电脑上执行(参考 Shizuku 的启动脚本):
#   adb shell sh /storage/emulated/0/Android/data/cc.lycstar.flit/files/flit-usb.sh
# 输出用 ASCII 英文, 避免电脑终端(尤其 Windows)中文代码页乱码。

PORT=5555
PROP=service.adb.tcp.port

echo "* Flit USB activation (Android $(getprop ro.build.version.release))"

if [ "$(getprop $PROP)" = "$PORT" ]; then
  echo "* Already configured. If Flit cannot connect yet, unplug and"
  echo "* replug the USB cable once, then tap connect in Flit."
  exit 0
fi

# Android 11 及以下: 该属性标为 shell_prop, shell 可写;
# Android 12+: 收紧为 adbd_config_prop, 系统拒绝写入。
setprop $PROP $PORT 2>/dev/null
if [ "$(getprop $PROP)" != "$PORT" ]; then
  echo "* This system denies device-side activation (Android 12+)."
  echo "* Run instead on the PC:  adb -d tcpip $PORT"
  exit 2
fi

# shell 无法直接 ctl 重启 adbd, 依次尝试 gadget 复位 / ctl / stop-start;
# 重启会断开当前 adb 会话, 所以提示要在重启动作之前输出。
echo "* TCP port set. Restarting adbd — the PC connection may drop now."
echo "* Unplug and replug the USB cable once if Flit still cannot connect,"
echo "* then go back to Flit and tap the connect button."
(svc usb resetUsbGadget 2>/dev/null || setprop ctl.restart adbd 2>/dev/null ||
  { stop adbd 2>/dev/null; start adbd 2>/dev/null; }) || true
