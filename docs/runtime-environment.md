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

## 可选版本目录

默认 APK 使用清单中固定的版本。可通过构建参数为环境页启用 GitHub Releases 版本目录，值为 `owner/repository`：

| Dart define | 组件 |
| --- | --- |
| `FLIT_BOOTSTRAP_REPO` | 基础环境 |
| `FLIT_ANDROID_SDK_REPO` | Android SDK |
| `FLIT_NDK_REPO` | Android NDK |
| `FLIT_FLUTTER_SDK_REPO` | Flutter SDK |

未配置的目录不发出请求，也不会提供版本切换选项。只配置经过兼容性验证的仓库；匿名下载不支持私有资产，不能把个人令牌写进应用。安装目录和资产名模式见 `ToolchainCatalog.components`。

## 发布验证

更新清单前核验下载地址、SHA-256、归档结构、NDK `source.properties` 与目录版本、应用前缀和动态库依赖。然后在干净的 arm64 Android 设备上验证初始化、新建/克隆、依赖解析、分析服务、APK 构建、ADB 安装运行、热重载及 Web 预览。

自动测试与本地 APK 编译覆盖应用代码及安装协议，不能替代这些设备端验证。当前发布准备不包含修改仓库可见性或重跑 GitHub APK 发布工作流。
