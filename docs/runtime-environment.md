# 设备端开发环境

本仓库维护安装协议，不重复维护工具链构建配方。产物由 README 中列出的伴生仓库构建与发布。

## 安装顺序

1. 下载 bootstrap，校验 SHA-256，原生安装器按官方包布局部署基础环境。
2. 安装 OpenJDK、Android SDK、NDK，并配置 Gradle 使用 Android 宿主工具。
3. 安装 Git、GitHub CLI、Flutter SDK，执行预热和最终检测。

所有必要组件就绪才允许正常开发。一个子任务对应一个脚本，`--check` 探测和安装逻辑放在同一个文件，避免页面自行推断工具是否安装。脚本输出通过 PTY 原样展示，控制器只解析阶段标记和版本信息。

## 发行清单

`assets/toolchain_manifest.json` 是默认安装地址与摘要的唯一来源。每个归档记录版本、下载地址、SHA-256、体积和安装位置；`aptSource` 定义 JDK/Git/gh 的软件源。`SetupRunner` 根据清单生成 `$HOME/.flit/env.sh`，仅安装动作改写 APT 配置，打开终端不会改写软件源。

bootstrap 和 APT 软件包必须为 `/data/data/cc.lycstar.flit/files/usr` 构建；SDK/NDK/Flutter 需要 Android bionic aarch64 宿主二进制。不得将桌面 Linux 工具或其他应用前缀的包直接安装进来。SHA-256 只能证明内容符合清单，不能证明二进制兼容。

内置摘要随应用固定，默认安装无需额外请求 GitHub API。生成的 `env.sh` 只供脚本读取，不作为独立维护的清单。安装目录中的 `.flit-complete` 仅在安装及后处理成功后写入，记录已安装归档的摘要；它不提供下载前的预期校验值。

## 版本目录

默认安装使用清单中的固定版本；版本目录默认查询 Flit 的配套 GitHub Releases 仓库。可通过以下构建参数覆盖仓库，值为 `owner/repository`：

| Dart define | 组件 |
| --- | --- |
| `FLIT_BOOTSTRAP_REPO` | 基础环境 |
| `FLIT_ANDROID_SDK_REPO` | Android SDK |
| `FLIT_NDK_REPO` | Android NDK |
| `FLIT_FLUTTER_SDK_REPO` | Flutter SDK |

版本目录安装直接使用 GitHub Release 资产的 `digest`（SHA-256），不写回内置清单，也不另存一份远程校验清单。缺少有效 SHA-256 的资产拒绝安装。SDK 和 Flutter 复用默认安装脚本；NDK 按 `Pkg.Revision` 并存。

Flutter SDK 存放于 `$PREFIX/opt/flutter/<版本>/`，`current` 相对软链接指向当前版本。终端、分析器和初始化脚本统一使用 `current`；`FLUTTER_ROOT` 与 PATH 指向该入口。版本目录同时显示本地已安装版本，可离线切换。切换前须关闭项目，工作台终端会停止，新打开的终端使用当前版本。安装先在临时目录解压并完成配置，成功后才替换 `current`，失败保留原版；默认初始化不会切回内置版本。旧单版本安装首次执行安装步骤时整体迁入版本目录，保留缓存。旧版本不会自动删除。

显式设为空字符串的目录不发出请求；页面会区分未配置、请求失败和无匹配版本。只配置经过兼容性验证的仓库；匿名下载不支持私有资产，不能把个人令牌写进应用。安装目录和资产名模式见 `ToolchainCatalog.components`。

## 发布验证

更新清单前核验下载地址、SHA-256、归档结构、NDK `source.properties` 与目录版本、应用前缀和动态库依赖。然后在干净的 arm64 Android 设备上验证初始化、新建/克隆、依赖解析、分析服务、APK 构建、ADB 安装运行、热重载及 Web 预览。

自动测试与本地 APK 编译覆盖应用代码及安装协议，不能替代这些设备端验证。当前发布准备不包含修改仓库可见性或重跑 GitHub APK 发布工作流。
