# 设备连接与页面约定

## ADB

- `DeviceConnection` 持有设备快照、操作结果与专用 `ConsoleSession`。页面仅持有输入框、终端展开状态及系统设置入口。
- 配对、连接、断开串行执行。配对需要退出码为 0 且收到 ADB 的成功回执；配对记录只表示历史，不能作为当前认证结果。
- 连接以目标地址在 `adb devices -l` 中进入 `device` 状态为准。`unauthorized`、`offline`、认证失败、拒绝连接和读取失败分别反馈。运行目标仍只接收在线设备。
- 查询和可用性检查加载与终端操作相同的 `env.sh`。脚本优先使用 SDK platform-tools，避免查询选中另一份 Termux ADB，导致不同版本争用服务。
- 刷新采用递增版本号，旧查询不能覆盖新操作。返回前台时刷新；离开页面会停止未结束的客户端命令，不删除密钥、不重启 ADB server，也不主动断开其他设备。
- 配对使用系统配对码弹窗的端口；连接使用无线调试主页的端口。断开针对单个 serial，不清除系统配对授权。

## 本机发现与通知配对

面向用户的完整步骤见 [无线配对指南](wireless-pairing.md)，应用内“通知配对”与“无线配对指南”入口共用 `DevicePairingGuidePage`。包含 MIUI 原生通知样式、通知权限、后台网络限制和手动配对替代步骤。

- 教程离线可读，阅读或退出不启动服务；点击“开始配对”后返回设备页，由现有串行入口先启动通知再打开系统设置。
- `pairingReadiness` 只读系统版本、通知总开关和配对渠道，不创建通知渠道、不启动扫描；从设置返回时重查。过期读取和页面销毁后的结果被忽略，读取失败显示未知而不误报已允许。
- 通知样式不是 Android 通用权限，指南不声称能够自动读取或修改 MIUI / HyperOS 的样式。

- “扫描并连接”先试本机最近成功端口，再通过 Android NSD 发现 `_adb-tls-connect._tcp`。只发现 ADB 服务，不对局域网或任意端口做盲扫；配对服务使用独立的 `_adb-tls-pairing._tcp`。
- 对照 [Shizuku AdbMdns](https://github.com/RikkaApps/Shizuku/blob/master/manager/src/main/java/moe/shizuku/manager/adb/AdbMdns.kt)，同时检查广播地址属于本机网卡及本机端口占用。跨扫描入口串行解析，失败限次重试，服务消失即失效。原生发现有效结果立即返回；Dart 超时比原生截止时间多 2 秒，避免先丢掉结果。
- “通知配对”先启动前台服务，再打开开发者选项。用户保持系统配对窗口打开，从通知输入 6 位码；不用切回 Flit。服务使用同一个 `FlitEnv`、SDK ADB 和 HOME 密钥，通过 stdin 输入配对码，不保存或记录配对码。
- 服务最多等待 3 分钟，ADB 配对命令最多 30 秒；取消时停止扫描和配对客户端，进程被杀后不重放配对请求。只持久化状态结果，返回页面后自动连接。通知被关闭时提示开启，不假装已启动。
- 参考 [Shizuku AdbPairingService](https://github.com/RikkaApps/Shizuku/blob/master/manager/src/main/java/moe/shizuku/manager/adb/AdbPairingService.kt) 的通知交互方式；Flit 配对仍由自带 ADB 执行。需要 Android 11 及以上。其他设备配对保留手动入口，不错误地跳到本机自动连接。
- 自动连接只认可目标地址的 `device` 状态，并等待短暂的上线延迟。认证失败与扫描失败、端口拒绝分别处理；单凭发现广播不能断言“未配对”。

## 电脑 USB 激活

- 页面参考 Shizuku 的“状态 + 无线调试 + 电脑启动”卡片结构，见 [home_start_adb.xml](https://github.com/RikkaApps/Shizuku/blob/master/manager/src/main/res/layout/home_start_adb.xml) 和 [StartAdbViewHolder](https://github.com/RikkaApps/Shizuku/blob/master/manager/src/main/java/moe/shizuku/manager/home/StartAdbViewHolder.kt)。Flit 使用完整 ADB 连接供 Flutter 运行、调试和端口转发；不启动 Shizuku 的 Binder 权限服务。
- 电脑安装 Platform Tools，手机打开 USB 调试并授权，电脑执行 `adb devices`、`adb -d tcpip 5555`。`-d` 限定 USB 目标，多个 USB 设备连接时会拒绝执行，指南要求只连接当前手机。
- `DeviceUsbGuide` 单独维护指南、电脑系统选择和复制操作。Windows PowerShell 使用 `.\adb.exe`，macOS/Linux 使用 `./adb`，均在解压后的 Platform Tools 目录执行。页面不会把这些命令交给手机终端。
- `DeviceConnection.connectUsb()` 只连接 `127.0.0.1:5555`，不等待 NSD，也不调用 `adb pair`。只有该目标在 `adb devices -l` 中处于 `device` 才算成功；局域网或其他无线端口在线不算成功。
- 授权失败引导确认手机上的 USB 调试授权；拒绝连接引导重新执行电脑命令，不误导到无线配对。成功后可拔线，通常无需 Wi-Fi；重启后一般需要重新激活，厂商限制仍需真机验证。
- TCP 调试可能监听其他网络接口。接回电脑执行 `adb -d usb` 可切回 USB 模式；Flit 的“断开”只断开客户端，不关闭 adbd 的 TCP 监听。
- 保存最后成功的连接方式，重新进页按该方式重连。显式选择无线连接时，不复用 USB 缓存端口；通知配对结果按 revision 只处理一次，防止旧成功结果覆盖后来的 USB 选择。首次进入无历史记录时只读状态，不自动启动扫描并显示错误。

## 页面

- 默认显示设备状态、无线调试卡片和电脑 USB 激活卡片；手动地址、端口折叠显示，通知配对帮助使用独立页面。电脑操作指南按需打开，支持复制命令和执行后的连接。日志默认收起，操作不强制抢占表单空间。
- `PageContent` / `PageList` 统一安全区域、16px 页面边距和 800px 表单最大宽度；颜色、字体和卡片复用应用主题。
- `PageIntro`、`StatusNotice`、`SettingsSlider` 统一说明、错误反馈与手机滑块布局。
- Flutter / Dart 创建分别检查对应命令，忽略过时的检查结果；创建和克隆在返回参数前检查目标目录，失败后保留表单。
- 环境变量页展示新任务环境的只读快照。使用 `env -0` 保留多行值，检查退出码，搜索结果直接展示，展开后可选择或复制完整值。

## 验证

`device_connection_test.dart` 覆盖认证状态、失败退出码、并发操作、陈旧刷新与启动失败；`device_connect_page_test.dart` 覆盖配对重试、等待上线及页面生命周期；`settings_pages_test.dart` 覆盖环境变量、创建检查与手机/横屏/平板布局。

自动测试不能替代 Android 真机的系统授权弹窗、无线网络变化及厂商后台限制验证。
