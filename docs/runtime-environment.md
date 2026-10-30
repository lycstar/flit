# 设备端开发环境

本仓库维护安装协议，不重复维护工具链构建配方。产物由 README 中列出的伴生仓库构建与发布。

## 安装顺序

1. 下载 bootstrap，校验 SHA-256，原生安装器按官方包布局部署基础环境。
2. 安装 OpenJDK、Android SDK、NDK、CMake，并配置 Gradle 使用 Android 宿主工具。
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
| `FLIT_ANDROID_SDK_REPO` | Android SDK |
| `FLIT_NDK_REPO` | Android NDK |
| `FLIT_CMAKE_REPO` | CMake |
| `FLIT_FLUTTER_SDK_REPO` | Flutter SDK |

版本目录安装直接使用 GitHub Release 资产的 `digest`（SHA-256），不写回内置清单，也不另存一份远程校验清单。缺少有效 SHA-256 的资产拒绝安装。所有组件均复用初始化的安装脚本。NDK 使用归档 `source.properties` 中的完整 `Pkg.Revision`，CMake 使用实际验证通过的版本号。

全部 SDK 归入 `$HOME/toolchains`，沿用 Android SDK 标准组件布局：

```text
toolchains/
├── flutter/
│   ├── <版本>/
│   └── current → <当前版本>
├── ndk/<Pkg.Revision>/
├── cmake/<版本>/
└── android-sdk/
    ├── platforms/android-<API>/
    ├── build-tools/<版本>/
    ├── platform-tools/
    ├── cmdline-tools/latest/
    ├── ndk → ../ndk
    └── cmake → ../cmake
```

Flutter 的 `current` 是终端、分析器、构建脚本的统一入口。NDK/CMake 不设置全局“当前版本”，项目声明的版本通过 SDK 内的链接定位；不再注入固定的 `ANDROID_NDK_HOME`。SDK 根目录固定，下载其他 SDK 发行包只补充组件，不改变 NDK/CMake 关系。

开发环境页统一展示已安装版本、路径、占用空间，支持离线切换 Flutter、删除版本、从发行目录下载。切换和删除前须关闭项目，工作台终端会停止。当前 Flutter 版本须先切换后才能删除。删除 Build Tools 会重新选择可用 AAPT2；全部删除时，环境检查会阻止继续开发。基础 NDK/CMake 仍为初始化必需版本。

下载以 SHA-256 区分缓存，已校验的归档可在解压失败后复用。先在同一文件系统的暂存目录解压并验证，再写入版本目录。完整的同版本目录保持原样；如需替换须主动删除。默认初始化保留已选 Flutter，其他旧版本也不会自动删除。不迁移旧目录布局，使用新布局需重新安装开发环境。Android SDK 的发行包记录只用于判断组件是否已齐备，删除组件后会自动失效。

显式设为空字符串的目录不发出请求；页面会区分未配置、请求失败和无匹配版本。只配置经过兼容性验证的仓库；匿名下载不支持私有资产，不能把个人令牌写进应用。安装目录和资产名模式见 `ToolchainCatalog.components`。

## 发布验证

更新清单前核验下载地址、SHA-256、归档结构、NDK `source.properties` 与目录版本、应用前缀和动态库依赖。然后在干净的 arm64 Android 设备上验证初始化、新建/克隆、依赖解析、分析服务、APK 构建、ADB 安装运行、热重载及 Web 预览。

自动测试与本地 APK 编译覆盖应用代码及安装协议，不能替代这些设备端验证。
