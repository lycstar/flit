// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get addWebSupport => '添加 Web 支持？';

  @override
  String get addWebSupportDescription =>
      '此项目没有 web 目录。Flit 将先执行 flutter create --platforms web . 添加 Web 支持，再启动预览。';

  @override
  String get addAndRun => '添加并运行';

  @override
  String get recommended => '推荐';

  @override
  String get space => '空格';

  @override
  String get enter => '换行';

  @override
  String get backspace => '退格';

  @override
  String get capsLock => '大写';

  @override
  String environmentCommandFailedExitCodeP(Object? p0) {
    return '环境命令执行失败（退出码 $p0）';
  }

  @override
  String readFailedP(Object? p0) {
    return '读取失败：$p0';
  }

  @override
  String get environmentVariables => '环境变量';

  @override
  String get refreshSnapshot => '刷新快照';

  @override
  String get searchVariablesOrValues => '搜索变量或值';

  @override
  String get retry => '重试';

  @override
  String get noMatchingVariables => '没有匹配的变量';

  @override
  String get readOnlyEnvironmentSnapshotForNewTasks =>
      '新任务的环境变量快照（只读）\n不包含终端中临时 export 的值。展开变量可查看完整值。';

  @override
  String searchResultsP(Object? p0) {
    return '搜索结果 · $p0';
  }

  @override
  String get toolchains => '工具链';

  @override
  String get pathCommandLookupOrder => 'PATH · 按顺序查找命令';

  @override
  String get commandSearchPaths => '命令搜索路径';

  @override
  String pDirectoriesInLookupOrder(Object? p0) {
    return '$p0 个目录 · 按顺序查找';
  }

  @override
  String get currentDirectory => '(当前目录)';

  @override
  String get directoriesAndCaches => '目录与缓存';

  @override
  String otherVariablesP(Object? p0) {
    return '其他变量 · $p0';
  }

  @override
  String get copyValue => '复制值';

  @override
  String get variableValueCopied => '已复制变量值';

  @override
  String get empty => '(空)';

  @override
  String get allowInstallationFromUnknownSourcesThenTap =>
      '需要先授权“安装未知应用”，授权后重新点击安装';

  @override
  String downloadCompleteP(Object? p0) {
    return '下载完成:$p0';
  }

  @override
  String downloadFailedP(Object? p0) {
    return '下载失败:$p0';
  }

  @override
  String get appUpdates => 'App 更新';

  @override
  String get compareThisBuildWithGithubReleasesOr =>
      '当前构建对照 GitHub 发布；历史版本的产物可下载安装。';

  @override
  String failedToFetchReleasesP(Object? p0) {
    return '发布列表请求失败：$p0';
  }

  @override
  String get unknown => '未知';

  @override
  String get localBuildVersionComparisonUnavailable => '本地构建，不比对版本';

  @override
  String get upToDate => '已是最新';

  @override
  String updateAvailableP(Object? p0) {
    return '有更新:$p0';
  }

  @override
  String get currentBuild => '当前构建';

  @override
  String get latestRelease => '最新发布';

  @override
  String get noAssets => '无产物';

  @override
  String get downloadAndInstall => '下载并安装';

  @override
  String get download => '下载';

  @override
  String get systemMonospace => '系统等宽字体';

  @override
  String get settingsStorageUnavailable => '设置存储不可用';

  @override
  String get checking => '检测中…';

  @override
  String failedToSaveOrLoadSettingsP(Object? p0) {
    return '设置保存或读取失败：$p0';
  }

  @override
  String get unableToRequestPermissionYouCanChange => '无法请求系统权限，可稍后在系统应用设置中调整';

  @override
  String get proxySettingsUpdatedAppliesToNewTerminals => '代理设置已更新，新终端和任务生效';

  @override
  String get settings => '设置';

  @override
  String get ideSettings => 'IDE 设置';

  @override
  String get configureDevelopmentToolsDeviceConnectionsAndThe =>
      '配置开发环境、设备连接和编辑器选项。';

  @override
  String get account => '账户';

  @override
  String get developmentEnvironment => '开发环境';

  @override
  String get viewToolchainPathsAndCommandEnvironmentSnapshots =>
      '查看工具链路径与命令环境快照';

  @override
  String get connectDevice => '连接设备';

  @override
  String get wirelessDebuggingPairingAndAuthorization => '无线调试 · 配对与认证状态';

  @override
  String get useSystemProxy => '跟随系统代理';

  @override
  String get noSystemProxyDetectedItWillBe => '未检测到系统代理；检测到后自动使用';

  @override
  String get backgroundAndNotifications => '后台与通知';

  @override
  String get foregroundService => '前台服务';

  @override
  String get showBuildAndTaskStatusInA => '常驻通知展示构建与任务的运行状态';

  @override
  String get backgroundExecution => '后台运行';

  @override
  String get ignoreBatteryOptimizationToReduceBackgroundTask =>
      '忽略电池优化，减少切到后台后任务被中断';

  @override
  String get editorAndTerminal => '编辑器与终端';

  @override
  String get editorSettings => '编辑器设置';

  @override
  String get fontColorSchemeSoftWraps => '字体 · 配色方案 · 软换行';

  @override
  String get terminalSettings => '终端设置';

  @override
  String get pinchToZoomFontSizeMonospaceFont => '双指缩放 · 字号 · 等宽字体 · 行高';

  @override
  String get aboutFlit => '关于 Flit';

  @override
  String get checkForUpdatesDownloadPreviousVersions => '检查更新 · 下载安装历史版本';

  @override
  String get buildCommit => '构建提交';

  @override
  String get platform => '运行平台';

  @override
  String get enabled => '已开启';

  @override
  String get denied => '已拒绝';

  @override
  String get disabled => '未开启';

  @override
  String get allowed => '已允许';

  @override
  String get notConfigured => '未设置';

  @override
  String get flutterProject => 'Flutter 工程';

  @override
  String get dartProject => 'Dart 工程';

  @override
  String get folder => '文件夹';

  @override
  String get nameCannotBeEmpty => '名称不能为空';

  @override
  String get nameCannotContainPathSeparators => '名称不能包含路径分隔符';

  @override
  String get nameCannotBeOr => '名称不能是 . 或 ..';

  @override
  String get justNow => '刚刚';

  @override
  String pMinutesAgo(Object? p0) {
    return '$p0 分钟前';
  }

  @override
  String pHoursAgo(Object? p0) {
    return '$p0 小时前';
  }

  @override
  String pDaysAgo(Object? p0) {
    return '$p0 天前';
  }

  @override
  String get projectDirectoryIsNotReadable => '工程目录不可读';

  @override
  String get aToolchainTaskIsRunningWaitBefore => '工具链任务正在进行，请完成后再打开项目';

  @override
  String get closeThisProjectBeforeRenamingOrDeleting => '请先关闭该工程，再重命名或删除它';

  @override
  String get whereAreProjectsStored => '工程保存在哪里？';

  @override
  String projectDirectoryP(Object? p0) {
    return '工程目录\n$p0\n\n';
  }

  @override
  String get uninstallingTheAppOrClearingItsData =>
      '卸载应用或清除应用数据会连同工程一起删除。备份方式：\n';

  @override
  String get pushToGithubFromVersionControl => '• 推送到 GitHub（版本控制面板）\n';

  @override
  String get openFilesFlitProjectsAndCopyThe =>
      '• 系统「文件」应用 → 侧栏「Flit 工程」，可把整个目录复制到共享存储或其他位置\n';

  @override
  String get longPressAFileInTheEditor => '• 编辑器文件树长按文件 → 分享';

  @override
  String get gotIt => '知道了';

  @override
  String deleteProjectP(Object? p0) {
    return '删除工程「$p0」？';
  }

  @override
  String get theDirectoryAndAllItsFilesWill => '目录及其中的所有文件会被删除，且不可恢复。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get cloneProject => '克隆项目';

  @override
  String get createProject => '创建项目';

  @override
  String get clone => '克隆';

  @override
  String get create => '创建';

  @override
  String pPSucceeded(Object? p0, Object? p1) {
    return '✓ $p0 $p1成功';
  }

  @override
  String pCancelled(Object? p0) {
    return '已中止$p0';
  }

  @override
  String get cloneFailedSignInToGithubFirst =>
      '克隆失败：私有仓库需要先登录 GitHub（克隆页 → GitHub 账户 → 登录）';

  @override
  String pFailedExitCodePSeeTerminal(Object? p0, Object? p1) {
    return '✗ $p0失败（退出码 $p1），详细输出见终端';
  }

  @override
  String get newProject => '新建项目';

  @override
  String get cloneRepository => '克隆仓库';

  @override
  String get projectsAreStoredInTheAppAnd => '工程存在应用内部，卸载即删 · 备份方式';

  @override
  String get checkingDevelopmentEnvironment => '正在检查开发环境';

  @override
  String get openDevelopmentEnvironmentForDetails => '可进入开发环境查看检测详情。';

  @override
  String get viewDevelopmentEnvironment => '查看开发环境';

  @override
  String get developmentEnvironmentIsNotReady => '开发环境未就绪';

  @override
  String get yourProjectsWillAppearHereAfterSetup => '完成环境配置后，这里会列出你的工程';

  @override
  String get setUpDevelopmentEnvironment => '配置开发环境';

  @override
  String get failedToReadProjectDirectory => '读取工程目录失败';

  @override
  String get noProjectsYet => '还没有工程';

  @override
  String get createAProjectOrCloneAGit => '新建工程，或从 Git 仓库克隆';

  @override
  String projectsP(Object? p0) {
    return '工程 · $p0';
  }

  @override
  String get more => '更多';

  @override
  String get rename => '重命名';

  @override
  String get renameProject => '重命名工程';

  @override
  String get projectDirectoryName => '工程目录名';

  @override
  String get ok => '确定';

  @override
  String pAlreadyExistsChooseAnotherDirectoryName(Object? p0) {
    return '$p0 已存在，请换一个目录名';
  }

  @override
  String get unableToCheckDestinationCheckTheDevelopment =>
      '无法检查目标目录，请检查开发环境后重试';

  @override
  String clonePreflightFailedP(Object? p0) {
    return '克隆前检查失败：$p0';
  }

  @override
  String get getFromVersionControl => '从版本控制获取项目';

  @override
  String get cloneARemoteRepositoryToLocalStorage => '将远程仓库克隆到本地，克隆完成后打开项目。';

  @override
  String get repository => '仓库';

  @override
  String get repositoryUrl => '仓库地址';

  @override
  String get directoryNameOptional => '目录名称（可选）';

  @override
  String get leaveEmptyToUseTheRepositoryName => '留空则使用仓库名称';

  @override
  String get branchOptional => '分支（可选）';

  @override
  String get leaveEmptyToUseTheRemoteDefault => '留空则使用远程仓库的默认分支';

  @override
  String get shallowClone => '浅克隆';

  @override
  String get fetchOnlyTheLatestCommitUseGit =>
      '仅获取最近一次提交。可使用 git fetch --unshallow 获取完整历史。';

  @override
  String get clonePreflight => '克隆前检查';

  @override
  String get signInToGithubBeforeCloningA => '私有仓库需要先登录 GitHub，登录后即可直接克隆。';

  @override
  String get ready => '就绪';

  @override
  String get gitNotFoundCheckItsInstallationAnd => '未找到 Git，请检查安装状态和 PATH';

  @override
  String unableToRunP(Object? p0) {
    return '无法运行：$p0';
  }

  @override
  String get location => '保存位置';

  @override
  String get startWithALowercaseLetterUseOnly => '以小写字母开头，只能包含小写字母、数字和下划线';

  @override
  String get dartReservedWordsAndToolNamesCannot => '不能使用 Dart 保留字或工具名称';

  @override
  String get useAReverseDomainNameSuchAs => '使用反向域名格式，例如 com.example';

  @override
  String projectPAlreadyExistsChooseAnotherName(Object? p0) {
    return '项目 $p0 已存在，请换一个名称';
  }

  @override
  String get unableToCheckDestinationCheckTheDevelopment146 =>
      '无法检查目标目录，请查看开发环境后重试';

  @override
  String projectPreflightFailedP(Object? p0) {
    return '创建前检查失败：$p0';
  }

  @override
  String get projectConfiguration => '项目配置';

  @override
  String chooseTheProjectTypeNameAndTarget(Object? p0) {
    return '设置项目类型、名称和目标平台。创建完成后打开项目。\n保存位置：$p0';
  }

  @override
  String get projectDetails => '项目信息';

  @override
  String get projectName => '项目名称';

  @override
  String get lowercaseLettersNumbersAndUnderscores => '小写字母、数字与下划线';

  @override
  String get organizationOptional => '组织标识（可选）';

  @override
  String get targetPlatforms => '目标平台';

  @override
  String get projectTemplate => '项目模板';

  @override
  String get consoleApplication => '控制台应用';

  @override
  String get dartPackage => 'Dart 包';

  @override
  String get serverApplication => '服务端应用';

  @override
  String get runConsoleProjectsUsingDartRunIn => '控制台项目可在终端使用 dart run 运行。';

  @override
  String get selectAtLeastOnePlatform => '请至少选择一个平台。';

  @override
  String get buildAndroidAndPreviewWebOnThis =>
      '本机可构建 Android、预览 Web；其他平台生成代码后需在对应系统构建。';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get emptyProject => '空白项目';

  @override
  String get excludeTheCounterExample => '不包含计数器示例';

  @override
  String get androidSourceLanguage => 'Android 源码语言';

  @override
  String get projectDescriptionOptional => '项目描述（可选）';

  @override
  String get projectPreflight => '创建前检查';

  @override
  String get checkAgain => '重新检测';

  @override
  String get buildApkDebug => '构建 APK（调试版）';

  @override
  String get buildApkRelease => '构建 APK（发布版）';

  @override
  String get buildWebRelease => '构建 Web（发布版）';

  @override
  String get getDependencies => '获取依赖';

  @override
  String get upgradeDependencies => '升级依赖';

  @override
  String get checkOutdatedDependencies => '检查过期依赖';

  @override
  String get cleanBuildOutputs => '清理构建产物';

  @override
  String get analyzeCode => '静态分析';

  @override
  String get runTests => '运行测试';

  @override
  String get environmentDiagnostics => '环境诊断';

  @override
  String get projectIsClosed => '项目已关闭';

  @override
  String get theDevelopmentEnvironmentIsBeingInstalledOr => '开发环境正在安装或切换，请等待完成';

  @override
  String get aGitOperationIsInProgressPlease => 'Git 操作正在进行，请等待完成';

  @override
  String get saveFailedPleaseRetry => '保存失败，请重试';

  @override
  String get aTaskIsAlreadyStartingPleaseWait => '当前已有任务正在启动，请稍后重试';

  @override
  String targetPIsNotConnected(Object? p0) {
    return '目标 $p0 未连接';
  }

  @override
  String get runDart => 'Dart 运行';

  @override
  String get compileExecutable => '编译可执行文件';

  @override
  String get waitForTheBuildOrDependencyUpdate => '请等待构建或依赖更新完成后再热重载';

  @override
  String get filesAreSyncingPleaseRetryShortly => '文件正在同步，请稍后重试';

  @override
  String get invalidFilePath => '文件路径无效';

  @override
  String get fileIsUnreadableOrOutsideTheProject => '文件不可读或位于项目目录之外';

  @override
  String get aFileIsAlreadyOpenAtThe => '目标路径已有打开的文件';

  @override
  String get saveFailedFileOperationCancelled => '保存失败，已取消文件操作';

  @override
  String fileDoesNotExistP(Object? p0) {
    return '文件不存在： $p0';
  }

  @override
  String unableToReloadPTheFileWas(Object? p0) {
    return '无法重新读取 $p0，已关闭此文件，请从“项目”工具窗口重新打开';
  }

  @override
  String unableToReadProjectDirectoryP(Object? p0) {
    return '无法读取项目目录：$p0';
  }

  @override
  String get fileIsOutsideTheCurrentProject => '文件不在当前项目内';

  @override
  String get noFilesToPaste => '没有可粘贴的文件';

  @override
  String get filesCanOnlyBeMovedWithinThe => '只能在当前项目内移动文件，请使用复制';

  @override
  String get aGitOperationIsRunningWaitOr => 'Git 操作正在进行，请等待完成或在终端停止';

  @override
  String get aFileOperationIsRunningWaitBefore => '文件操作正在进行，请等待完成后再切换项目';

  @override
  String get failedToSaveTheCurrentProjectRetry => '当前项目保存失败，请重试后再切换项目';

  @override
  String fontSizeAppliedButSavingFailedP(Object? p0) {
    return '字号已应用，但保存失败：$p0';
  }

  @override
  String get terminalAppearance => '终端外观';

  @override
  String get closeTerminalSettings => '关闭终端设置';

  @override
  String get collapseTerminal => '收起终端';

  @override
  String get expandTerminal => '展开终端';

  @override
  String get stopping => '正在停止…';

  @override
  String get stopCurrentTask => '停止当前任务';

  @override
  String get terminateAndClose => '终止并关闭';

  @override
  String get close => '关闭';

  @override
  String get terminalFontAndZoom => '终端字体与缩放';

  @override
  String get clearTerminal => '清空终端';

  @override
  String get exitFullScreen => '退出全屏终端';

  @override
  String get fullScreenTerminal => '全屏终端';

  @override
  String get paste => '粘贴';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get selectAll => '全选';

  @override
  String closePSession(Object? p0) {
    return '关闭 $p0 会话';
  }

  @override
  String get developmentEnvironmentIsNotReadyCompleteSetup => '开发环境未就绪，请先初始化环境';

  @override
  String get aTaskCannotBeTheDefaultShell => '任务不会是默认 shell';

  @override
  String pRequiresExclusiveProjectAccessStopIt(Object? p0) {
    return '“$p0”与该操作需要独占项目，请结束后重试';
  }

  @override
  String pIsUpdatingDependenciesOrBuildFiles(Object? p0) {
    return '“$p0”正在更新依赖或构建文件，请等待完成';
  }

  @override
  String get sessionIsClosed => '会话已关闭';

  @override
  String get theCurrentTaskHasNotFinished => '当前任务尚未结束';

  @override
  String failedToReadOutputP(Object? p0) {
    return '读取输出失败： $p0';
  }

  @override
  String failedToStartP(Object? p0) {
    return '启动失败： $p0';
  }

  @override
  String get stopped => '已停止';

  @override
  String get processExitedWithCode => '进程结束，退出码 0';

  @override
  String processExitedWithCodeP(Object? p0) {
    return '进程结束，退出码 $p0';
  }

  @override
  String get executionTimedOutStopping => '执行超时，正在停止';

  @override
  String get sharedByAllTerminalsAndSavedAutomatically =>
      '所有终端共用设置，自动保存。也可在终端内容区双指缩放。';

  @override
  String settingsAppliedButSavingFailedP(Object? p0) {
    return '设置已应用，但保存失败：$p0';
  }

  @override
  String get terminalFontSize => '终端字号';

  @override
  String get decreaseTerminalFontSize => '缩小终端字号';

  @override
  String get increaseTerminalFontSize => '放大终端字号';

  @override
  String get monospaceFont => '等宽字体';

  @override
  String get lineHeight => '行高';

  @override
  String p(Object? p0) {
    return '$p0 倍';
  }

  @override
  String get flitFlutterBuildApkBuildComplete =>
      'flit ~ \$ flutter build apk\n✓ 构建完成  Build complete\n0123456789  []{\'} <> !=';

  @override
  String get resetTerminalAppearance => '恢复终端默认外观';

  @override
  String get thisAssetHasNoShaDigest => '该产物缺少 SHA-256';

  @override
  String unsupportedComponentP(Object? p0) {
    return '不支持的组件：$p0';
  }

  @override
  String get aToolchainIsBeingInstalledPleaseWait => '工具链正在安装，请稍后重试';

  @override
  String get projectClosedOrTaskCancelled => '项目已关闭或任务已取消';

  @override
  String get requiredComponentsAreMissingBuildNotStarted => '组件未补齐，构建未启动';

  @override
  String componentRepairIncompleteP(Object? p0) {
    return '组件修复未完成：$p0';
  }

  @override
  String androidEnvironmentCheckFailedCompleteSetupIn(Object? p0) {
    return 'Android 环境检查失败，请先在开发环境页完成初始化。\n$p0';
  }

  @override
  String get installingComponentsChangesTheSharedDevelopmentEnvironment =>
      '安装组件需要修改共用开发环境。请先结束正在运行的任务，再重试。';

  @override
  String matchingVersionOrDownloadInformationUnavailableP(Object? p0) {
    return '未找到可安装的对应版本或无法获取下载信息：$p0';
  }

  @override
  String get aTaskIsRunningStopItAnd => '已有任务正在运行，请结束后重试';

  @override
  String get installAndroidBuildComponents => '安装 Android 构建组件';

  @override
  String stillUnavailableAfterInstallationP(Object? p0) {
    return '安装后仍不可用：$p0';
  }

  @override
  String automaticInstallationIsNotSupportedForP(Object? p0) {
    return '不支持自动安装 $p0';
  }

  @override
  String get invalidNdkVersion => '无效的 NDK 版本';

  @override
  String unableToLocateNdkP(Object? p0) {
    return '无法定位 NDK $p0';
  }

  @override
  String get androidSdkLicensesHaveNotBeenAccepted =>
      'Android SDK 许可证尚未接受。请在开发环境终端运行 \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses，接受所需许可证后重试。';

  @override
  String get theSdkNdkCmakePathInThe =>
      '项目配置的 SDK/NDK/CMake 路径无效。请检查 local.properties 或 Gradle 中的路径；安装到默认目录不会修复自定义路径。';

  @override
  String unknownComponentP(Object? p0) {
    return '未知组件：$p0';
  }

  @override
  String noValidPReleaseConfiguredP(Object? p0, Object? p1) {
    return '未配置有效的 $p0 发行版本：$p1';
  }

  @override
  String releaseUnavailableP(Object? p0) {
    return '发行版本不可用：$p0';
  }

  @override
  String noUniquePFoundInP(Object? p0, Object? p1) {
    return '$p0 中未找到唯一的 $p1';
  }

  @override
  String pPIsMissingAValidDownload(Object? p0, Object? p1) {
    return '$p0 / $p1 缺少有效的下载地址或 SHA-256';
  }

  @override
  String get invalidGithubReleasesResponse => 'GitHub Releases 响应无效';

  @override
  String get baseEnvironment => '基础环境';

  @override
  String get bashPackageManager => 'Bash · 软件包管理器';

  @override
  String get androidToolchain => 'Android 工具链';

  @override
  String get openjdkAndroidSdkNdkCmakeGradleConfiguration =>
      'OpenJDK 17 · Android SDK · NDK · CMake · Gradle 配置';

  @override
  String get flutterToolchain => 'Flutter 工具链';

  @override
  String get flutterSdkGitAndGhWarmUp => 'Flutter SDK · Git 与 gh · 预热';

  @override
  String get gradleConfiguration => 'Gradle 配置';

  @override
  String get gitAndGh => 'Git 与 gh';

  @override
  String get warmUp => '预热';

  @override
  String get projectTasksAreUsingTheDevelopmentEnvironment =>
      '项目任务正在使用开发环境，请先结束任务再安装、切换或删除组件';

  @override
  String get aTaskIsRunningWaitBeforeInstalling => '当前有任务进行中，请等待完成后再安装版本';

  @override
  String get installTheBaseEnvironmentBeforeAddingOther => '请先安装基础环境，再安装其他版本';

  @override
  String installP(Object? p0) {
    return '安装 $p0';
  }

  @override
  String fetchingDownloadInformationForP(Object? p0) {
    return '正在获取 $p0 的下载信息…';
  }

  @override
  String pInstalled(Object? p0) {
    return '✓ $p0 安装完成';
  }

  @override
  String installationFailedExitCodePSeeOutput(Object? p0) {
    return '安装失败，退出码 $p0（详细输出见上）';
  }

  @override
  String installationFailedP(Object? p0) {
    return '安装失败：$p0';
  }

  @override
  String operationFailedExitCodePSeeOutput(Object? p0) {
    return '操作失败，退出码 $p0（详细输出见上）';
  }

  @override
  String get installTheBaseEnvironmentBeforeCheckingThe => '请先安装基础环境，再执行网络检测';

  @override
  String get networkCheck => '网络检测';

  @override
  String environmentCheckFailedP(Object? p0) {
    return '环境检测失败：$p0';
  }

  @override
  String get environmentCheck => '环境检测';

  @override
  String environmentCheckIncompleteExitCodeP(Object? p0) {
    return '环境检查未完成，退出码 $p0';
  }

  @override
  String get componentsAreNotReadyCheckAgain => '组件检测尚未就绪，请重新检测';

  @override
  String get componentDirectoryCheckFailed => '组件目录检测失败';

  @override
  String unableToReadInstalledComponentsCheckAgain(Object? p0) {
    return '无法读取已安装组件，请重新检测：$p0';
  }

  @override
  String get environmentSetup => '安装环境';

  @override
  String baseEnvironmentInstallationFailedP(Object? p0) {
    return '✗ 基础环境安装失败：$p0';
  }

  @override
  String pInstallationFailedRemainingStepsSkipped(Object? p0) {
    return '✗ $p0 安装失败，已跳过后续步骤';
  }

  @override
  String pComplete(Object? p0) {
    return '✓ $p0 完成';
  }

  @override
  String get installationCompleteDevelopmentEnvironmentReady =>
      '✓ 安装完成，开发环境已就绪';

  @override
  String get environmentVerificationFailedCheckMissingOrFailed =>
      '环境复查未通过，请查看缺失或失败的组件';

  @override
  String get stoppedYouCanResumeInstallationLater => '已停止，可随时继续安装';

  @override
  String preparingP(Object? p0) {
    return '准备 $p0…';
  }

  @override
  String failedToFetchInstallationInformationP(Object? p0) {
    return '获取安装信息失败：$p0';
  }

  @override
  String get keepMultipleVersionsAndChooseTheActive =>
      '可安装多个版本，选择当前使用的版本。安装新版本后会自动切换。';

  @override
  String get matchesTheProjectCompilesdkMultipleApiVersions =>
      '对应项目的 compileSdk，可同时保留多个 API 版本。';

  @override
  String get androidPackagingToolsInstallAndKeepVersions =>
      'Android 打包工具，按项目需要安装并保留多个版本。';

  @override
  String get nativeCompilerToolsTheProjectSelectsThe =>
      '原生代码编译工具，由项目指定版本，可同时安装多个版本。';

  @override
  String get nativeBuildToolsTheProjectSelectsThe =>
      '原生构建工具，由项目指定版本，可同时安装多个版本。';

  @override
  String get adbAndOtherSharedDeviceToolsInstalling =>
      'ADB 等设备工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。';

  @override
  String get sdkmanagerAndOtherSharedSdkManagementTools =>
      'sdkmanager 等 SDK 管理工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。';

  @override
  String companionToolsP(Object? p0) {
    return '配套工具包 · $p0';
  }

  @override
  String get unknownVersion => '版本未知';

  @override
  String get closeTheProjectBeforeChangingSdksOr => '请先关闭项目，再更改 SDK 或工具链';

  @override
  String get back => '返回';

  @override
  String get proxySettings => '代理设置';

  @override
  String get sdksAndToolchains => 'SDK 与工具链';

  @override
  String get manageSdksAndBuildToolsViewInstallation =>
      '管理 SDK 和构建工具链，在终端查看安装输出。';

  @override
  String get setupDetails => '初始化详情';

  @override
  String get checkingEnvironment => '正在检测环境';

  @override
  String get managingToolchains => '正在管理工具链';

  @override
  String get environmentReady => '环境已就绪';

  @override
  String get installingComponents => '正在安装组件';

  @override
  String get installationFailed => '安装失败';

  @override
  String get environmentNotReady => '环境未就绪';

  @override
  String get checkingLocalComponentsPleaseWait => '正在核对本地组件，请稍候';

  @override
  String get seeTerminalForDetails => '详细输出见终端';

  @override
  String get componentsReadyYouCanCreateProjectsAnd => '组件已就绪，可以创建项目和构建 APK';

  @override
  String pPReady(Object? p0, Object? p1) {
    return '已就绪 $p0/$p1 项';
  }

  @override
  String get done => '完成';

  @override
  String get resumeInstallation => '继续安装';

  @override
  String get startInstallation => '开始安装';

  @override
  String networkP(Object? p0) {
    return '网络：$p0';
  }

  @override
  String get baseEnvironmentDownloadConfigurationIsIncompleteUpdate =>
      '基础环境的下载配置不完整，请更新应用后重试';

  @override
  String get downloadingBaseEnvironment => '正在下载基础环境…';

  @override
  String downloadUrlP(Object? p0) {
    return '下载地址：$p0';
  }

  @override
  String downloadFailedHttpPCheckTheUrl(Object? p0) {
    return '下载失败：HTTP $p0，请检查下载地址和网络后重试';
  }

  @override
  String downloadedPPMb(Object? p0, Object? p1) {
    return '下载 $p0%（$p1 MB）';
  }

  @override
  String downloadCompletePMb(Object? p0) {
    return '下载完成（$p0 MB）';
  }

  @override
  String verifyingShaP(Object? p0) {
    return '正在校验 SHA-256：$p0';
  }

  @override
  String baseEnvironmentChecksumMismatchExpectedPActual(
    Object? p0,
    Object? p1,
  ) {
    return '基础环境安装包校验失败：\n期望：$p0\n实际：$p1';
  }

  @override
  String get shaVerified => 'SHA-256 校验通过';

  @override
  String get installingBaseEnvironmentExtractingAndConfiguring =>
      '正在安装基础环境（解压与配置）…';

  @override
  String get nativeInstallerDidNotConfirmASuccessful => '原生安装器未确认基础环境安装成功';

  @override
  String get baseEnvironmentReady => '基础环境已就绪';

  @override
  String get checkFailedOpenDevelopmentEnvironment => '检测失败 · 进入开发环境查看';

  @override
  String get notInstalledSetUpDevelopmentEnvironment => '尚未安装 · 配置开发环境';

  @override
  String get allComponentsReady => '组件全部就绪';

  @override
  String pPComponentsReady(Object? p0, Object? p1) {
    return '已就绪 $p0/$p1 个组件';
  }

  @override
  String get manageVersions => '管理版本';

  @override
  String deleteP(Object? p0) {
    return '删除 $p0？';
  }

  @override
  String get projectsUsingThisVersionWillNeedIt =>
      '依赖此版本的项目需重新安装后才能构建；删除基础必需版本后，需要补齐开发环境。';

  @override
  String get repairInstallation => '修复安装';

  @override
  String get useThisVersion => '使用此版本';

  @override
  String get switchVersionsBeforeDeleting => '先切换版本再删除';

  @override
  String get deleteVersion => '删除版本';

  @override
  String replaceP(Object? p0) {
    return '替换 $p0？';
  }

  @override
  String installTheCompanionToolsFromPReplacing(Object? p0) {
    return '将安装 $p0 提供的配套工具包，替换当前共用工具。';
  }

  @override
  String get replace => '替换';

  @override
  String get refreshAvailableVersions => '刷新可下载版本';

  @override
  String get localVersions => '本地版本';

  @override
  String get checkingLocalComponents => '正在检测本地组件…';

  @override
  String get installationStatusUnconfirmed => '安装状态待确认';

  @override
  String get notInstalled => '未安装';

  @override
  String get companionTools => '配套工具包';

  @override
  String get availableVersions => '可下载版本';

  @override
  String failedToFetchVersionsPP(Object? p0, Object? p1) {
    return '获取版本失败，$p0。\n$p1';
  }

  @override
  String get noDownloadableCompanionVersionsInTheRepository => '仓库暂无可下载的配套版本。';

  @override
  String get allCatalogVersionsAreInstalledUseThe =>
      '目录中的版本已在本地，需修复的版本可通过管理菜单重新安装。';

  @override
  String get installingTheSameNdkVersionKeepsThe => '安装相同 NDK 版本会保留现有可用版本。';

  @override
  String get componentManager => '组件管理';

  @override
  String get manageInstalledVersionsDownloadsAndRepairsBy =>
      '按组件管理本地版本、下载与修复。SDK 整包仅用于初始化。';

  @override
  String get setUpTheBaseEnvironmentFirstThen => '先完成基础环境初始化，再按项目需要管理组件。';

  @override
  String pVersionsPP(Object? p0, Object? p1, Object? p2) {
    return '$p0 个版本$p1$p2';
  }

  @override
  String get availableAfterSetup => '初始化后可管理';

  @override
  String get checking372 => '正在检测…';

  @override
  String get installing => '安装中';

  @override
  String get failed => '失败';

  @override
  String get waitingForDependencies => '等待依赖';

  @override
  String get pendingInstallation => '待安装';

  @override
  String pInstalling(Object? p0) {
    return '$p0 · 安装中';
  }

  @override
  String pFailed(Object? p0) {
    return '$p0 · 失败';
  }

  @override
  String pWaitingForPreviousSteps(Object? p0) {
    return '$p0 · 等待前序步骤';
  }

  @override
  String pPendingInstallation(Object? p0) {
    return '$p0 · 待安装';
  }

  @override
  String get deviceConnection => '设备连接';

  @override
  String get enterAnIpAddressOrHostnameWithout => '请输入 IP 地址或主机名，不包含协议和端口';

  @override
  String get portMustBeBetweenAnd => '端口必须在 1–65535 之间';

  @override
  String get unableToReadDevicesSeeTerminalOutput => '读取设备失败，请查看终端输出';

  @override
  String get adbFailedToStartCheckTheDevelopment => 'ADB 启动失败，请检查开发环境';

  @override
  String operationFailedPSeeTerminalForDetails(Object? p0) {
    return '操作失败：$p0。详细原因见终端。';
  }

  @override
  String get enterADigitPairingCode => '请填写 6 位配对码';

  @override
  String get pairingFailedKeepTheSystemPairingDialog =>
      '配对失败：请保持系统配对码弹窗开启，核对配对端口与配对码后重试。详细原因见终端。';

  @override
  String get pairedSuccessfully => '配对成功';

  @override
  String get unableToConfirmDeviceIsOnlineRefresh => '连接后未能确认设备在线，请刷新设备或查看日志';

  @override
  String get connectedToLocalWirelessDebugging => '✓ 已自动连接本机无线调试';

  @override
  String get allowUsbDebuggingOnThePhoneThen => '请在手机上允许 USB 调试授权后重试';

  @override
  String get pairingRequiredTapNotificationPairing => '需要配对，请点击“通知配对”';

  @override
  String get connectionFailedCheckLogsOrConnectManually =>
      '连接未成功，请查看日志或使用当前端口手动连接';

  @override
  String get noWirelessPortFoundScanAgainEnter =>
      '未发现无线端口，可重新扫描、手动输入，或通过电脑 USB 激活';

  @override
  String get connectedLocallyUsbActivatedYouCanUnplug =>
      '✓ 已连接本机 · 电脑 USB 激活，可拔掉数据线';

  @override
  String get unableToConfirmConnectionInstallAdbFirst => '无法确认连接状态，请先安装 ADB';

  @override
  String get unableToConfirmConnectionFailedToRead =>
      '✗ 无法确认连接状态：读取设备失败，请查看终端输出';

  @override
  String connectedToP(Object? p0) {
    return '✓ 已连接 $p0';
  }

  @override
  String get deviceUnauthorizedAllowUsbDebuggingOnThe =>
      '设备未授权：请在手机上允许 USB 调试授权，再点连接';

  @override
  String get localAdbIsOfflineRunTheActivation => '本机 ADB 离线，请在电脑重新执行激活命令后重试';

  @override
  String get adbAuthenticationFailedConfirmUsbDebuggingAuthorization =>
      'ADB 认证失败：请在手机上确认 USB 调试授权，再点连接';

  @override
  String get notActivatedConnectViaUsbAndRun =>
      '尚未激活：请用 USB 连接电脑，执行激活命令后重试；手机重启后需重新激活';

  @override
  String get unableToConnectToLocalPortCheck =>
      '未能连接本机 5555 端口，请检查电脑激活结果和手机授权；部分系统可能限制此方式';

  @override
  String get deviceUnauthorizedConfirmAuthorizationOnTheTarget =>
      '设备未授权：请在目标设备确认调试授权；无线调试请重新配对，再使用连接端口连接。';

  @override
  String get deviceOfflineEnableWirelessDebuggingThenDisconnect =>
      '设备离线：请确认无线调试仍开启，再断开此设备并用当前连接端口重连。';

  @override
  String get adbAuthenticationFailedPairAgainInWireless =>
      'ADB 认证失败：请在无线调试中重新配对，再连接。';

  @override
  String get connectionRefusedEnableWirelessDebuggingAndUse =>
      '连接被拒绝：请开启无线调试，并使用主页上的连接端口。';

  @override
  String get connectionTimedOutCheckTheAddressNetwork =>
      '连接超时：请检查设备地址、网络和无线调试状态。';

  @override
  String get deviceIsNotOnlineCheckTerminalOutput =>
      '设备尚未上线，请查看终端输出并核对无线调试的连接端口';

  @override
  String disconnectedFromPPairingAuthorizationIsRetained(Object? p0) {
    return '已断开 $p0；配对授权仍保留。';
  }

  @override
  String get unableToConfirmDisconnectionCheckTerminalOutput =>
      '无法确认设备已断开，请查看终端输出并刷新设备。';

  @override
  String connectedButFailedToSaveDeviceSettings(Object? p0) {
    return '连接结果已生效，但设备设置保存失败： $p0';
  }

  @override
  String get unableToReadAdbDeviceStatus => '无法读取 ADB 设备状态';

  @override
  String tryingPreviousConnectionPortP(Object? p0) {
    return '尝试上次连接端口 $p0';
  }

  @override
  String get scanningLocalWirelessDebuggingPorts => '扫描本机无线调试连接端口…';

  @override
  String foundConnectionPortP(Object? p0) {
    return '发现连接端口 $p0';
  }

  @override
  String scanOrConnectionFailedP(Object? p0) {
    return '扫描或连接失败：$p0';
  }

  @override
  String get connectedLocallyYouCanUnplugTheCable => '已连接本机，可以拔掉数据线。';

  @override
  String get waitTimedOutCheckTheComputerCommand => '等待超时，请检查电脑命令输出，然后重新连接。';

  @override
  String get allowUsbDebuggingOnThePhoneFlit =>
      '请在手机上允许 USB 调试授权，Flit 会自动继续连接。';

  @override
  String get unableToReadAdbStatusCheckThe => '无法读取 ADB 状态，请检查开发环境；正在重试…';

  @override
  String get waitingForComputerActivationFlitWillConnect =>
      '等待电脑激活… Flit 会自动连接本机。';

  @override
  String get activateViaComputerUsb => '通过电脑 USB 激活';

  @override
  String get enableUsbDebuggingConnectThePhoneTo =>
      '1. 手机开启 USB 调试，用数据线连接电脑，并允许调试授权。电脑只连接这一台手机。';

  @override
  String get downloadAndExtractPlatformToolsOnThe =>
      '2. 电脑下载并解压 Platform Tools，在解压目录打开终端。';

  @override
  String get unableToOpenTheDownloadPage => '无法打开下载页面';

  @override
  String get onTheComputerVisitDeveloperAndroidCom =>
      '请在电脑访问 developer.android.com/tools/releases/platform-tools';

  @override
  String get platformToolsWebsite => 'Platform Tools 官网';

  @override
  String get runThisCommandOnTheComputerKeep => '3. 在电脑执行这一条命令，然后保持此引导打开，等待连接。';

  @override
  String get computerOs => '电脑系统';

  @override
  String get copyFailedLongPressTheCommandTo => '复制失败，请长按命令复制';

  @override
  String get copyCommand => '复制命令';

  @override
  String get afterTheComputerShowsRestartingInTcp =>
      '电脑显示 restarting in TCP mode port: 5555 后，Flit 会尝试连接。若手机再次弹出调试授权，请允许。';

  @override
  String get waitsAutomaticallyForUpToMinutesClosing =>
      '自动等待最多 2 分钟，退出引导即停止。之后仍可在设备页点“连接本机”。手机重启后通常需要重新激活。';

  @override
  String tcpDebuggingMayAlsoListenOnNetwork(Object? p0) {
    return 'TCP 调试可能同时监听网络接口。停用时接回电脑执行 $p0 -d usb；Flit 中“断开”仅断开客户端。';
  }

  @override
  String get reconnect => '重新连接';

  @override
  String get connectNow => '立即连接';

  @override
  String get unableToReadPairingStatusGoBack => '无法读取配对状态，请返回后重试';

  @override
  String get systemOperationFailed => '系统操作失败';

  @override
  String get openTheSystemPairingDialogAndEnter => '打开系统配对码窗口，在通知中输入配对码';

  @override
  String get noPairingPortFoundKeepTheSystem => '未发现配对端口，请保持系统配对窗口开启';

  @override
  String get refreshDevices => '刷新设备';

  @override
  String get manualConnectionOtherDevices => '手动连接 / 其他设备';

  @override
  String get deviceAddress => '设备地址';

  @override
  String get connectionPort => '连接端口';

  @override
  String get connect => '连接';

  @override
  String get pairingRecorded => '有配对记录';

  @override
  String get keepTheSystemPairingDialogOpenIn => '手动配对时请分屏保留系统配对窗口。';

  @override
  String get pairingPort => '配对端口';

  @override
  String get pairingCodeDigits => '配对码（6 位）';

  @override
  String get scanning => '扫描中…';

  @override
  String get scanPairingPorts => '扫描配对端口';

  @override
  String get pair => '配对';

  @override
  String get wirelessPairingGuide => '无线配对指南';

  @override
  String get notificationStylePairingStepsAndTroubleshooting =>
      '通知样式、配对步骤与常见问题';

  @override
  String get connectViaWirelessDebugging => '通过无线调试连接';

  @override
  String get androidPairAndConnectOverWiFi => 'Android 11+ · Wi-Fi 下配对与连接';

  @override
  String get wirelessDebuggingSettings => '无线调试设置';

  @override
  String get notificationPairing => '通知配对';

  @override
  String get scanAndConnect => '扫描并连接';

  @override
  String get searchingForPairingPort => '正在寻找配对端口…';

  @override
  String get cancelPairing => '取消配对';

  @override
  String get activateFromAComputerThenUnplugThe => '电脑激活后连接，可拔掉数据线';

  @override
  String get viewSteps => '查看步骤';

  @override
  String get connecting => '连接中…';

  @override
  String get connectLocally => '连接本机';

  @override
  String get deviceStatus => '设备状态';

  @override
  String pOnline(Object? p0) {
    return '$p0 台在线';
  }

  @override
  String get adbNotFoundInstallTheAndroidToolchain =>
      '未找到 ADB，请在“开发环境”中安装 Android 工具链。';

  @override
  String get noConnections => '暂无连接';

  @override
  String disconnectP(Object? p0) {
    return '断开 $p0';
  }

  @override
  String get unableToReadNotificationStatus => '无法读取通知状态';

  @override
  String get unableToReadNotificationStatusRetry => '无法读取通知状态，请重试';

  @override
  String get unableToOpenSystemSettings => '无法打开系统设置';

  @override
  String get unableToOpenRetryLater => '无法打开，请稍后重试';

  @override
  String get enterThePairingCodeInTheNotification => '在通知中输入配对码';

  @override
  String get androidPhoneMustBeConnectedToWi => 'Android 11 及以上 · 手机需连接 Wi-Fi';

  @override
  String get checkingNotificationPermission => '正在检查通知权限…';

  @override
  String get wirelessPairingIsNotSupportedOnThis => '此系统不支持无线配对';

  @override
  String get pairingNotificationsEnabled => '配对通知已开启';

  @override
  String get allowFlitNotificationsFirst => '请先允许 Flit 通知';

  @override
  String get notificationStatusUnknown => '通知状态未知';

  @override
  String get wirelessPairingRequiresAndroidOrLaterGo =>
      '无线配对需要 Android 11 或以上，可返回使用电脑 USB 激活。';

  @override
  String get allowFlitNotificationsIncludingTheWirelessDebugging =>
      '允许 Flit 发布通知；若已有“无线调试配对”通知类别，也要开启。配对时从通知里输入代码。';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get checkAgain487 => '重新检查';

  @override
  String get xiaomiPocoSomeMiuiVersionsRequireThe =>
      '小米 / POCO：部分 MIUI 需要把通知样式改为“原生样式”，否则可能无法输入配对码。具体路径见下方说明。';

  @override
  String get finishTheCurrentDeviceOperationOrInstall =>
      '请先在设备页结束当前操作，或安装缺失的 ADB，再开始配对。';

  @override
  String get startPairing => '开始配对';

  @override
  String get tapStartPairingBelowFlitStartsThe =>
      '点击下方“开始配对”，Flit 会先启动配对通知，再打开开发者选项。首次使用请先开启开发者选项和 USB 调试。';

  @override
  String get openThePairingCodeDialog => '打开配对码窗口';

  @override
  String get enableWirelessDebuggingTapItsLabelTo =>
      '开启“无线调试”，点击这项的文字进入详情，再点“使用配对码配对设备”。保持显示 6 位代码的窗口打开。';

  @override
  String get enablingTheSwitchAloneIsNotEnough => '仅打开右侧开关还不够，需要进入无线调试详情页。';

  @override
  String get expandTheNotificationAndEnterTheDigit => '下拉通知，输入 6 位码';

  @override
  String get expandTheFlitPairingNotificationTapEnter =>
      '展开 Flit 的配对通知，点击“输入配对码”，填入系统窗口中的代码并发送。不要切回 Flit 填写，切换应用可能关闭配对窗口。';

  @override
  String get theEnterPairingCodeButtonAppearsOnce => '找到配对端口后，通知才会出现“输入配对码”按钮。';

  @override
  String get returnToFlitToConnect => '返回 Flit 连接';

  @override
  String get returnToFlitAfterSuccessfulPairingIt =>
      '通知提示配对成功后返回 Flit，会自动尝试连接本机。已配对时直接“扫描并连接”；重新开启无线调试后，连接端口可能改变。';

  @override
  String get noNotificationInputEnteringTheCodeFails => '通知里没有输入框 / 点输入就失败';

  @override
  String get expandTheNotificationAndCheckThatEnter =>
      '先展开通知，确认已显示“输入配对码”。若仍停留在“搜索端口”，请看下一项。';

  @override
  String get someXiaomiRedmiAndPocoMiuiVersions =>
      '小米、Redmi、POCO 的部分 MIUI：在系统设置 → 通知管理 → 通知显示设置，将通知样式切为“原生样式”，再重新配对。';

  @override
  String get namesAndLocationsVaryAcrossHyperosAnd =>
      'HyperOS 或其他版本的入口、名称可能不同；如提供“Android”或“原生”通知样式，可尝试切换。Flit 无法自动检测或修改此设置。';

  @override
  String get ifThisOptionIsUnavailableKeepThe =>
      '找不到该选项时，可用分屏保留系统配对窗口，在“手动连接 / 其他设备”输入配对端口和配对码。';

  @override
  String get keepsSearchingNoResponseAfterOpeningSettings =>
      '一直搜索端口 / 切到设置后没反应';

  @override
  String get enableWiFiAndWirelessDebuggingAnd =>
      '确认 Wi-Fi 和无线调试已开启，并保持“使用配对码配对设备”窗口打开。配对端口只在这个窗口打开时广播。';

  @override
  String get someSystemsRestrictLocalNetworkAccessFor =>
      '部分系统会限制不可见应用的本地网络访问。允许 Flit 后台运行，并在系统的联网管理中允许 Wi-Fi / 本地网络访问（如提供）。';

  @override
  String get allowBackgroundExecution => '允许后台运行';

  @override
  String get ifNothingIsFoundToggleWirelessDebugging =>
      '仍无结果可重新开关无线调试后再试。Flit 最多搜索 3 分钟；超时后重新开始，也可改用电脑 USB 激活。';

  @override
  String get pairedButCannotConnect => '配对成功，但连接失败';

  @override
  String get pairingAndConnectionPortsDifferForManual =>
      '配对端口与连接端口不同。手动连接时，请使用无线调试主页显示的连接端口，不要使用配对码窗口的端口。';

  @override
  String get tapScanAndConnectOnTheDevice =>
      '返回设备页点“扫描并连接”。仍找不到端口时，可以手动输入连接端口，或使用电脑 USB 激活。配对记录不代表设备当前在线。';

  @override
  String get unableToOpenReferencePage => '无法打开参考页面';

  @override
  String get referenceShizukuGuide => '参考：Shizuku 使用指南';

  @override
  String get webServerRestarted => 'Web 服务已重新运行';

  @override
  String get webStartupTimedOutCheckRunLogs => 'Web 启动超时，请查看运行日志';

  @override
  String webStartupFailedP(Object? p0) {
    return 'Web 启动失败：$p0';
  }

  @override
  String webRunFailedP(Object? p0) {
    return 'Web 运行失败：$p0';
  }

  @override
  String updateFailedP(Object? p0) {
    return '更新失败：$p0';
  }

  @override
  String webProcessExitedCodePCheckRun(Object? p0) {
    return 'Web 进程已退出（退出码 $p0），请查看运行日志';
  }

  @override
  String get webServerStopped => 'Web 服务已停止';

  @override
  String get runWebToPreviewHere => '运行 Web 后在这里预览';

  @override
  String get compilingAndStartingTheWebServer => '正在编译并启动 Web 服务';

  @override
  String get webStartupFailed => 'Web 启动失败';

  @override
  String get viewRunLogs => '查看运行日志';

  @override
  String get thePageHasNotRenderedYetCheck => '页面尚未完成首次渲染，请查看运行日志或重新加载';

  @override
  String pageLoadFailedP(Object? p0) {
    return '页面加载失败：$p0';
  }

  @override
  String pageRequestFailedHttpP(Object? p0) {
    return '页面请求失败：HTTP $p0';
  }

  @override
  String unableToLoadPreviewP(Object? p0) {
    return '无法加载预览：$p0';
  }

  @override
  String get reloadPageResetPageState => '重新加载页面（重置页面状态）';

  @override
  String get loadingPreview => '正在加载预览…';

  @override
  String get reload => '重新加载';

  @override
  String get updating => '正在更新…';

  @override
  String get document => '本文档';

  @override
  String get symbol => '符号';

  @override
  String get keyword => '关键字';

  @override
  String get method => '方法';

  @override
  String get type => '类型';

  @override
  String get variable => '变量';

  @override
  String get module => '模块';

  @override
  String get property => '属性';

  @override
  String get dartLanguageServiceCouldNotStart => 'Dart 语言服务无法启动';

  @override
  String get initializationFailed => '初始化失败';

  @override
  String get languageServiceDisconnected => '语言服务连接已断开';

  @override
  String get saved => '已保存';

  @override
  String get fileChangedExternallySavingStoppedTapThe =>
      '文件已被外部修改，保存已停止。点击标题下方状态可重新载入。';

  @override
  String get fileChangedExternally => '文件已被外部修改';

  @override
  String pSavingStoppedToAvoidOverwritingDisk(Object? p0) {
    return '$p0\n\n为避免覆盖磁盘上的修改，已停止保存。重新载入将丢弃此文件尚未保存的编辑内容。';
  }

  @override
  String get reloadFromDisk => '重新载入';

  @override
  String unableToReadP(Object? p0) {
    return '无法读取 $p0';
  }

  @override
  String get aFileOperationIsInProgressWait => '文件操作正在进行，请稍后再关闭';

  @override
  String get aFileOperationIsInProgressWait552 => '文件操作正在进行，请等待完成后再关闭项目';

  @override
  String get fileChangedTapToResolve => '文件已变更 · 点击处理';

  @override
  String get saveFailedTapToRetry => '保存失败 · 点击重试';

  @override
  String get saving => '正在保存…';

  @override
  String get unsaved => '未保存';

  @override
  String get project => '项目';

  @override
  String get versionControl => '版本控制';

  @override
  String get closeProject => '关闭项目';

  @override
  String get selectAFileFromTheProjectTool => '从“项目”工具窗口选择文件以开始编辑';

  @override
  String get openProjectToolWindow => '打开项目工具窗口';

  @override
  String get editorOptions => '编辑器选项';

  @override
  String get settingsSaveAutomaticallyPinchInTheCode => '设置自动保存，也可在代码区双指缩放。';

  @override
  String get display => '显示';

  @override
  String get fontSize => '字号';

  @override
  String get font => '字体';

  @override
  String get builtIn => '内置';

  @override
  String get colorScheme => '配色方案';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get terminal => '终端';

  @override
  String get editing => '编辑行为';

  @override
  String get softWraps => '软换行';

  @override
  String get wrapLongLinesWithoutInsertingLineBreaks => '长行自动折行显示，不插入换行符';

  @override
  String get scrollLongLinesHorizontallyLineNumbersStay => '长行横向滚动，行号保持可见';

  @override
  String deleteP576(Object? p0) {
    return '删除「$p0」？';
  }

  @override
  String get permanentlyDeleteTheSelectedFileOrDirectory =>
      '将永久删除所选文件或目录及其内容，此操作无法撤销。';

  @override
  String get name => '名称';

  @override
  String get newDirectory => '新建目录';

  @override
  String get newFile => '新建文件';

  @override
  String get installMissingAndroidBuildComponents => '补齐 Android 构建组件？';

  @override
  String get componentsCurrentlyUnavailable => '组件暂时无法安装';

  @override
  String get theBuildFailedBecauseTheseComponentsAre => '本次构建缺少或无法使用以下组件：';

  @override
  String get preflightFoundTheseMissingOrUnusableComponents =>
      '构建前检查发现以下组件缺失或不可用：';

  @override
  String theBuildWillPAfterInstallationDownload(Object? p0) {
    return '安装完成后$p0构建。下载进度会显示在控制台中。';
  }

  @override
  String get installAndRetry => '安装并重试';

  @override
  String get installAndContinue => '安装并继续';

  @override
  String get starting => '正在启动';

  @override
  String get rerun => '重新运行';

  @override
  String get run => '运行';

  @override
  String get hotReload => '热重载';

  @override
  String get stopRun => '停止运行';

  @override
  String get switchRunTarget => '切换运行目标？';

  @override
  String get stopTheCurrentRunAndStartThe => '将停止当前运行，并在新目标上运行项目。';

  @override
  String get switchAndRun => '切换并运行';

  @override
  String get tasks => '任务';

  @override
  String currentProjectP(Object? p0) {
    return '当前项目： $p0';
  }

  @override
  String currentTaskP(Object? p0) {
    return '当前任务：$p0';
  }

  @override
  String get tasksUseSeparateTerminalsConflictingActionsAre =>
      '各任务使用独立终端，冲突操作暂不可用。';

  @override
  String get dependencies => '依赖';

  @override
  String get fetchDependenciesAndWritePackageConfig => '获取依赖并写入 package_config';

  @override
  String get upgradeDependenciesWithinConstraints => '按约束升级依赖';

  @override
  String get listOutdatedDependencies => '列出可升级的依赖';

  @override
  String get build => '构建';

  @override
  String get buildThenInstallOnTheSelectedAndroid =>
      '构建完成后通过 ADB 安装到选中的 Android 设备';

  @override
  String get buildAReleaseApkThenChooseAdb => '生成发布 APK；之后可选 ADB 设备或系统安装器';

  @override
  String get outputDirectoryBuildWeb => '输出目录：build/web';

  @override
  String get dartCompileExeOutputBuildPackageName =>
      'dart compile exe，输出 build/<包名>；完成后可在终端直接运行';

  @override
  String get code => '代码';

  @override
  String get runBatchAnalysisAndShowResultsIn => '分析器批量诊断，输出到终端';

  @override
  String get runTestsInTheTestDirectory => '运行 test/ 目录下的测试';

  @override
  String get maintenance => '维护';

  @override
  String get deleteBuildAndDartToolCaches => '删除 build/ 与 .dart_tool 缓存';

  @override
  String get checkFlutterAndAndroidToolchainHealth =>
      '检查 Flutter/Android 工具链健康度';

  @override
  String failedToReadDevicesP(Object? p0) {
    return '读取设备失败： $p0';
  }

  @override
  String get selectPlatform => '选择平台';

  @override
  String get webPreview => 'Web 预览';

  @override
  String get runTarget => '运行目标';

  @override
  String get refresh => '刷新';

  @override
  String get previewInsideTheIdeWithoutADevice => '在 IDE 内预览，无需连接设备';

  @override
  String get connectAndroidDevice => '连接 Android 设备';

  @override
  String get closeOthers => '关闭其他';

  @override
  String closeP(Object? p0) {
    return '关闭 $p0';
  }

  @override
  String get fileDoesNotExist => '文件不存在';

  @override
  String get cannotInstallAllowFlitToInstallUnknown =>
      '无法安装：请先在系统设置里授予 Flit“安装未知应用”权限';

  @override
  String get installLocally => '安装到本机';

  @override
  String get noApplicationCanOpenThisFile => '没有能打开此文件的应用';

  @override
  String get openWith => '用其他应用打开';

  @override
  String get unableToShareThisFile => '无法分享该文件';

  @override
  String get share => '分享';

  @override
  String linePPIssues(Object? p0, Object? p1) {
    return '第 $p0 行 · $p1 个问题';
  }

  @override
  String get quickFix => '快速修复';

  @override
  String get completionItemExpiredTypeAgain => '补全项已失效，请重新输入';

  @override
  String get problemsCurrentFile => '问题 · 当前文件';

  @override
  String get noProblems => '暂无问题';

  @override
  String linePColumnP(Object? p0, Object? p1) {
    return '第 $p0 行 · 第 $p1 列';
  }

  @override
  String get syntaxHighlighting => '语法高亮';

  @override
  String get startingDartAnalyzer => '正在启动 Dart 分析器…';

  @override
  String get dartAnalysisReady => 'Dart · 代码分析就绪';

  @override
  String get dartBasicCompletion => 'Dart · 基础补全';

  @override
  String problemsP(Object? p0) {
    return '问题 $p0';
  }

  @override
  String get browseSharedStorageAndSelectFilesTo =>
      '浏览共享存储，选择需要复制到当前项目的文件。此浏览器仅用于导入文件。';

  @override
  String unableToReadDirectoryP(Object? p0) {
    return '无法读取目录： $p0';
  }

  @override
  String get pasteHere => '粘贴到此处';

  @override
  String copiedPLongPressTheDestinationDirectory(Object? p0) {
    return '已复制 $p0，长按目标目录可粘贴';
  }

  @override
  String get cut => '剪切';

  @override
  String cutPLongPressTheDestinationDirectory(Object? p0) {
    return '已剪切 $p0，长按目标目录可粘贴';
  }

  @override
  String copiedPReturnToTheProjectAnd(Object? p0) {
    return '已复制 $p0，返回项目后长按目标目录可粘贴';
  }

  @override
  String get sharedStorageImportOnly => '共享存储（仅导入）';

  @override
  String get newItem => '新建';

  @override
  String get switchLocation => '切换位置';

  @override
  String get copyFromSharedStorage => '从共享存储复制…';

  @override
  String get svgPreviewFromEditorBuffer => 'SVG 预览(内容来自编辑缓冲)';

  @override
  String get emptyFile => '空文件';

  @override
  String get unableToRenderSvgContentIsNot => '无法渲染该 SVG：内容不是有效的 SVG';

  @override
  String unableToRenderSvgP(Object? p0) {
    return '无法渲染该 SVG：$p0';
  }

  @override
  String get preview => '预览';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get commitStagedChanges => '提交已暂存的更改';

  @override
  String get commitMessage => '提交消息';

  @override
  String get showStagedDiff => '显示已暂存的差异';

  @override
  String get showUnstagedDiff => '显示未暂存的差异';

  @override
  String get markConflictResolvedStage => '标记冲突已解决（暂存）';

  @override
  String get stageFile => '暂存文件';

  @override
  String get unstage => '取消暂存';

  @override
  String get rollbackUnstagedChanges => '回滚未暂存的更改';

  @override
  String get rollbackChanges => '回滚更改？';

  @override
  String discardUnstagedChangesInPStagedChanges(Object? p0) {
    return '将丢弃 $p0 未暂存的更改，已暂存的内容保留。此操作无法撤销。';
  }

  @override
  String get branches => '分支';

  @override
  String get createAndSwitchBranch => '新建并切换分支';

  @override
  String get newBranch => '新建分支';

  @override
  String get branchName => '分支名称';

  @override
  String get commitHistory => '提交历史';

  @override
  String get remoteOrigin => '远程仓库 · origin';

  @override
  String get commitAuthorThisRepository => '提交者信息（当前仓库）';

  @override
  String get email => '邮箱';

  @override
  String get detachedHead => '游离 HEAD';

  @override
  String get refreshVersionControlStatus => '刷新版本控制状态';

  @override
  String get repositorySettings => '仓库设置';

  @override
  String get remotes => '远程仓库';

  @override
  String get commitAuthor => '提交者信息';

  @override
  String get pull => '拉取';

  @override
  String get push => '推送';

  @override
  String get operationInProgressViewProgressOrStop => '操作进行中，可在终端查看进度或停止。';

  @override
  String get thisProjectHasNoGitRepositoryYet => '此项目尚未创建 Git 仓库。';

  @override
  String get initializeRepository => '初始化仓库';

  @override
  String get noLocalChanges => '没有本地更改';

  @override
  String get conflictsFoundResolveThemInTheEditor => '存在冲突：编辑文件解决冲突后，逐个暂存。';

  @override
  String get conflicts => '冲突';

  @override
  String get untracked => '未跟踪';

  @override
  String get stagedWithAdditionalUnstagedChanges => '已暂存，另有未暂存更改';

  @override
  String get staged => '已暂存';

  @override
  String get stageAllChanges => '暂存所有更改';

  @override
  String commitChangesP(Object? p0) {
    return '提交更改 · $p0';
  }

  @override
  String get signOutOfGithub => '退出 GitHub 登录？';

  @override
  String get removeGithubComCredentialsFromThisDevice =>
      '将移除此设备上 github.com 的登录凭据。';

  @override
  String get signOut => '退出登录';

  @override
  String get ghIsNotInstalledCompleteTheFlutter =>
      '未安装 gh · 在开发环境页完成 Flutter 阶段安装后可用';

  @override
  String get notSignedInSignInToClone => '未登录 · 私有仓库的克隆与推送需要登录';

  @override
  String get signedInGitCredentialHelperConfigured => '已登录 · git 凭据助手已接入';

  @override
  String get githubAccount => 'GitHub 账户';

  @override
  String get working => '正在处理…';

  @override
  String get waitingForBrowserAuthorization => '等待浏览器授权…';

  @override
  String signedInP(Object? p0) {
    return '已登录 · $p0';
  }

  @override
  String get viewAuthorizationCode => '查看授权码';

  @override
  String get signIn => '登录';

  @override
  String get ghIsNotInstalledCompleteTheFlutter708 =>
      '尚未安装 gh，请先在开发环境页完成 Flutter 阶段安装';

  @override
  String get githubSignIn => 'GitHub 登录';

  @override
  String get signInCancelled => '已取消登录';

  @override
  String signInIncompleteExitCodePP(Object? p0, Object? p1) {
    return '登录未完成（退出码 $p0）$p1';
  }

  @override
  String signInFailedP(Object? p0) {
    return '登录失败：$p0';
  }

  @override
  String get githubSignOut => '退出 GitHub 登录';

  @override
  String githubSignOutIncompleteExitCodeP(Object? p0) {
    return '退出 GitHub 登录未完成（退出码 $p0）';
  }

  @override
  String githubSignOutFailedP(Object? p0) {
    return '退出 GitHub 登录失败：$p0';
  }

  @override
  String get unableToOpenBrowserVisitGithubCom =>
      '无法打开浏览器，请访问 github.com/login/device';

  @override
  String failedToOpenBrowserP(Object? p0) {
    return '打开浏览器失败：$p0';
  }

  @override
  String get signInToGithub => '登录 GitHub';

  @override
  String get copyTheDeviceCodeAndAuthorizeIn => '复制设备授权码后，在浏览器中授权。完成后自动更新登录状态。';

  @override
  String get later => '稍后处理';

  @override
  String get cancelSignIn => '取消登录';

  @override
  String get copyAndOpenBrowser => '复制并打开浏览器';

  @override
  String get openTheGitRepositoryRootToUse => '请打开 Git 仓库根目录后使用版本控制';

  @override
  String get aTaskIsRunningStopItBefore => '当前有任务正在运行，请先结束后再执行 Git 操作';

  @override
  String get saveFailedGitOperationCancelled => '保存失败，已取消 Git 操作';

  @override
  String pIncompleteExitCodePSeeTerminal(Object? p0, Object? p1) {
    return '$p0 未完成（退出码 $p1），请查看终端输出';
  }

  @override
  String get enterACommitMessage => '请输入提交消息';

  @override
  String get resolveConflictsAndStageTheFilesFirst => '请先解决冲突并暂存文件';

  @override
  String get stageTheFilesToCommitFirst => '请先暂存需要提交的文件';

  @override
  String get commit => '提交';

  @override
  String get theCurrentFileStatusDoesNotSupport => '当前文件状态不支持回滚';

  @override
  String get commitOrRollbackChangesBeforeSwitchingBranches =>
      '请先提交或回滚当前更改，再切换分支';

  @override
  String get switchBranch => '切换分支';

  @override
  String get commitOrRollbackChangesBeforePulling => '请先提交或回滚当前更改，再拉取';

  @override
  String get thisBranchHasNoUpstreamPushAnd => '当前分支未设置上游分支，请先推送并关联远程分支';

  @override
  String get switchToABranchAndCreateA => '请先切换到分支并创建提交';

  @override
  String get resolveConflictsFirst => '请先解决冲突';

  @override
  String get firstPushRequiresARemoteConfigureOrigin =>
      '首次推送需要一个远程仓库，请在「远程仓库」中配置 origin';

  @override
  String get firstPush => '首次推送';

  @override
  String get enterAValidRepositoryUrl => '请输入有效的仓库地址';

  @override
  String get enterTheCommitAuthorNameAndEmail => '请填写提交者名称和邮箱';

  @override
  String get invalidSourcePath => '源路径无效';

  @override
  String get filesCannotBeMovedOutsideTheirProject => '不能将文件移出它所属的项目目录';

  @override
  String get destinationMustBeInsideTheCurrentProject => '目标必须位于当前项目目录内';

  @override
  String get cannotCopyOrMoveADirectoryInto => '不能将目录复制或移动到它自己内部';

  @override
  String get onlyEntriesInsideTheCurrentProjectCan => '只能删除当前项目目录中的条目';

  @override
  String get invalidName => '名称无效';

  @override
  String get renameIsOnlyAllowedWithinTheCurrent => '只能在当前项目目录内重命名';

  @override
  String get filesAndDirectoriesCanOnlyBeCreated => '只能在当前项目目录中创建文件或目录';

  @override
  String operationFailedExitCodeP(Object? p0) {
    return '操作失败（退出码 $p0）';
  }

  @override
  String operationFailedP(Object? p0) {
    return '操作失败：$p0';
  }

  @override
  String get connected => '已连接';

  @override
  String get unauthorized => '未授权';

  @override
  String get offline => '离线';

  @override
  String get authenticating => '认证中';

  @override
  String get localDevice => '本机';

  @override
  String localDeviceP(Object? p0) {
    return '本机 · $p0';
  }

  @override
  String lanP(Object? p0) {
    return '局域网 $p0';
  }

  @override
  String get lan => '局域网';

  @override
  String get failedToReadDevices => '读取设备失败';

  @override
  String adbDidNotReturnADeviceList(Object? p0) {
    return 'ADB 未返回设备列表：$p0';
  }

  @override
  String get backgroundExecutionAndNotifications => '后台运行与通知';

  @override
  String get setupAndBuildsMayTakeAWhile => '初始化和构建可能耗时较长，建议开启：';

  @override
  String get theForegroundServiceOnlyShowsGeneralTask =>
      '前台服务仅显示通用运行状态，开关在系统通知设置中，可稍后在「设置 → 后台与通知」里再调。';

  @override
  String get continueAction => '继续';

  @override
  String get allowSharedStorageAccess => '允许访问共享存储？';

  @override
  String get withPermissionFlitCanAccessSharedStorage =>
      '授权后，Flit 可以访问共享存储中的文件。你也可以暂不授权，继续使用应用内项目目录；应用内文件不会显示在普通文件管理器中，卸载 Flit 时会一并删除。';

  @override
  String get notNow => '暂不授权';

  @override
  String get grantAccess => '继续授权';

  @override
  String get sharedStoragePermissionDeniedAppPrivateProjects =>
      '未授予共享存储权限，仍可使用应用内项目目录';

  @override
  String gitCommandFailedP(Object? p0) {
    return 'Git 执行失败（$p0）';
  }

  @override
  String get gitUnavailableCheckTheDevelopmentEnvironment => 'Git 不可用，请检查开发环境';

  @override
  String get theProjectIsInsideAParentGit => '当前项目位于上级 Git 仓库中，请打开仓库根目录后使用版本控制';

  @override
  String get thisFileIsUntrackedStageItTo => '此文件尚未跟踪，暂存后可查看完整差异。';

  @override
  String get noTextDiffPossiblyABinaryFile => '没有文本差异（可能是二进制文件或文件模式变化）。';

  @override
  String get language => '语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get refreshVersionsLater => '可稍后点击刷新重试';

  @override
  String get showingPreviousCatalog => '暂时显示上次获取的目录';

  @override
  String currentVersionSuffix(Object? p0) {
    return ' · 当前 $p0';
  }

  @override
  String repairCountSuffix(Object? p0) {
    return ' · $p0 个需修复';
  }

  @override
  String get retryBuildVerb => '重新尝试一次';

  @override
  String get continueBuildVerb => '继续';

  @override
  String get startingEllipsis => '正在启动…';

  @override
  String get prereleaseSuffix => ' · 预发布';

  @override
  String get cannotRun => '无法运行';

  @override
  String get running => '运行中';

  @override
  String get exited => '已结束';

  @override
  String get switchVersion => '切换';

  @override
  String get requestFailed => '✗ 请求失败';

  @override
  String get currentSuffix => ' · 当前';

  @override
  String get installed => '已安装';

  @override
  String get installationIncomplete => '安装不完整';

  @override
  String get replaceSharedToolsSuffix => ' · 替换共用工具';

  @override
  String get needsRepair => '需修复';

  @override
  String get compilationFailed => '编译失败';

  @override
  String get unstaged => '未暂存';
}
