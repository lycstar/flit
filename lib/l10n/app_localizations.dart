import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @addWebSupport.
  ///
  /// In zh, this message translates to:
  /// **'添加 Web 支持？'**
  String get addWebSupport;

  /// No description provided for @addWebSupportDescription.
  ///
  /// In zh, this message translates to:
  /// **'此项目没有 web 目录。Flit 将先执行 flutter create --platforms web . 添加 Web 支持，再启动预览。'**
  String get addWebSupportDescription;

  /// No description provided for @addAndRun.
  ///
  /// In zh, this message translates to:
  /// **'添加并运行'**
  String get addAndRun;

  /// No description provided for @recommended.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get recommended;

  /// No description provided for @space.
  ///
  /// In zh, this message translates to:
  /// **'空格'**
  String get space;

  /// No description provided for @enter.
  ///
  /// In zh, this message translates to:
  /// **'换行'**
  String get enter;

  /// No description provided for @backspace.
  ///
  /// In zh, this message translates to:
  /// **'退格'**
  String get backspace;

  /// No description provided for @capsLock.
  ///
  /// In zh, this message translates to:
  /// **'大写'**
  String get capsLock;

  /// No description provided for @environmentCommandFailedExitCodeP.
  ///
  /// In zh, this message translates to:
  /// **'环境命令执行失败（退出码 {p0}）'**
  String environmentCommandFailedExitCodeP(Object? p0);

  /// No description provided for @readFailedP.
  ///
  /// In zh, this message translates to:
  /// **'读取失败：{p0}'**
  String readFailedP(Object? p0);

  /// No description provided for @environmentVariables.
  ///
  /// In zh, this message translates to:
  /// **'环境变量'**
  String get environmentVariables;

  /// No description provided for @refreshSnapshot.
  ///
  /// In zh, this message translates to:
  /// **'刷新快照'**
  String get refreshSnapshot;

  /// No description provided for @searchVariablesOrValues.
  ///
  /// In zh, this message translates to:
  /// **'搜索变量或值'**
  String get searchVariablesOrValues;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @noMatchingVariables.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的变量'**
  String get noMatchingVariables;

  /// No description provided for @readOnlyEnvironmentSnapshotForNewTasks.
  ///
  /// In zh, this message translates to:
  /// **'新任务的环境变量快照（只读）\n不包含终端中临时 export 的值。展开变量可查看完整值。'**
  String get readOnlyEnvironmentSnapshotForNewTasks;

  /// No description provided for @searchResultsP.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果 · {p0}'**
  String searchResultsP(Object? p0);

  /// No description provided for @toolchains.
  ///
  /// In zh, this message translates to:
  /// **'工具链'**
  String get toolchains;

  /// No description provided for @pathCommandLookupOrder.
  ///
  /// In zh, this message translates to:
  /// **'PATH · 按顺序查找命令'**
  String get pathCommandLookupOrder;

  /// No description provided for @commandSearchPaths.
  ///
  /// In zh, this message translates to:
  /// **'命令搜索路径'**
  String get commandSearchPaths;

  /// No description provided for @pDirectoriesInLookupOrder.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个目录 · 按顺序查找'**
  String pDirectoriesInLookupOrder(Object? p0);

  /// No description provided for @currentDirectory.
  ///
  /// In zh, this message translates to:
  /// **'(当前目录)'**
  String get currentDirectory;

  /// No description provided for @directoriesAndCaches.
  ///
  /// In zh, this message translates to:
  /// **'目录与缓存'**
  String get directoriesAndCaches;

  /// No description provided for @otherVariablesP.
  ///
  /// In zh, this message translates to:
  /// **'其他变量 · {p0}'**
  String otherVariablesP(Object? p0);

  /// No description provided for @copyValue.
  ///
  /// In zh, this message translates to:
  /// **'复制值'**
  String get copyValue;

  /// No description provided for @variableValueCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制变量值'**
  String get variableValueCopied;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'(空)'**
  String get empty;

  /// No description provided for @allowInstallationFromUnknownSourcesThenTap.
  ///
  /// In zh, this message translates to:
  /// **'需要先授权“安装未知应用”，授权后重新点击安装'**
  String get allowInstallationFromUnknownSourcesThenTap;

  /// No description provided for @downloadCompleteP.
  ///
  /// In zh, this message translates to:
  /// **'下载完成:{p0}'**
  String downloadCompleteP(Object? p0);

  /// No description provided for @downloadFailedP.
  ///
  /// In zh, this message translates to:
  /// **'下载失败:{p0}'**
  String downloadFailedP(Object? p0);

  /// No description provided for @appUpdates.
  ///
  /// In zh, this message translates to:
  /// **'App 更新'**
  String get appUpdates;

  /// No description provided for @compareThisBuildWithGithubReleasesOr.
  ///
  /// In zh, this message translates to:
  /// **'当前构建对照 GitHub 发布；历史版本的产物可下载安装。'**
  String get compareThisBuildWithGithubReleasesOr;

  /// No description provided for @failedToFetchReleasesP.
  ///
  /// In zh, this message translates to:
  /// **'发布列表请求失败：{p0}'**
  String failedToFetchReleasesP(Object? p0);

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @localBuildVersionComparisonUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'本地构建，不比对版本'**
  String get localBuildVersionComparisonUnavailable;

  /// No description provided for @upToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新'**
  String get upToDate;

  /// No description provided for @updateAvailableP.
  ///
  /// In zh, this message translates to:
  /// **'有更新:{p0}'**
  String updateAvailableP(Object? p0);

  /// No description provided for @currentBuild.
  ///
  /// In zh, this message translates to:
  /// **'当前构建'**
  String get currentBuild;

  /// No description provided for @latestRelease.
  ///
  /// In zh, this message translates to:
  /// **'最新发布'**
  String get latestRelease;

  /// No description provided for @noAssets.
  ///
  /// In zh, this message translates to:
  /// **'无产物'**
  String get noAssets;

  /// No description provided for @downloadAndInstall.
  ///
  /// In zh, this message translates to:
  /// **'下载并安装'**
  String get downloadAndInstall;

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @systemMonospace.
  ///
  /// In zh, this message translates to:
  /// **'系统等宽字体'**
  String get systemMonospace;

  /// No description provided for @settingsStorageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'设置存储不可用'**
  String get settingsStorageUnavailable;

  /// No description provided for @checking.
  ///
  /// In zh, this message translates to:
  /// **'检测中…'**
  String get checking;

  /// No description provided for @failedToSaveOrLoadSettingsP.
  ///
  /// In zh, this message translates to:
  /// **'设置保存或读取失败：{p0}'**
  String failedToSaveOrLoadSettingsP(Object? p0);

  /// No description provided for @unableToRequestPermissionYouCanChange.
  ///
  /// In zh, this message translates to:
  /// **'无法请求系统权限，可稍后在系统应用设置中调整'**
  String get unableToRequestPermissionYouCanChange;

  /// No description provided for @proxySettingsUpdatedAppliesToNewTerminals.
  ///
  /// In zh, this message translates to:
  /// **'代理设置已更新，新终端和任务生效'**
  String get proxySettingsUpdatedAppliesToNewTerminals;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @ideSettings.
  ///
  /// In zh, this message translates to:
  /// **'IDE 设置'**
  String get ideSettings;

  /// No description provided for @configureDevelopmentToolsDeviceConnectionsAndThe.
  ///
  /// In zh, this message translates to:
  /// **'配置开发环境、设备连接和编辑器选项。'**
  String get configureDevelopmentToolsDeviceConnectionsAndThe;

  /// No description provided for @general.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get general;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'账户'**
  String get account;

  /// No description provided for @developmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'开发环境'**
  String get developmentEnvironment;

  /// No description provided for @viewToolchainPathsAndCommandEnvironmentSnapshots.
  ///
  /// In zh, this message translates to:
  /// **'查看工具链路径与命令环境快照'**
  String get viewToolchainPathsAndCommandEnvironmentSnapshots;

  /// No description provided for @connectDevice.
  ///
  /// In zh, this message translates to:
  /// **'连接设备'**
  String get connectDevice;

  /// No description provided for @wirelessDebuggingPairingAndAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'无线调试 · 配对与认证状态'**
  String get wirelessDebuggingPairingAndAuthorization;

  /// No description provided for @useSystemProxy.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统代理'**
  String get useSystemProxy;

  /// No description provided for @noSystemProxyDetectedItWillBe.
  ///
  /// In zh, this message translates to:
  /// **'未检测到系统代理；检测到后自动使用'**
  String get noSystemProxyDetectedItWillBe;

  /// No description provided for @backgroundAndNotifications.
  ///
  /// In zh, this message translates to:
  /// **'后台与通知'**
  String get backgroundAndNotifications;

  /// No description provided for @foregroundService.
  ///
  /// In zh, this message translates to:
  /// **'前台服务'**
  String get foregroundService;

  /// No description provided for @showBuildAndTaskStatusInA.
  ///
  /// In zh, this message translates to:
  /// **'常驻通知展示构建与任务的运行状态'**
  String get showBuildAndTaskStatusInA;

  /// No description provided for @backgroundExecution.
  ///
  /// In zh, this message translates to:
  /// **'后台运行'**
  String get backgroundExecution;

  /// No description provided for @ignoreBatteryOptimizationToReduceBackgroundTask.
  ///
  /// In zh, this message translates to:
  /// **'忽略电池优化，减少切到后台后任务被中断'**
  String get ignoreBatteryOptimizationToReduceBackgroundTask;

  /// No description provided for @editorAndTerminal.
  ///
  /// In zh, this message translates to:
  /// **'编辑器与终端'**
  String get editorAndTerminal;

  /// No description provided for @editorSettings.
  ///
  /// In zh, this message translates to:
  /// **'编辑器设置'**
  String get editorSettings;

  /// No description provided for @fontColorSchemeSoftWraps.
  ///
  /// In zh, this message translates to:
  /// **'字体 · 配色方案 · 软换行'**
  String get fontColorSchemeSoftWraps;

  /// No description provided for @terminalSettings.
  ///
  /// In zh, this message translates to:
  /// **'终端设置'**
  String get terminalSettings;

  /// No description provided for @pinchToZoomFontSizeMonospaceFont.
  ///
  /// In zh, this message translates to:
  /// **'双指缩放 · 字号 · 等宽字体 · 行高'**
  String get pinchToZoomFontSizeMonospaceFont;

  /// No description provided for @aboutFlit.
  ///
  /// In zh, this message translates to:
  /// **'关于 Flit'**
  String get aboutFlit;

  /// No description provided for @checkForUpdatesDownloadPreviousVersions.
  ///
  /// In zh, this message translates to:
  /// **'检查更新 · 下载安装历史版本'**
  String get checkForUpdatesDownloadPreviousVersions;

  /// No description provided for @buildCommit.
  ///
  /// In zh, this message translates to:
  /// **'构建提交'**
  String get buildCommit;

  /// No description provided for @platform.
  ///
  /// In zh, this message translates to:
  /// **'运行平台'**
  String get platform;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get enabled;

  /// No description provided for @denied.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get denied;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'未开启'**
  String get disabled;

  /// No description provided for @allowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get allowed;

  /// No description provided for @notConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get notConfigured;

  /// No description provided for @flutterProject.
  ///
  /// In zh, this message translates to:
  /// **'Flutter 工程'**
  String get flutterProject;

  /// No description provided for @dartProject.
  ///
  /// In zh, this message translates to:
  /// **'Dart 工程'**
  String get dartProject;

  /// No description provided for @folder.
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get folder;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'名称不能为空'**
  String get nameCannotBeEmpty;

  /// No description provided for @nameCannotContainPathSeparators.
  ///
  /// In zh, this message translates to:
  /// **'名称不能包含路径分隔符'**
  String get nameCannotContainPathSeparators;

  /// No description provided for @nameCannotBeOr.
  ///
  /// In zh, this message translates to:
  /// **'名称不能是 . 或 ..'**
  String get nameCannotBeOr;

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @pMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 分钟前'**
  String pMinutesAgo(Object? p0);

  /// No description provided for @pHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 小时前'**
  String pHoursAgo(Object? p0);

  /// No description provided for @pDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 天前'**
  String pDaysAgo(Object? p0);

  /// No description provided for @projectDirectoryIsNotReadable.
  ///
  /// In zh, this message translates to:
  /// **'工程目录不可读'**
  String get projectDirectoryIsNotReadable;

  /// No description provided for @aToolchainTaskIsRunningWaitBefore.
  ///
  /// In zh, this message translates to:
  /// **'工具链任务正在进行，请完成后再打开项目'**
  String get aToolchainTaskIsRunningWaitBefore;

  /// No description provided for @closeThisProjectBeforeRenamingOrDeleting.
  ///
  /// In zh, this message translates to:
  /// **'请先关闭该工程，再重命名或删除它'**
  String get closeThisProjectBeforeRenamingOrDeleting;

  /// No description provided for @whereAreProjectsStored.
  ///
  /// In zh, this message translates to:
  /// **'工程保存在哪里？'**
  String get whereAreProjectsStored;

  /// No description provided for @projectDirectoryP.
  ///
  /// In zh, this message translates to:
  /// **'工程目录\n{p0}\n\n'**
  String projectDirectoryP(Object? p0);

  /// No description provided for @uninstallingTheAppOrClearingItsData.
  ///
  /// In zh, this message translates to:
  /// **'卸载应用或清除应用数据会连同工程一起删除。备份方式：\n'**
  String get uninstallingTheAppOrClearingItsData;

  /// No description provided for @pushToGithubFromVersionControl.
  ///
  /// In zh, this message translates to:
  /// **'• 推送到 GitHub（版本控制面板）\n'**
  String get pushToGithubFromVersionControl;

  /// No description provided for @openFilesFlitProjectsAndCopyThe.
  ///
  /// In zh, this message translates to:
  /// **'• 系统「文件」应用 → 侧栏「Flit 工程」，可把整个目录复制到共享存储或其他位置\n'**
  String get openFilesFlitProjectsAndCopyThe;

  /// No description provided for @longPressAFileInTheEditor.
  ///
  /// In zh, this message translates to:
  /// **'• 编辑器文件树长按文件 → 分享'**
  String get longPressAFileInTheEditor;

  /// No description provided for @gotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get gotIt;

  /// No description provided for @deleteProjectP.
  ///
  /// In zh, this message translates to:
  /// **'删除工程「{p0}」？'**
  String deleteProjectP(Object? p0);

  /// No description provided for @theDirectoryAndAllItsFilesWill.
  ///
  /// In zh, this message translates to:
  /// **'目录及其中的所有文件会被删除，且不可恢复。'**
  String get theDirectoryAndAllItsFilesWill;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @cloneProject.
  ///
  /// In zh, this message translates to:
  /// **'克隆项目'**
  String get cloneProject;

  /// No description provided for @createProject.
  ///
  /// In zh, this message translates to:
  /// **'创建项目'**
  String get createProject;

  /// No description provided for @clone.
  ///
  /// In zh, this message translates to:
  /// **'克隆'**
  String get clone;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @pPSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'✓ {p0} {p1}成功'**
  String pPSucceeded(Object? p0, Object? p1);

  /// No description provided for @pCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已中止{p0}'**
  String pCancelled(Object? p0);

  /// No description provided for @cloneFailedSignInToGithubFirst.
  ///
  /// In zh, this message translates to:
  /// **'克隆失败：私有仓库需要先登录 GitHub（克隆页 → GitHub 账户 → 登录）'**
  String get cloneFailedSignInToGithubFirst;

  /// No description provided for @pFailedExitCodePSeeTerminal.
  ///
  /// In zh, this message translates to:
  /// **'✗ {p0}失败（退出码 {p1}），详细输出见终端'**
  String pFailedExitCodePSeeTerminal(Object? p0, Object? p1);

  /// No description provided for @newProject.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get newProject;

  /// No description provided for @cloneRepository.
  ///
  /// In zh, this message translates to:
  /// **'克隆仓库'**
  String get cloneRepository;

  /// No description provided for @projectsAreStoredInTheAppAnd.
  ///
  /// In zh, this message translates to:
  /// **'工程存在应用内部，卸载即删 · 备份方式'**
  String get projectsAreStoredInTheAppAnd;

  /// No description provided for @checkingDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'正在检查开发环境'**
  String get checkingDevelopmentEnvironment;

  /// No description provided for @openDevelopmentEnvironmentForDetails.
  ///
  /// In zh, this message translates to:
  /// **'可进入开发环境查看检测详情。'**
  String get openDevelopmentEnvironmentForDetails;

  /// No description provided for @viewDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'查看开发环境'**
  String get viewDevelopmentEnvironment;

  /// No description provided for @developmentEnvironmentIsNotReady.
  ///
  /// In zh, this message translates to:
  /// **'开发环境未就绪'**
  String get developmentEnvironmentIsNotReady;

  /// No description provided for @yourProjectsWillAppearHereAfterSetup.
  ///
  /// In zh, this message translates to:
  /// **'完成环境配置后，这里会列出你的工程'**
  String get yourProjectsWillAppearHereAfterSetup;

  /// No description provided for @setUpDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'配置开发环境'**
  String get setUpDevelopmentEnvironment;

  /// No description provided for @failedToReadProjectDirectory.
  ///
  /// In zh, this message translates to:
  /// **'读取工程目录失败'**
  String get failedToReadProjectDirectory;

  /// No description provided for @noProjectsYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有工程'**
  String get noProjectsYet;

  /// No description provided for @createAProjectOrCloneAGit.
  ///
  /// In zh, this message translates to:
  /// **'新建工程，或从 Git 仓库克隆'**
  String get createAProjectOrCloneAGit;

  /// No description provided for @projectsP.
  ///
  /// In zh, this message translates to:
  /// **'工程 · {p0}'**
  String projectsP(Object? p0);

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @renameProject.
  ///
  /// In zh, this message translates to:
  /// **'重命名工程'**
  String get renameProject;

  /// No description provided for @projectDirectoryName.
  ///
  /// In zh, this message translates to:
  /// **'工程目录名'**
  String get projectDirectoryName;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @pAlreadyExistsChooseAnotherDirectoryName.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 已存在，请换一个目录名'**
  String pAlreadyExistsChooseAnotherDirectoryName(Object? p0);

  /// No description provided for @unableToCheckDestinationCheckTheDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'无法检查目标目录，请检查开发环境后重试'**
  String get unableToCheckDestinationCheckTheDevelopment;

  /// No description provided for @clonePreflightFailedP.
  ///
  /// In zh, this message translates to:
  /// **'克隆前检查失败：{p0}'**
  String clonePreflightFailedP(Object? p0);

  /// No description provided for @getFromVersionControl.
  ///
  /// In zh, this message translates to:
  /// **'从版本控制获取项目'**
  String get getFromVersionControl;

  /// No description provided for @cloneARemoteRepositoryToLocalStorage.
  ///
  /// In zh, this message translates to:
  /// **'将远程仓库克隆到本地，克隆完成后打开项目。'**
  String get cloneARemoteRepositoryToLocalStorage;

  /// No description provided for @repository.
  ///
  /// In zh, this message translates to:
  /// **'仓库'**
  String get repository;

  /// No description provided for @repositoryUrl.
  ///
  /// In zh, this message translates to:
  /// **'仓库地址'**
  String get repositoryUrl;

  /// No description provided for @directoryNameOptional.
  ///
  /// In zh, this message translates to:
  /// **'目录名称（可选）'**
  String get directoryNameOptional;

  /// No description provided for @leaveEmptyToUseTheRepositoryName.
  ///
  /// In zh, this message translates to:
  /// **'留空则使用仓库名称'**
  String get leaveEmptyToUseTheRepositoryName;

  /// No description provided for @branchOptional.
  ///
  /// In zh, this message translates to:
  /// **'分支（可选）'**
  String get branchOptional;

  /// No description provided for @leaveEmptyToUseTheRemoteDefault.
  ///
  /// In zh, this message translates to:
  /// **'留空则使用远程仓库的默认分支'**
  String get leaveEmptyToUseTheRemoteDefault;

  /// No description provided for @shallowClone.
  ///
  /// In zh, this message translates to:
  /// **'浅克隆'**
  String get shallowClone;

  /// No description provided for @fetchOnlyTheLatestCommitUseGit.
  ///
  /// In zh, this message translates to:
  /// **'仅获取最近一次提交。可使用 git fetch --unshallow 获取完整历史。'**
  String get fetchOnlyTheLatestCommitUseGit;

  /// No description provided for @clonePreflight.
  ///
  /// In zh, this message translates to:
  /// **'克隆前检查'**
  String get clonePreflight;

  /// No description provided for @signInToGithubBeforeCloningA.
  ///
  /// In zh, this message translates to:
  /// **'私有仓库需要先登录 GitHub，登录后即可直接克隆。'**
  String get signInToGithubBeforeCloningA;

  /// No description provided for @ready.
  ///
  /// In zh, this message translates to:
  /// **'就绪'**
  String get ready;

  /// No description provided for @gitNotFoundCheckItsInstallationAnd.
  ///
  /// In zh, this message translates to:
  /// **'未找到 Git，请检查安装状态和 PATH'**
  String get gitNotFoundCheckItsInstallationAnd;

  /// No description provided for @unableToRunP.
  ///
  /// In zh, this message translates to:
  /// **'无法运行：{p0}'**
  String unableToRunP(Object? p0);

  /// No description provided for @location.
  ///
  /// In zh, this message translates to:
  /// **'保存位置'**
  String get location;

  /// No description provided for @startWithALowercaseLetterUseOnly.
  ///
  /// In zh, this message translates to:
  /// **'以小写字母开头，只能包含小写字母、数字和下划线'**
  String get startWithALowercaseLetterUseOnly;

  /// No description provided for @dartReservedWordsAndToolNamesCannot.
  ///
  /// In zh, this message translates to:
  /// **'不能使用 Dart 保留字或工具名称'**
  String get dartReservedWordsAndToolNamesCannot;

  /// No description provided for @useAReverseDomainNameSuchAs.
  ///
  /// In zh, this message translates to:
  /// **'使用反向域名格式，例如 com.example'**
  String get useAReverseDomainNameSuchAs;

  /// No description provided for @projectPAlreadyExistsChooseAnotherName.
  ///
  /// In zh, this message translates to:
  /// **'项目 {p0} 已存在，请换一个名称'**
  String projectPAlreadyExistsChooseAnotherName(Object? p0);

  /// No description provided for @unableToCheckDestinationCheckTheDevelopment146.
  ///
  /// In zh, this message translates to:
  /// **'无法检查目标目录，请查看开发环境后重试'**
  String get unableToCheckDestinationCheckTheDevelopment146;

  /// No description provided for @projectPreflightFailedP.
  ///
  /// In zh, this message translates to:
  /// **'创建前检查失败：{p0}'**
  String projectPreflightFailedP(Object? p0);

  /// No description provided for @projectConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'项目配置'**
  String get projectConfiguration;

  /// No description provided for @chooseTheProjectTypeNameAndTarget.
  ///
  /// In zh, this message translates to:
  /// **'设置项目类型、名称和目标平台。创建完成后打开项目。\n保存位置：{p0}'**
  String chooseTheProjectTypeNameAndTarget(Object? p0);

  /// No description provided for @projectDetails.
  ///
  /// In zh, this message translates to:
  /// **'项目信息'**
  String get projectDetails;

  /// No description provided for @projectName.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// No description provided for @lowercaseLettersNumbersAndUnderscores.
  ///
  /// In zh, this message translates to:
  /// **'小写字母、数字与下划线'**
  String get lowercaseLettersNumbersAndUnderscores;

  /// No description provided for @organizationOptional.
  ///
  /// In zh, this message translates to:
  /// **'组织标识（可选）'**
  String get organizationOptional;

  /// No description provided for @targetPlatforms.
  ///
  /// In zh, this message translates to:
  /// **'目标平台'**
  String get targetPlatforms;

  /// No description provided for @projectTemplate.
  ///
  /// In zh, this message translates to:
  /// **'项目模板'**
  String get projectTemplate;

  /// No description provided for @consoleApplication.
  ///
  /// In zh, this message translates to:
  /// **'控制台应用'**
  String get consoleApplication;

  /// No description provided for @dartPackage.
  ///
  /// In zh, this message translates to:
  /// **'Dart 包'**
  String get dartPackage;

  /// No description provided for @serverApplication.
  ///
  /// In zh, this message translates to:
  /// **'服务端应用'**
  String get serverApplication;

  /// No description provided for @runConsoleProjectsUsingDartRunIn.
  ///
  /// In zh, this message translates to:
  /// **'控制台项目可在终端使用 dart run 运行。'**
  String get runConsoleProjectsUsingDartRunIn;

  /// No description provided for @selectAtLeastOnePlatform.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个平台。'**
  String get selectAtLeastOnePlatform;

  /// No description provided for @buildAndroidAndPreviewWebOnThis.
  ///
  /// In zh, this message translates to:
  /// **'本机可构建 Android、预览 Web；其他平台生成代码后需在对应系统构建。'**
  String get buildAndroidAndPreviewWebOnThis;

  /// No description provided for @advancedSettings.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get advancedSettings;

  /// No description provided for @emptyProject.
  ///
  /// In zh, this message translates to:
  /// **'空白项目'**
  String get emptyProject;

  /// No description provided for @excludeTheCounterExample.
  ///
  /// In zh, this message translates to:
  /// **'不包含计数器示例'**
  String get excludeTheCounterExample;

  /// No description provided for @androidSourceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'Android 源码语言'**
  String get androidSourceLanguage;

  /// No description provided for @projectDescriptionOptional.
  ///
  /// In zh, this message translates to:
  /// **'项目描述（可选）'**
  String get projectDescriptionOptional;

  /// No description provided for @projectPreflight.
  ///
  /// In zh, this message translates to:
  /// **'创建前检查'**
  String get projectPreflight;

  /// No description provided for @checkAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新检测'**
  String get checkAgain;

  /// No description provided for @buildApkDebug.
  ///
  /// In zh, this message translates to:
  /// **'构建 APK（调试版）'**
  String get buildApkDebug;

  /// No description provided for @buildApkRelease.
  ///
  /// In zh, this message translates to:
  /// **'构建 APK（发布版）'**
  String get buildApkRelease;

  /// No description provided for @buildWebRelease.
  ///
  /// In zh, this message translates to:
  /// **'构建 Web（发布版）'**
  String get buildWebRelease;

  /// No description provided for @getDependencies.
  ///
  /// In zh, this message translates to:
  /// **'获取依赖'**
  String get getDependencies;

  /// No description provided for @upgradeDependencies.
  ///
  /// In zh, this message translates to:
  /// **'升级依赖'**
  String get upgradeDependencies;

  /// No description provided for @checkOutdatedDependencies.
  ///
  /// In zh, this message translates to:
  /// **'检查过期依赖'**
  String get checkOutdatedDependencies;

  /// No description provided for @cleanBuildOutputs.
  ///
  /// In zh, this message translates to:
  /// **'清理构建产物'**
  String get cleanBuildOutputs;

  /// No description provided for @analyzeCode.
  ///
  /// In zh, this message translates to:
  /// **'静态分析'**
  String get analyzeCode;

  /// No description provided for @runTests.
  ///
  /// In zh, this message translates to:
  /// **'运行测试'**
  String get runTests;

  /// No description provided for @environmentDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'环境诊断'**
  String get environmentDiagnostics;

  /// No description provided for @projectIsClosed.
  ///
  /// In zh, this message translates to:
  /// **'项目已关闭'**
  String get projectIsClosed;

  /// No description provided for @theDevelopmentEnvironmentIsBeingInstalledOr.
  ///
  /// In zh, this message translates to:
  /// **'开发环境正在安装或切换，请等待完成'**
  String get theDevelopmentEnvironmentIsBeingInstalledOr;

  /// No description provided for @aGitOperationIsInProgressPlease.
  ///
  /// In zh, this message translates to:
  /// **'Git 操作正在进行，请等待完成'**
  String get aGitOperationIsInProgressPlease;

  /// No description provided for @saveFailedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试'**
  String get saveFailedPleaseRetry;

  /// No description provided for @aTaskIsAlreadyStartingPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'当前已有任务正在启动，请稍后重试'**
  String get aTaskIsAlreadyStartingPleaseWait;

  /// No description provided for @targetPIsNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'目标 {p0} 未连接'**
  String targetPIsNotConnected(Object? p0);

  /// No description provided for @runDart.
  ///
  /// In zh, this message translates to:
  /// **'Dart 运行'**
  String get runDart;

  /// No description provided for @compileExecutable.
  ///
  /// In zh, this message translates to:
  /// **'编译可执行文件'**
  String get compileExecutable;

  /// No description provided for @waitForTheBuildOrDependencyUpdate.
  ///
  /// In zh, this message translates to:
  /// **'请等待构建或依赖更新完成后再热重载'**
  String get waitForTheBuildOrDependencyUpdate;

  /// No description provided for @filesAreSyncingPleaseRetryShortly.
  ///
  /// In zh, this message translates to:
  /// **'文件正在同步，请稍后重试'**
  String get filesAreSyncingPleaseRetryShortly;

  /// No description provided for @invalidFilePath.
  ///
  /// In zh, this message translates to:
  /// **'文件路径无效'**
  String get invalidFilePath;

  /// No description provided for @fileIsUnreadableOrOutsideTheProject.
  ///
  /// In zh, this message translates to:
  /// **'文件不可读或位于项目目录之外'**
  String get fileIsUnreadableOrOutsideTheProject;

  /// No description provided for @aFileIsAlreadyOpenAtThe.
  ///
  /// In zh, this message translates to:
  /// **'目标路径已有打开的文件'**
  String get aFileIsAlreadyOpenAtThe;

  /// No description provided for @saveFailedFileOperationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，已取消文件操作'**
  String get saveFailedFileOperationCancelled;

  /// No description provided for @fileDoesNotExistP.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在： {p0}'**
  String fileDoesNotExistP(Object? p0);

  /// No description provided for @unableToReloadPTheFileWas.
  ///
  /// In zh, this message translates to:
  /// **'无法重新读取 {p0}，已关闭此文件，请从“项目”工具窗口重新打开'**
  String unableToReloadPTheFileWas(Object? p0);

  /// No description provided for @unableToReadProjectDirectoryP.
  ///
  /// In zh, this message translates to:
  /// **'无法读取项目目录：{p0}'**
  String unableToReadProjectDirectoryP(Object? p0);

  /// No description provided for @fileIsOutsideTheCurrentProject.
  ///
  /// In zh, this message translates to:
  /// **'文件不在当前项目内'**
  String get fileIsOutsideTheCurrentProject;

  /// No description provided for @noFilesToPaste.
  ///
  /// In zh, this message translates to:
  /// **'没有可粘贴的文件'**
  String get noFilesToPaste;

  /// No description provided for @filesCanOnlyBeMovedWithinThe.
  ///
  /// In zh, this message translates to:
  /// **'只能在当前项目内移动文件，请使用复制'**
  String get filesCanOnlyBeMovedWithinThe;

  /// No description provided for @aGitOperationIsRunningWaitOr.
  ///
  /// In zh, this message translates to:
  /// **'Git 操作正在进行，请等待完成或在终端停止'**
  String get aGitOperationIsRunningWaitOr;

  /// No description provided for @aFileOperationIsRunningWaitBefore.
  ///
  /// In zh, this message translates to:
  /// **'文件操作正在进行，请等待完成后再切换项目'**
  String get aFileOperationIsRunningWaitBefore;

  /// No description provided for @failedToSaveTheCurrentProjectRetry.
  ///
  /// In zh, this message translates to:
  /// **'当前项目保存失败，请重试后再切换项目'**
  String get failedToSaveTheCurrentProjectRetry;

  /// No description provided for @fontSizeAppliedButSavingFailedP.
  ///
  /// In zh, this message translates to:
  /// **'字号已应用，但保存失败：{p0}'**
  String fontSizeAppliedButSavingFailedP(Object? p0);

  /// No description provided for @terminalAppearance.
  ///
  /// In zh, this message translates to:
  /// **'终端外观'**
  String get terminalAppearance;

  /// No description provided for @closeTerminalSettings.
  ///
  /// In zh, this message translates to:
  /// **'关闭终端设置'**
  String get closeTerminalSettings;

  /// No description provided for @collapseTerminal.
  ///
  /// In zh, this message translates to:
  /// **'收起终端'**
  String get collapseTerminal;

  /// No description provided for @expandTerminal.
  ///
  /// In zh, this message translates to:
  /// **'展开终端'**
  String get expandTerminal;

  /// No description provided for @stopping.
  ///
  /// In zh, this message translates to:
  /// **'正在停止…'**
  String get stopping;

  /// No description provided for @stopCurrentTask.
  ///
  /// In zh, this message translates to:
  /// **'停止当前任务'**
  String get stopCurrentTask;

  /// No description provided for @terminateAndClose.
  ///
  /// In zh, this message translates to:
  /// **'终止并关闭'**
  String get terminateAndClose;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @terminalFontAndZoom.
  ///
  /// In zh, this message translates to:
  /// **'终端字体与缩放'**
  String get terminalFontAndZoom;

  /// No description provided for @clearTerminal.
  ///
  /// In zh, this message translates to:
  /// **'清空终端'**
  String get clearTerminal;

  /// No description provided for @exitFullScreen.
  ///
  /// In zh, this message translates to:
  /// **'退出全屏终端'**
  String get exitFullScreen;

  /// No description provided for @fullScreenTerminal.
  ///
  /// In zh, this message translates to:
  /// **'全屏终端'**
  String get fullScreenTerminal;

  /// No description provided for @paste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴'**
  String get paste;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @closePSession.
  ///
  /// In zh, this message translates to:
  /// **'关闭 {p0} 会话'**
  String closePSession(Object? p0);

  /// No description provided for @developmentEnvironmentIsNotReadyCompleteSetup.
  ///
  /// In zh, this message translates to:
  /// **'开发环境未就绪，请先初始化环境'**
  String get developmentEnvironmentIsNotReadyCompleteSetup;

  /// No description provided for @aTaskCannotBeTheDefaultShell.
  ///
  /// In zh, this message translates to:
  /// **'任务不会是默认 shell'**
  String get aTaskCannotBeTheDefaultShell;

  /// No description provided for @pRequiresExclusiveProjectAccessStopIt.
  ///
  /// In zh, this message translates to:
  /// **'“{p0}”与该操作需要独占项目，请结束后重试'**
  String pRequiresExclusiveProjectAccessStopIt(Object? p0);

  /// No description provided for @pIsUpdatingDependenciesOrBuildFiles.
  ///
  /// In zh, this message translates to:
  /// **'“{p0}”正在更新依赖或构建文件，请等待完成'**
  String pIsUpdatingDependenciesOrBuildFiles(Object? p0);

  /// No description provided for @sessionIsClosed.
  ///
  /// In zh, this message translates to:
  /// **'会话已关闭'**
  String get sessionIsClosed;

  /// No description provided for @theCurrentTaskHasNotFinished.
  ///
  /// In zh, this message translates to:
  /// **'当前任务尚未结束'**
  String get theCurrentTaskHasNotFinished;

  /// No description provided for @failedToReadOutputP.
  ///
  /// In zh, this message translates to:
  /// **'读取输出失败： {p0}'**
  String failedToReadOutputP(Object? p0);

  /// No description provided for @failedToStartP.
  ///
  /// In zh, this message translates to:
  /// **'启动失败： {p0}'**
  String failedToStartP(Object? p0);

  /// No description provided for @stopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get stopped;

  /// No description provided for @processExitedWithCode.
  ///
  /// In zh, this message translates to:
  /// **'进程结束，退出码 0'**
  String get processExitedWithCode;

  /// No description provided for @processExitedWithCodeP.
  ///
  /// In zh, this message translates to:
  /// **'进程结束，退出码 {p0}'**
  String processExitedWithCodeP(Object? p0);

  /// No description provided for @executionTimedOutStopping.
  ///
  /// In zh, this message translates to:
  /// **'执行超时，正在停止'**
  String get executionTimedOutStopping;

  /// No description provided for @sharedByAllTerminalsAndSavedAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'所有终端共用设置，自动保存。也可在终端内容区双指缩放。'**
  String get sharedByAllTerminalsAndSavedAutomatically;

  /// No description provided for @settingsAppliedButSavingFailedP.
  ///
  /// In zh, this message translates to:
  /// **'设置已应用，但保存失败：{p0}'**
  String settingsAppliedButSavingFailedP(Object? p0);

  /// No description provided for @terminalFontSize.
  ///
  /// In zh, this message translates to:
  /// **'终端字号'**
  String get terminalFontSize;

  /// No description provided for @decreaseTerminalFontSize.
  ///
  /// In zh, this message translates to:
  /// **'缩小终端字号'**
  String get decreaseTerminalFontSize;

  /// No description provided for @increaseTerminalFontSize.
  ///
  /// In zh, this message translates to:
  /// **'放大终端字号'**
  String get increaseTerminalFontSize;

  /// No description provided for @monospaceFont.
  ///
  /// In zh, this message translates to:
  /// **'等宽字体'**
  String get monospaceFont;

  /// No description provided for @lineHeight.
  ///
  /// In zh, this message translates to:
  /// **'行高'**
  String get lineHeight;

  /// No description provided for @p.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 倍'**
  String p(Object? p0);

  /// No description provided for @flitFlutterBuildApkBuildComplete.
  ///
  /// In zh, this message translates to:
  /// **'flit ~ \$ flutter build apk\n✓ 构建完成  Build complete\n0123456789  []\'{\'\'}\' <> !='**
  String get flitFlutterBuildApkBuildComplete;

  /// No description provided for @resetTerminalAppearance.
  ///
  /// In zh, this message translates to:
  /// **'恢复终端默认外观'**
  String get resetTerminalAppearance;

  /// No description provided for @thisAssetHasNoShaDigest.
  ///
  /// In zh, this message translates to:
  /// **'该产物缺少 SHA-256'**
  String get thisAssetHasNoShaDigest;

  /// No description provided for @unsupportedComponentP.
  ///
  /// In zh, this message translates to:
  /// **'不支持的组件：{p0}'**
  String unsupportedComponentP(Object? p0);

  /// No description provided for @aToolchainIsBeingInstalledPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'工具链正在安装，请稍后重试'**
  String get aToolchainIsBeingInstalledPleaseWait;

  /// No description provided for @projectClosedOrTaskCancelled.
  ///
  /// In zh, this message translates to:
  /// **'项目已关闭或任务已取消'**
  String get projectClosedOrTaskCancelled;

  /// No description provided for @requiredComponentsAreMissingBuildNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'组件未补齐，构建未启动'**
  String get requiredComponentsAreMissingBuildNotStarted;

  /// No description provided for @componentRepairIncompleteP.
  ///
  /// In zh, this message translates to:
  /// **'组件修复未完成：{p0}'**
  String componentRepairIncompleteP(Object? p0);

  /// No description provided for @androidEnvironmentCheckFailedCompleteSetupIn.
  ///
  /// In zh, this message translates to:
  /// **'Android 环境检查失败，请先在开发环境页完成初始化。\n{p0}'**
  String androidEnvironmentCheckFailedCompleteSetupIn(Object? p0);

  /// No description provided for @installingComponentsChangesTheSharedDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'安装组件需要修改共用开发环境。请先结束正在运行的任务，再重试。'**
  String get installingComponentsChangesTheSharedDevelopmentEnvironment;

  /// No description provided for @matchingVersionOrDownloadInformationUnavailableP.
  ///
  /// In zh, this message translates to:
  /// **'未找到可安装的对应版本或无法获取下载信息：{p0}'**
  String matchingVersionOrDownloadInformationUnavailableP(Object? p0);

  /// No description provided for @aTaskIsRunningStopItAnd.
  ///
  /// In zh, this message translates to:
  /// **'已有任务正在运行，请结束后重试'**
  String get aTaskIsRunningStopItAnd;

  /// No description provided for @installAndroidBuildComponents.
  ///
  /// In zh, this message translates to:
  /// **'安装 Android 构建组件'**
  String get installAndroidBuildComponents;

  /// No description provided for @stillUnavailableAfterInstallationP.
  ///
  /// In zh, this message translates to:
  /// **'安装后仍不可用：{p0}'**
  String stillUnavailableAfterInstallationP(Object? p0);

  /// No description provided for @automaticInstallationIsNotSupportedForP.
  ///
  /// In zh, this message translates to:
  /// **'不支持自动安装 {p0}'**
  String automaticInstallationIsNotSupportedForP(Object? p0);

  /// No description provided for @invalidNdkVersion.
  ///
  /// In zh, this message translates to:
  /// **'无效的 NDK 版本'**
  String get invalidNdkVersion;

  /// No description provided for @unableToLocateNdkP.
  ///
  /// In zh, this message translates to:
  /// **'无法定位 NDK {p0}'**
  String unableToLocateNdkP(Object? p0);

  /// No description provided for @androidSdkLicensesHaveNotBeenAccepted.
  ///
  /// In zh, this message translates to:
  /// **'Android SDK 许可证尚未接受。请在开发环境终端运行 \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses，接受所需许可证后重试。'**
  String get androidSdkLicensesHaveNotBeenAccepted;

  /// No description provided for @theSdkNdkCmakePathInThe.
  ///
  /// In zh, this message translates to:
  /// **'项目配置的 SDK/NDK/CMake 路径无效。请检查 local.properties 或 Gradle 中的路径；安装到默认目录不会修复自定义路径。'**
  String get theSdkNdkCmakePathInThe;

  /// No description provided for @unknownComponentP.
  ///
  /// In zh, this message translates to:
  /// **'未知组件：{p0}'**
  String unknownComponentP(Object? p0);

  /// No description provided for @noValidPReleaseConfiguredP.
  ///
  /// In zh, this message translates to:
  /// **'未配置有效的 {p0} 发行版本：{p1}'**
  String noValidPReleaseConfiguredP(Object? p0, Object? p1);

  /// No description provided for @releaseUnavailableP.
  ///
  /// In zh, this message translates to:
  /// **'发行版本不可用：{p0}'**
  String releaseUnavailableP(Object? p0);

  /// No description provided for @noUniquePFoundInP.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 中未找到唯一的 {p1}'**
  String noUniquePFoundInP(Object? p0, Object? p1);

  /// No description provided for @pPIsMissingAValidDownload.
  ///
  /// In zh, this message translates to:
  /// **'{p0} / {p1} 缺少有效的下载地址或 SHA-256'**
  String pPIsMissingAValidDownload(Object? p0, Object? p1);

  /// No description provided for @invalidGithubReleasesResponse.
  ///
  /// In zh, this message translates to:
  /// **'GitHub Releases 响应无效'**
  String get invalidGithubReleasesResponse;

  /// No description provided for @baseEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'基础环境'**
  String get baseEnvironment;

  /// No description provided for @bashPackageManager.
  ///
  /// In zh, this message translates to:
  /// **'Bash · 软件包管理器'**
  String get bashPackageManager;

  /// No description provided for @androidToolchain.
  ///
  /// In zh, this message translates to:
  /// **'Android 工具链'**
  String get androidToolchain;

  /// No description provided for @openjdkAndroidSdkNdkCmakeGradleConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'OpenJDK 17 · Android SDK · NDK · CMake · Gradle 配置'**
  String get openjdkAndroidSdkNdkCmakeGradleConfiguration;

  /// No description provided for @flutterToolchain.
  ///
  /// In zh, this message translates to:
  /// **'Flutter 工具链'**
  String get flutterToolchain;

  /// No description provided for @flutterSdkGitAndGhWarmUp.
  ///
  /// In zh, this message translates to:
  /// **'Flutter SDK · Git 与 gh · 预热'**
  String get flutterSdkGitAndGhWarmUp;

  /// No description provided for @gradleConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'Gradle 配置'**
  String get gradleConfiguration;

  /// No description provided for @gitAndGh.
  ///
  /// In zh, this message translates to:
  /// **'Git 与 gh'**
  String get gitAndGh;

  /// No description provided for @warmUp.
  ///
  /// In zh, this message translates to:
  /// **'预热'**
  String get warmUp;

  /// No description provided for @projectTasksAreUsingTheDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'项目任务正在使用开发环境，请先结束任务再安装、切换或删除组件'**
  String get projectTasksAreUsingTheDevelopmentEnvironment;

  /// No description provided for @aTaskIsRunningWaitBeforeInstalling.
  ///
  /// In zh, this message translates to:
  /// **'当前有任务进行中，请等待完成后再安装版本'**
  String get aTaskIsRunningWaitBeforeInstalling;

  /// No description provided for @installTheBaseEnvironmentBeforeAddingOther.
  ///
  /// In zh, this message translates to:
  /// **'请先安装基础环境，再安装其他版本'**
  String get installTheBaseEnvironmentBeforeAddingOther;

  /// No description provided for @installP.
  ///
  /// In zh, this message translates to:
  /// **'安装 {p0}'**
  String installP(Object? p0);

  /// No description provided for @fetchingDownloadInformationForP.
  ///
  /// In zh, this message translates to:
  /// **'正在获取 {p0} 的下载信息…'**
  String fetchingDownloadInformationForP(Object? p0);

  /// No description provided for @pInstalled.
  ///
  /// In zh, this message translates to:
  /// **'✓ {p0} 安装完成'**
  String pInstalled(Object? p0);

  /// No description provided for @installationFailedExitCodePSeeOutput.
  ///
  /// In zh, this message translates to:
  /// **'安装失败，退出码 {p0}（详细输出见上）'**
  String installationFailedExitCodePSeeOutput(Object? p0);

  /// No description provided for @installationFailedP.
  ///
  /// In zh, this message translates to:
  /// **'安装失败：{p0}'**
  String installationFailedP(Object? p0);

  /// No description provided for @operationFailedExitCodePSeeOutput.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，退出码 {p0}（详细输出见上）'**
  String operationFailedExitCodePSeeOutput(Object? p0);

  /// No description provided for @installTheBaseEnvironmentBeforeCheckingThe.
  ///
  /// In zh, this message translates to:
  /// **'请先安装基础环境，再执行网络检测'**
  String get installTheBaseEnvironmentBeforeCheckingThe;

  /// No description provided for @networkCheck.
  ///
  /// In zh, this message translates to:
  /// **'网络检测'**
  String get networkCheck;

  /// No description provided for @environmentCheckFailedP.
  ///
  /// In zh, this message translates to:
  /// **'环境检测失败：{p0}'**
  String environmentCheckFailedP(Object? p0);

  /// No description provided for @environmentCheck.
  ///
  /// In zh, this message translates to:
  /// **'环境检测'**
  String get environmentCheck;

  /// No description provided for @environmentCheckIncompleteExitCodeP.
  ///
  /// In zh, this message translates to:
  /// **'环境检查未完成，退出码 {p0}'**
  String environmentCheckIncompleteExitCodeP(Object? p0);

  /// No description provided for @componentsAreNotReadyCheckAgain.
  ///
  /// In zh, this message translates to:
  /// **'组件检测尚未就绪，请重新检测'**
  String get componentsAreNotReadyCheckAgain;

  /// No description provided for @componentDirectoryCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'组件目录检测失败'**
  String get componentDirectoryCheckFailed;

  /// No description provided for @unableToReadInstalledComponentsCheckAgain.
  ///
  /// In zh, this message translates to:
  /// **'无法读取已安装组件，请重新检测：{p0}'**
  String unableToReadInstalledComponentsCheckAgain(Object? p0);

  /// No description provided for @environmentSetup.
  ///
  /// In zh, this message translates to:
  /// **'安装环境'**
  String get environmentSetup;

  /// No description provided for @baseEnvironmentInstallationFailedP.
  ///
  /// In zh, this message translates to:
  /// **'✗ 基础环境安装失败：{p0}'**
  String baseEnvironmentInstallationFailedP(Object? p0);

  /// No description provided for @pInstallationFailedRemainingStepsSkipped.
  ///
  /// In zh, this message translates to:
  /// **'✗ {p0} 安装失败，已跳过后续步骤'**
  String pInstallationFailedRemainingStepsSkipped(Object? p0);

  /// No description provided for @pComplete.
  ///
  /// In zh, this message translates to:
  /// **'✓ {p0} 完成'**
  String pComplete(Object? p0);

  /// No description provided for @installationCompleteDevelopmentEnvironmentReady.
  ///
  /// In zh, this message translates to:
  /// **'✓ 安装完成，开发环境已就绪'**
  String get installationCompleteDevelopmentEnvironmentReady;

  /// No description provided for @environmentVerificationFailedCheckMissingOrFailed.
  ///
  /// In zh, this message translates to:
  /// **'环境复查未通过，请查看缺失或失败的组件'**
  String get environmentVerificationFailedCheckMissingOrFailed;

  /// No description provided for @stoppedYouCanResumeInstallationLater.
  ///
  /// In zh, this message translates to:
  /// **'已停止，可随时继续安装'**
  String get stoppedYouCanResumeInstallationLater;

  /// No description provided for @preparingP.
  ///
  /// In zh, this message translates to:
  /// **'准备 {p0}…'**
  String preparingP(Object? p0);

  /// No description provided for @failedToFetchInstallationInformationP.
  ///
  /// In zh, this message translates to:
  /// **'获取安装信息失败：{p0}'**
  String failedToFetchInstallationInformationP(Object? p0);

  /// No description provided for @keepMultipleVersionsAndChooseTheActive.
  ///
  /// In zh, this message translates to:
  /// **'可安装多个版本，选择当前使用的版本。安装新版本后会自动切换。'**
  String get keepMultipleVersionsAndChooseTheActive;

  /// No description provided for @matchesTheProjectCompilesdkMultipleApiVersions.
  ///
  /// In zh, this message translates to:
  /// **'对应项目的 compileSdk，可同时保留多个 API 版本。'**
  String get matchesTheProjectCompilesdkMultipleApiVersions;

  /// No description provided for @androidPackagingToolsInstallAndKeepVersions.
  ///
  /// In zh, this message translates to:
  /// **'Android 打包工具，按项目需要安装并保留多个版本。'**
  String get androidPackagingToolsInstallAndKeepVersions;

  /// No description provided for @nativeCompilerToolsTheProjectSelectsThe.
  ///
  /// In zh, this message translates to:
  /// **'原生代码编译工具，由项目指定版本，可同时安装多个版本。'**
  String get nativeCompilerToolsTheProjectSelectsThe;

  /// No description provided for @nativeBuildToolsTheProjectSelectsThe.
  ///
  /// In zh, this message translates to:
  /// **'原生构建工具，由项目指定版本，可同时安装多个版本。'**
  String get nativeBuildToolsTheProjectSelectsThe;

  /// No description provided for @adbAndOtherSharedDeviceToolsInstalling.
  ///
  /// In zh, this message translates to:
  /// **'ADB 等设备工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。'**
  String get adbAndOtherSharedDeviceToolsInstalling;

  /// No description provided for @sdkmanagerAndOtherSharedSdkManagementTools.
  ///
  /// In zh, this message translates to:
  /// **'sdkmanager 等 SDK 管理工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。'**
  String get sdkmanagerAndOtherSharedSdkManagementTools;

  /// No description provided for @companionToolsP.
  ///
  /// In zh, this message translates to:
  /// **'配套工具包 · {p0}'**
  String companionToolsP(Object? p0);

  /// No description provided for @unknownVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本未知'**
  String get unknownVersion;

  /// No description provided for @closeTheProjectBeforeChangingSdksOr.
  ///
  /// In zh, this message translates to:
  /// **'请先关闭项目，再更改 SDK 或工具链'**
  String get closeTheProjectBeforeChangingSdksOr;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @proxySettings.
  ///
  /// In zh, this message translates to:
  /// **'代理设置'**
  String get proxySettings;

  /// No description provided for @sdksAndToolchains.
  ///
  /// In zh, this message translates to:
  /// **'SDK 与工具链'**
  String get sdksAndToolchains;

  /// No description provided for @manageSdksAndBuildToolsViewInstallation.
  ///
  /// In zh, this message translates to:
  /// **'管理 SDK 和构建工具链，在终端查看安装输出。'**
  String get manageSdksAndBuildToolsViewInstallation;

  /// No description provided for @setupDetails.
  ///
  /// In zh, this message translates to:
  /// **'初始化详情'**
  String get setupDetails;

  /// No description provided for @checkingEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'正在检测环境'**
  String get checkingEnvironment;

  /// No description provided for @managingToolchains.
  ///
  /// In zh, this message translates to:
  /// **'正在管理工具链'**
  String get managingToolchains;

  /// No description provided for @environmentReady.
  ///
  /// In zh, this message translates to:
  /// **'环境已就绪'**
  String get environmentReady;

  /// No description provided for @installingComponents.
  ///
  /// In zh, this message translates to:
  /// **'正在安装组件'**
  String get installingComponents;

  /// No description provided for @installationFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败'**
  String get installationFailed;

  /// No description provided for @environmentNotReady.
  ///
  /// In zh, this message translates to:
  /// **'环境未就绪'**
  String get environmentNotReady;

  /// No description provided for @checkingLocalComponentsPleaseWait.
  ///
  /// In zh, this message translates to:
  /// **'正在核对本地组件，请稍候'**
  String get checkingLocalComponentsPleaseWait;

  /// No description provided for @seeTerminalForDetails.
  ///
  /// In zh, this message translates to:
  /// **'详细输出见终端'**
  String get seeTerminalForDetails;

  /// No description provided for @componentsReadyYouCanCreateProjectsAnd.
  ///
  /// In zh, this message translates to:
  /// **'组件已就绪，可以创建项目和构建 APK'**
  String get componentsReadyYouCanCreateProjectsAnd;

  /// No description provided for @pPReady.
  ///
  /// In zh, this message translates to:
  /// **'已就绪 {p0}/{p1} 项'**
  String pPReady(Object? p0, Object? p1);

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @resumeInstallation.
  ///
  /// In zh, this message translates to:
  /// **'继续安装'**
  String get resumeInstallation;

  /// No description provided for @startInstallation.
  ///
  /// In zh, this message translates to:
  /// **'开始安装'**
  String get startInstallation;

  /// No description provided for @networkP.
  ///
  /// In zh, this message translates to:
  /// **'网络：{p0}'**
  String networkP(Object? p0);

  /// No description provided for @baseEnvironmentDownloadConfigurationIsIncompleteUpdate.
  ///
  /// In zh, this message translates to:
  /// **'基础环境的下载配置不完整，请更新应用后重试'**
  String get baseEnvironmentDownloadConfigurationIsIncompleteUpdate;

  /// No description provided for @downloadingBaseEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'正在下载基础环境…'**
  String get downloadingBaseEnvironment;

  /// No description provided for @downloadUrlP.
  ///
  /// In zh, this message translates to:
  /// **'下载地址：{p0}'**
  String downloadUrlP(Object? p0);

  /// No description provided for @downloadFailedHttpPCheckTheUrl.
  ///
  /// In zh, this message translates to:
  /// **'下载失败：HTTP {p0}，请检查下载地址和网络后重试'**
  String downloadFailedHttpPCheckTheUrl(Object? p0);

  /// No description provided for @downloadedPPMb.
  ///
  /// In zh, this message translates to:
  /// **'下载 {p0}%（{p1} MB）'**
  String downloadedPPMb(Object? p0, Object? p1);

  /// No description provided for @downloadCompletePMb.
  ///
  /// In zh, this message translates to:
  /// **'下载完成（{p0} MB）'**
  String downloadCompletePMb(Object? p0);

  /// No description provided for @verifyingShaP.
  ///
  /// In zh, this message translates to:
  /// **'正在校验 SHA-256：{p0}'**
  String verifyingShaP(Object? p0);

  /// No description provided for @baseEnvironmentChecksumMismatchExpectedPActual.
  ///
  /// In zh, this message translates to:
  /// **'基础环境安装包校验失败：\n期望：{p0}\n实际：{p1}'**
  String baseEnvironmentChecksumMismatchExpectedPActual(Object? p0, Object? p1);

  /// No description provided for @shaVerified.
  ///
  /// In zh, this message translates to:
  /// **'SHA-256 校验通过'**
  String get shaVerified;

  /// No description provided for @installingBaseEnvironmentExtractingAndConfiguring.
  ///
  /// In zh, this message translates to:
  /// **'正在安装基础环境（解压与配置）…'**
  String get installingBaseEnvironmentExtractingAndConfiguring;

  /// No description provided for @nativeInstallerDidNotConfirmASuccessful.
  ///
  /// In zh, this message translates to:
  /// **'原生安装器未确认基础环境安装成功'**
  String get nativeInstallerDidNotConfirmASuccessful;

  /// No description provided for @baseEnvironmentReady.
  ///
  /// In zh, this message translates to:
  /// **'基础环境已就绪'**
  String get baseEnvironmentReady;

  /// No description provided for @checkFailedOpenDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'检测失败 · 进入开发环境查看'**
  String get checkFailedOpenDevelopmentEnvironment;

  /// No description provided for @notInstalledSetUpDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'尚未安装 · 配置开发环境'**
  String get notInstalledSetUpDevelopmentEnvironment;

  /// No description provided for @allComponentsReady.
  ///
  /// In zh, this message translates to:
  /// **'组件全部就绪'**
  String get allComponentsReady;

  /// No description provided for @pPComponentsReady.
  ///
  /// In zh, this message translates to:
  /// **'已就绪 {p0}/{p1} 个组件'**
  String pPComponentsReady(Object? p0, Object? p1);

  /// No description provided for @manageVersions.
  ///
  /// In zh, this message translates to:
  /// **'管理版本'**
  String get manageVersions;

  /// No description provided for @deleteP.
  ///
  /// In zh, this message translates to:
  /// **'删除 {p0}？'**
  String deleteP(Object? p0);

  /// No description provided for @projectsUsingThisVersionWillNeedIt.
  ///
  /// In zh, this message translates to:
  /// **'依赖此版本的项目需重新安装后才能构建；删除基础必需版本后，需要补齐开发环境。'**
  String get projectsUsingThisVersionWillNeedIt;

  /// No description provided for @repairInstallation.
  ///
  /// In zh, this message translates to:
  /// **'修复安装'**
  String get repairInstallation;

  /// No description provided for @useThisVersion.
  ///
  /// In zh, this message translates to:
  /// **'使用此版本'**
  String get useThisVersion;

  /// No description provided for @switchVersionsBeforeDeleting.
  ///
  /// In zh, this message translates to:
  /// **'先切换版本再删除'**
  String get switchVersionsBeforeDeleting;

  /// No description provided for @deleteVersion.
  ///
  /// In zh, this message translates to:
  /// **'删除版本'**
  String get deleteVersion;

  /// No description provided for @replaceP.
  ///
  /// In zh, this message translates to:
  /// **'替换 {p0}？'**
  String replaceP(Object? p0);

  /// No description provided for @installTheCompanionToolsFromPReplacing.
  ///
  /// In zh, this message translates to:
  /// **'将安装 {p0} 提供的配套工具包，替换当前共用工具。'**
  String installTheCompanionToolsFromPReplacing(Object? p0);

  /// No description provided for @replace.
  ///
  /// In zh, this message translates to:
  /// **'替换'**
  String get replace;

  /// No description provided for @refreshAvailableVersions.
  ///
  /// In zh, this message translates to:
  /// **'刷新可下载版本'**
  String get refreshAvailableVersions;

  /// No description provided for @localVersions.
  ///
  /// In zh, this message translates to:
  /// **'本地版本'**
  String get localVersions;

  /// No description provided for @checkingLocalComponents.
  ///
  /// In zh, this message translates to:
  /// **'正在检测本地组件…'**
  String get checkingLocalComponents;

  /// No description provided for @installationStatusUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'安装状态待确认'**
  String get installationStatusUnconfirmed;

  /// No description provided for @notInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get notInstalled;

  /// No description provided for @companionTools.
  ///
  /// In zh, this message translates to:
  /// **'配套工具包'**
  String get companionTools;

  /// No description provided for @availableVersions.
  ///
  /// In zh, this message translates to:
  /// **'可下载版本'**
  String get availableVersions;

  /// No description provided for @failedToFetchVersionsPP.
  ///
  /// In zh, this message translates to:
  /// **'获取版本失败，{p0}。\n{p1}'**
  String failedToFetchVersionsPP(Object? p0, Object? p1);

  /// No description provided for @noDownloadableCompanionVersionsInTheRepository.
  ///
  /// In zh, this message translates to:
  /// **'仓库暂无可下载的配套版本。'**
  String get noDownloadableCompanionVersionsInTheRepository;

  /// No description provided for @allCatalogVersionsAreInstalledUseThe.
  ///
  /// In zh, this message translates to:
  /// **'目录中的版本已在本地，需修复的版本可通过管理菜单重新安装。'**
  String get allCatalogVersionsAreInstalledUseThe;

  /// No description provided for @installingTheSameNdkVersionKeepsThe.
  ///
  /// In zh, this message translates to:
  /// **'安装相同 NDK 版本会保留现有可用版本。'**
  String get installingTheSameNdkVersionKeepsThe;

  /// No description provided for @componentManager.
  ///
  /// In zh, this message translates to:
  /// **'组件管理'**
  String get componentManager;

  /// No description provided for @manageInstalledVersionsDownloadsAndRepairsBy.
  ///
  /// In zh, this message translates to:
  /// **'按组件管理本地版本、下载与修复。SDK 整包仅用于初始化。'**
  String get manageInstalledVersionsDownloadsAndRepairsBy;

  /// No description provided for @setUpTheBaseEnvironmentFirstThen.
  ///
  /// In zh, this message translates to:
  /// **'先完成基础环境初始化，再按项目需要管理组件。'**
  String get setUpTheBaseEnvironmentFirstThen;

  /// No description provided for @pVersionsPP.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个版本{p1}{p2}'**
  String pVersionsPP(Object? p0, Object? p1, Object? p2);

  /// No description provided for @availableAfterSetup.
  ///
  /// In zh, this message translates to:
  /// **'初始化后可管理'**
  String get availableAfterSetup;

  /// No description provided for @checking372.
  ///
  /// In zh, this message translates to:
  /// **'正在检测…'**
  String get checking372;

  /// No description provided for @installing.
  ///
  /// In zh, this message translates to:
  /// **'安装中'**
  String get installing;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// No description provided for @waitingForDependencies.
  ///
  /// In zh, this message translates to:
  /// **'等待依赖'**
  String get waitingForDependencies;

  /// No description provided for @pendingInstallation.
  ///
  /// In zh, this message translates to:
  /// **'待安装'**
  String get pendingInstallation;

  /// No description provided for @pInstalling.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 安装中'**
  String pInstalling(Object? p0);

  /// No description provided for @pFailed.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 失败'**
  String pFailed(Object? p0);

  /// No description provided for @pWaitingForPreviousSteps.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 等待前序步骤'**
  String pWaitingForPreviousSteps(Object? p0);

  /// No description provided for @pPendingInstallation.
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 待安装'**
  String pPendingInstallation(Object? p0);

  /// No description provided for @deviceConnection.
  ///
  /// In zh, this message translates to:
  /// **'设备连接'**
  String get deviceConnection;

  /// No description provided for @enterAnIpAddressOrHostnameWithout.
  ///
  /// In zh, this message translates to:
  /// **'请输入 IP 地址或主机名，不包含协议和端口'**
  String get enterAnIpAddressOrHostnameWithout;

  /// No description provided for @portMustBeBetweenAnd.
  ///
  /// In zh, this message translates to:
  /// **'端口必须在 1–65535 之间'**
  String get portMustBeBetweenAnd;

  /// No description provided for @unableToReadDevicesSeeTerminalOutput.
  ///
  /// In zh, this message translates to:
  /// **'读取设备失败，请查看终端输出'**
  String get unableToReadDevicesSeeTerminalOutput;

  /// No description provided for @adbFailedToStartCheckTheDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'ADB 启动失败，请检查开发环境'**
  String get adbFailedToStartCheckTheDevelopment;

  /// No description provided for @operationFailedPSeeTerminalForDetails.
  ///
  /// In zh, this message translates to:
  /// **'操作失败：{p0}。详细原因见终端。'**
  String operationFailedPSeeTerminalForDetails(Object? p0);

  /// No description provided for @enterADigitPairingCode.
  ///
  /// In zh, this message translates to:
  /// **'请填写 6 位配对码'**
  String get enterADigitPairingCode;

  /// No description provided for @pairingFailedKeepTheSystemPairingDialog.
  ///
  /// In zh, this message translates to:
  /// **'配对失败：请保持系统配对码弹窗开启，核对配对端口与配对码后重试。详细原因见终端。'**
  String get pairingFailedKeepTheSystemPairingDialog;

  /// No description provided for @pairedSuccessfully.
  ///
  /// In zh, this message translates to:
  /// **'配对成功'**
  String get pairedSuccessfully;

  /// No description provided for @unableToConfirmDeviceIsOnlineRefresh.
  ///
  /// In zh, this message translates to:
  /// **'连接后未能确认设备在线，请刷新设备或查看日志'**
  String get unableToConfirmDeviceIsOnlineRefresh;

  /// No description provided for @connectedToLocalWirelessDebugging.
  ///
  /// In zh, this message translates to:
  /// **'✓ 已自动连接本机无线调试'**
  String get connectedToLocalWirelessDebugging;

  /// No description provided for @allowUsbDebuggingOnThePhoneThen.
  ///
  /// In zh, this message translates to:
  /// **'请在手机上允许 USB 调试授权后重试'**
  String get allowUsbDebuggingOnThePhoneThen;

  /// No description provided for @pairingRequiredTapNotificationPairing.
  ///
  /// In zh, this message translates to:
  /// **'需要配对，请点击“通知配对”'**
  String get pairingRequiredTapNotificationPairing;

  /// No description provided for @connectionFailedCheckLogsOrConnectManually.
  ///
  /// In zh, this message translates to:
  /// **'连接未成功，请查看日志或使用当前端口手动连接'**
  String get connectionFailedCheckLogsOrConnectManually;

  /// No description provided for @noWirelessPortFoundScanAgainEnter.
  ///
  /// In zh, this message translates to:
  /// **'未发现无线端口，可重新扫描、手动输入，或通过电脑 USB 激活'**
  String get noWirelessPortFoundScanAgainEnter;

  /// No description provided for @connectedLocallyUsbActivatedYouCanUnplug.
  ///
  /// In zh, this message translates to:
  /// **'✓ 已连接本机 · 电脑 USB 激活，可拔掉数据线'**
  String get connectedLocallyUsbActivatedYouCanUnplug;

  /// No description provided for @unableToConfirmConnectionInstallAdbFirst.
  ///
  /// In zh, this message translates to:
  /// **'无法确认连接状态，请先安装 ADB'**
  String get unableToConfirmConnectionInstallAdbFirst;

  /// No description provided for @unableToConfirmConnectionFailedToRead.
  ///
  /// In zh, this message translates to:
  /// **'✗ 无法确认连接状态：读取设备失败，请查看终端输出'**
  String get unableToConfirmConnectionFailedToRead;

  /// No description provided for @connectedToP.
  ///
  /// In zh, this message translates to:
  /// **'✓ 已连接 {p0}'**
  String connectedToP(Object? p0);

  /// No description provided for @deviceUnauthorizedAllowUsbDebuggingOnThe.
  ///
  /// In zh, this message translates to:
  /// **'设备未授权：请在手机上允许 USB 调试授权，再点连接'**
  String get deviceUnauthorizedAllowUsbDebuggingOnThe;

  /// No description provided for @localAdbIsOfflineRunTheActivation.
  ///
  /// In zh, this message translates to:
  /// **'本机 ADB 离线，请在电脑重新执行激活命令后重试'**
  String get localAdbIsOfflineRunTheActivation;

  /// No description provided for @adbAuthenticationFailedConfirmUsbDebuggingAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'ADB 认证失败：请在手机上确认 USB 调试授权，再点连接'**
  String get adbAuthenticationFailedConfirmUsbDebuggingAuthorization;

  /// No description provided for @notActivatedConnectViaUsbAndRun.
  ///
  /// In zh, this message translates to:
  /// **'尚未激活：请用 USB 连接电脑，执行激活命令后重试；手机重启后需重新激活'**
  String get notActivatedConnectViaUsbAndRun;

  /// No description provided for @unableToConnectToLocalPortCheck.
  ///
  /// In zh, this message translates to:
  /// **'未能连接本机 5555 端口，请检查电脑激活结果和手机授权；部分系统可能限制此方式'**
  String get unableToConnectToLocalPortCheck;

  /// No description provided for @deviceUnauthorizedConfirmAuthorizationOnTheTarget.
  ///
  /// In zh, this message translates to:
  /// **'设备未授权：请在目标设备确认调试授权；无线调试请重新配对，再使用连接端口连接。'**
  String get deviceUnauthorizedConfirmAuthorizationOnTheTarget;

  /// No description provided for @deviceOfflineEnableWirelessDebuggingThenDisconnect.
  ///
  /// In zh, this message translates to:
  /// **'设备离线：请确认无线调试仍开启，再断开此设备并用当前连接端口重连。'**
  String get deviceOfflineEnableWirelessDebuggingThenDisconnect;

  /// No description provided for @adbAuthenticationFailedPairAgainInWireless.
  ///
  /// In zh, this message translates to:
  /// **'ADB 认证失败：请在无线调试中重新配对，再连接。'**
  String get adbAuthenticationFailedPairAgainInWireless;

  /// No description provided for @connectionRefusedEnableWirelessDebuggingAndUse.
  ///
  /// In zh, this message translates to:
  /// **'连接被拒绝：请开启无线调试，并使用主页上的连接端口。'**
  String get connectionRefusedEnableWirelessDebuggingAndUse;

  /// No description provided for @connectionTimedOutCheckTheAddressNetwork.
  ///
  /// In zh, this message translates to:
  /// **'连接超时：请检查设备地址、网络和无线调试状态。'**
  String get connectionTimedOutCheckTheAddressNetwork;

  /// No description provided for @deviceIsNotOnlineCheckTerminalOutput.
  ///
  /// In zh, this message translates to:
  /// **'设备尚未上线，请查看终端输出并核对无线调试的连接端口'**
  String get deviceIsNotOnlineCheckTerminalOutput;

  /// No description provided for @disconnectedFromPPairingAuthorizationIsRetained.
  ///
  /// In zh, this message translates to:
  /// **'已断开 {p0}；配对授权仍保留。'**
  String disconnectedFromPPairingAuthorizationIsRetained(Object? p0);

  /// No description provided for @unableToConfirmDisconnectionCheckTerminalOutput.
  ///
  /// In zh, this message translates to:
  /// **'无法确认设备已断开，请查看终端输出并刷新设备。'**
  String get unableToConfirmDisconnectionCheckTerminalOutput;

  /// No description provided for @connectedButFailedToSaveDeviceSettings.
  ///
  /// In zh, this message translates to:
  /// **'连接结果已生效，但设备设置保存失败： {p0}'**
  String connectedButFailedToSaveDeviceSettings(Object? p0);

  /// No description provided for @unableToReadAdbDeviceStatus.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 ADB 设备状态'**
  String get unableToReadAdbDeviceStatus;

  /// No description provided for @tryingPreviousConnectionPortP.
  ///
  /// In zh, this message translates to:
  /// **'尝试上次连接端口 {p0}'**
  String tryingPreviousConnectionPortP(Object? p0);

  /// No description provided for @scanningLocalWirelessDebuggingPorts.
  ///
  /// In zh, this message translates to:
  /// **'扫描本机无线调试连接端口…'**
  String get scanningLocalWirelessDebuggingPorts;

  /// No description provided for @foundConnectionPortP.
  ///
  /// In zh, this message translates to:
  /// **'发现连接端口 {p0}'**
  String foundConnectionPortP(Object? p0);

  /// No description provided for @scanOrConnectionFailedP.
  ///
  /// In zh, this message translates to:
  /// **'扫描或连接失败：{p0}'**
  String scanOrConnectionFailedP(Object? p0);

  /// No description provided for @connectedLocallyYouCanUnplugTheCable.
  ///
  /// In zh, this message translates to:
  /// **'已连接本机，可以拔掉数据线。'**
  String get connectedLocallyYouCanUnplugTheCable;

  /// No description provided for @waitTimedOutCheckTheComputerCommand.
  ///
  /// In zh, this message translates to:
  /// **'等待超时，请检查电脑命令输出，然后重新连接。'**
  String get waitTimedOutCheckTheComputerCommand;

  /// No description provided for @allowUsbDebuggingOnThePhoneFlit.
  ///
  /// In zh, this message translates to:
  /// **'请在手机上允许 USB 调试授权，Flit 会自动继续连接。'**
  String get allowUsbDebuggingOnThePhoneFlit;

  /// No description provided for @unableToReadAdbStatusCheckThe.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 ADB 状态，请检查开发环境；正在重试…'**
  String get unableToReadAdbStatusCheckThe;

  /// No description provided for @waitingForComputerActivationFlitWillConnect.
  ///
  /// In zh, this message translates to:
  /// **'等待电脑激活… Flit 会自动连接本机。'**
  String get waitingForComputerActivationFlitWillConnect;

  /// No description provided for @activateViaComputerUsb.
  ///
  /// In zh, this message translates to:
  /// **'通过电脑 USB 激活'**
  String get activateViaComputerUsb;

  /// No description provided for @enableUsbDebuggingConnectThePhoneTo.
  ///
  /// In zh, this message translates to:
  /// **'1. 手机开启 USB 调试，用数据线连接电脑，并允许调试授权。电脑只连接这一台手机。'**
  String get enableUsbDebuggingConnectThePhoneTo;

  /// No description provided for @downloadAndExtractPlatformToolsOnThe.
  ///
  /// In zh, this message translates to:
  /// **'2. 电脑下载并解压 Platform Tools，在解压目录打开终端。'**
  String get downloadAndExtractPlatformToolsOnThe;

  /// No description provided for @unableToOpenTheDownloadPage.
  ///
  /// In zh, this message translates to:
  /// **'无法打开下载页面'**
  String get unableToOpenTheDownloadPage;

  /// No description provided for @onTheComputerVisitDeveloperAndroidCom.
  ///
  /// In zh, this message translates to:
  /// **'请在电脑访问 developer.android.com/tools/releases/platform-tools'**
  String get onTheComputerVisitDeveloperAndroidCom;

  /// No description provided for @platformToolsWebsite.
  ///
  /// In zh, this message translates to:
  /// **'Platform Tools 官网'**
  String get platformToolsWebsite;

  /// No description provided for @runThisCommandOnTheComputerKeep.
  ///
  /// In zh, this message translates to:
  /// **'3. 在电脑执行这一条命令，然后保持此引导打开，等待连接。'**
  String get runThisCommandOnTheComputerKeep;

  /// No description provided for @computerOs.
  ///
  /// In zh, this message translates to:
  /// **'电脑系统'**
  String get computerOs;

  /// No description provided for @copyFailedLongPressTheCommandTo.
  ///
  /// In zh, this message translates to:
  /// **'复制失败，请长按命令复制'**
  String get copyFailedLongPressTheCommandTo;

  /// No description provided for @copyCommand.
  ///
  /// In zh, this message translates to:
  /// **'复制命令'**
  String get copyCommand;

  /// No description provided for @afterTheComputerShowsRestartingInTcp.
  ///
  /// In zh, this message translates to:
  /// **'电脑显示 restarting in TCP mode port: 5555 后，Flit 会尝试连接。若手机再次弹出调试授权，请允许。'**
  String get afterTheComputerShowsRestartingInTcp;

  /// No description provided for @waitsAutomaticallyForUpToMinutesClosing.
  ///
  /// In zh, this message translates to:
  /// **'自动等待最多 2 分钟，退出引导即停止。之后仍可在设备页点“连接本机”。手机重启后通常需要重新激活。'**
  String get waitsAutomaticallyForUpToMinutesClosing;

  /// No description provided for @tcpDebuggingMayAlsoListenOnNetwork.
  ///
  /// In zh, this message translates to:
  /// **'TCP 调试可能同时监听网络接口。停用时接回电脑执行 {p0} -d usb；Flit 中“断开”仅断开客户端。'**
  String tcpDebuggingMayAlsoListenOnNetwork(Object? p0);

  /// No description provided for @reconnect.
  ///
  /// In zh, this message translates to:
  /// **'重新连接'**
  String get reconnect;

  /// No description provided for @connectNow.
  ///
  /// In zh, this message translates to:
  /// **'立即连接'**
  String get connectNow;

  /// No description provided for @unableToReadPairingStatusGoBack.
  ///
  /// In zh, this message translates to:
  /// **'无法读取配对状态，请返回后重试'**
  String get unableToReadPairingStatusGoBack;

  /// No description provided for @systemOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'系统操作失败'**
  String get systemOperationFailed;

  /// No description provided for @openTheSystemPairingDialogAndEnter.
  ///
  /// In zh, this message translates to:
  /// **'打开系统配对码窗口，在通知中输入配对码'**
  String get openTheSystemPairingDialogAndEnter;

  /// No description provided for @noPairingPortFoundKeepTheSystem.
  ///
  /// In zh, this message translates to:
  /// **'未发现配对端口，请保持系统配对窗口开启'**
  String get noPairingPortFoundKeepTheSystem;

  /// No description provided for @refreshDevices.
  ///
  /// In zh, this message translates to:
  /// **'刷新设备'**
  String get refreshDevices;

  /// No description provided for @manualConnectionOtherDevices.
  ///
  /// In zh, this message translates to:
  /// **'手动连接 / 其他设备'**
  String get manualConnectionOtherDevices;

  /// No description provided for @deviceAddress.
  ///
  /// In zh, this message translates to:
  /// **'设备地址'**
  String get deviceAddress;

  /// No description provided for @connectionPort.
  ///
  /// In zh, this message translates to:
  /// **'连接端口'**
  String get connectionPort;

  /// No description provided for @connect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connect;

  /// No description provided for @pairingRecorded.
  ///
  /// In zh, this message translates to:
  /// **'有配对记录'**
  String get pairingRecorded;

  /// No description provided for @keepTheSystemPairingDialogOpenIn.
  ///
  /// In zh, this message translates to:
  /// **'手动配对时请分屏保留系统配对窗口。'**
  String get keepTheSystemPairingDialogOpenIn;

  /// No description provided for @pairingPort.
  ///
  /// In zh, this message translates to:
  /// **'配对端口'**
  String get pairingPort;

  /// No description provided for @pairingCodeDigits.
  ///
  /// In zh, this message translates to:
  /// **'配对码（6 位）'**
  String get pairingCodeDigits;

  /// No description provided for @scanning.
  ///
  /// In zh, this message translates to:
  /// **'扫描中…'**
  String get scanning;

  /// No description provided for @scanPairingPorts.
  ///
  /// In zh, this message translates to:
  /// **'扫描配对端口'**
  String get scanPairingPorts;

  /// No description provided for @pair.
  ///
  /// In zh, this message translates to:
  /// **'配对'**
  String get pair;

  /// No description provided for @wirelessPairingGuide.
  ///
  /// In zh, this message translates to:
  /// **'无线配对指南'**
  String get wirelessPairingGuide;

  /// No description provided for @notificationStylePairingStepsAndTroubleshooting.
  ///
  /// In zh, this message translates to:
  /// **'通知样式、配对步骤与常见问题'**
  String get notificationStylePairingStepsAndTroubleshooting;

  /// No description provided for @connectViaWirelessDebugging.
  ///
  /// In zh, this message translates to:
  /// **'通过无线调试连接'**
  String get connectViaWirelessDebugging;

  /// No description provided for @androidPairAndConnectOverWiFi.
  ///
  /// In zh, this message translates to:
  /// **'Android 11+ · Wi-Fi 下配对与连接'**
  String get androidPairAndConnectOverWiFi;

  /// No description provided for @wirelessDebuggingSettings.
  ///
  /// In zh, this message translates to:
  /// **'无线调试设置'**
  String get wirelessDebuggingSettings;

  /// No description provided for @notificationPairing.
  ///
  /// In zh, this message translates to:
  /// **'通知配对'**
  String get notificationPairing;

  /// No description provided for @scanAndConnect.
  ///
  /// In zh, this message translates to:
  /// **'扫描并连接'**
  String get scanAndConnect;

  /// No description provided for @searchingForPairingPort.
  ///
  /// In zh, this message translates to:
  /// **'正在寻找配对端口…'**
  String get searchingForPairingPort;

  /// No description provided for @cancelPairing.
  ///
  /// In zh, this message translates to:
  /// **'取消配对'**
  String get cancelPairing;

  /// No description provided for @activateFromAComputerThenUnplugThe.
  ///
  /// In zh, this message translates to:
  /// **'电脑激活后连接，可拔掉数据线'**
  String get activateFromAComputerThenUnplugThe;

  /// No description provided for @viewSteps.
  ///
  /// In zh, this message translates to:
  /// **'查看步骤'**
  String get viewSteps;

  /// No description provided for @connecting.
  ///
  /// In zh, this message translates to:
  /// **'连接中…'**
  String get connecting;

  /// No description provided for @connectLocally.
  ///
  /// In zh, this message translates to:
  /// **'连接本机'**
  String get connectLocally;

  /// No description provided for @deviceStatus.
  ///
  /// In zh, this message translates to:
  /// **'设备状态'**
  String get deviceStatus;

  /// No description provided for @pOnline.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 台在线'**
  String pOnline(Object? p0);

  /// No description provided for @adbNotFoundInstallTheAndroidToolchain.
  ///
  /// In zh, this message translates to:
  /// **'未找到 ADB，请在“开发环境”中安装 Android 工具链。'**
  String get adbNotFoundInstallTheAndroidToolchain;

  /// No description provided for @noConnections.
  ///
  /// In zh, this message translates to:
  /// **'暂无连接'**
  String get noConnections;

  /// No description provided for @disconnectP.
  ///
  /// In zh, this message translates to:
  /// **'断开 {p0}'**
  String disconnectP(Object? p0);

  /// No description provided for @unableToReadNotificationStatus.
  ///
  /// In zh, this message translates to:
  /// **'无法读取通知状态'**
  String get unableToReadNotificationStatus;

  /// No description provided for @unableToReadNotificationStatusRetry.
  ///
  /// In zh, this message translates to:
  /// **'无法读取通知状态，请重试'**
  String get unableToReadNotificationStatusRetry;

  /// No description provided for @unableToOpenSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'无法打开系统设置'**
  String get unableToOpenSystemSettings;

  /// No description provided for @unableToOpenRetryLater.
  ///
  /// In zh, this message translates to:
  /// **'无法打开，请稍后重试'**
  String get unableToOpenRetryLater;

  /// No description provided for @enterThePairingCodeInTheNotification.
  ///
  /// In zh, this message translates to:
  /// **'在通知中输入配对码'**
  String get enterThePairingCodeInTheNotification;

  /// No description provided for @androidPhoneMustBeConnectedToWi.
  ///
  /// In zh, this message translates to:
  /// **'Android 11 及以上 · 手机需连接 Wi-Fi'**
  String get androidPhoneMustBeConnectedToWi;

  /// No description provided for @checkingNotificationPermission.
  ///
  /// In zh, this message translates to:
  /// **'正在检查通知权限…'**
  String get checkingNotificationPermission;

  /// No description provided for @wirelessPairingIsNotSupportedOnThis.
  ///
  /// In zh, this message translates to:
  /// **'此系统不支持无线配对'**
  String get wirelessPairingIsNotSupportedOnThis;

  /// No description provided for @pairingNotificationsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'配对通知已开启'**
  String get pairingNotificationsEnabled;

  /// No description provided for @allowFlitNotificationsFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先允许 Flit 通知'**
  String get allowFlitNotificationsFirst;

  /// No description provided for @notificationStatusUnknown.
  ///
  /// In zh, this message translates to:
  /// **'通知状态未知'**
  String get notificationStatusUnknown;

  /// No description provided for @wirelessPairingRequiresAndroidOrLaterGo.
  ///
  /// In zh, this message translates to:
  /// **'无线配对需要 Android 11 或以上，可返回使用电脑 USB 激活。'**
  String get wirelessPairingRequiresAndroidOrLaterGo;

  /// No description provided for @allowFlitNotificationsIncludingTheWirelessDebugging.
  ///
  /// In zh, this message translates to:
  /// **'允许 Flit 发布通知；若已有“无线调试配对”通知类别，也要开启。配对时从通知里输入代码。'**
  String get allowFlitNotificationsIncludingTheWirelessDebugging;

  /// No description provided for @notificationSettings.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get notificationSettings;

  /// No description provided for @checkAgain487.
  ///
  /// In zh, this message translates to:
  /// **'重新检查'**
  String get checkAgain487;

  /// No description provided for @xiaomiPocoSomeMiuiVersionsRequireThe.
  ///
  /// In zh, this message translates to:
  /// **'小米 / POCO：部分 MIUI 需要把通知样式改为“原生样式”，否则可能无法输入配对码。具体路径见下方说明。'**
  String get xiaomiPocoSomeMiuiVersionsRequireThe;

  /// No description provided for @finishTheCurrentDeviceOperationOrInstall.
  ///
  /// In zh, this message translates to:
  /// **'请先在设备页结束当前操作，或安装缺失的 ADB，再开始配对。'**
  String get finishTheCurrentDeviceOperationOrInstall;

  /// No description provided for @startPairing.
  ///
  /// In zh, this message translates to:
  /// **'开始配对'**
  String get startPairing;

  /// No description provided for @tapStartPairingBelowFlitStartsThe.
  ///
  /// In zh, this message translates to:
  /// **'点击下方“开始配对”，Flit 会先启动配对通知，再打开开发者选项。首次使用请先开启开发者选项和 USB 调试。'**
  String get tapStartPairingBelowFlitStartsThe;

  /// No description provided for @openThePairingCodeDialog.
  ///
  /// In zh, this message translates to:
  /// **'打开配对码窗口'**
  String get openThePairingCodeDialog;

  /// No description provided for @enableWirelessDebuggingTapItsLabelTo.
  ///
  /// In zh, this message translates to:
  /// **'开启“无线调试”，点击这项的文字进入详情，再点“使用配对码配对设备”。保持显示 6 位代码的窗口打开。'**
  String get enableWirelessDebuggingTapItsLabelTo;

  /// No description provided for @enablingTheSwitchAloneIsNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'仅打开右侧开关还不够，需要进入无线调试详情页。'**
  String get enablingTheSwitchAloneIsNotEnough;

  /// No description provided for @expandTheNotificationAndEnterTheDigit.
  ///
  /// In zh, this message translates to:
  /// **'下拉通知，输入 6 位码'**
  String get expandTheNotificationAndEnterTheDigit;

  /// No description provided for @expandTheFlitPairingNotificationTapEnter.
  ///
  /// In zh, this message translates to:
  /// **'展开 Flit 的配对通知，点击“输入配对码”，填入系统窗口中的代码并发送。不要切回 Flit 填写，切换应用可能关闭配对窗口。'**
  String get expandTheFlitPairingNotificationTapEnter;

  /// No description provided for @theEnterPairingCodeButtonAppearsOnce.
  ///
  /// In zh, this message translates to:
  /// **'找到配对端口后，通知才会出现“输入配对码”按钮。'**
  String get theEnterPairingCodeButtonAppearsOnce;

  /// No description provided for @returnToFlitToConnect.
  ///
  /// In zh, this message translates to:
  /// **'返回 Flit 连接'**
  String get returnToFlitToConnect;

  /// No description provided for @returnToFlitAfterSuccessfulPairingIt.
  ///
  /// In zh, this message translates to:
  /// **'通知提示配对成功后返回 Flit，会自动尝试连接本机。已配对时直接“扫描并连接”；重新开启无线调试后，连接端口可能改变。'**
  String get returnToFlitAfterSuccessfulPairingIt;

  /// No description provided for @noNotificationInputEnteringTheCodeFails.
  ///
  /// In zh, this message translates to:
  /// **'通知里没有输入框 / 点输入就失败'**
  String get noNotificationInputEnteringTheCodeFails;

  /// No description provided for @expandTheNotificationAndCheckThatEnter.
  ///
  /// In zh, this message translates to:
  /// **'先展开通知，确认已显示“输入配对码”。若仍停留在“搜索端口”，请看下一项。'**
  String get expandTheNotificationAndCheckThatEnter;

  /// No description provided for @someXiaomiRedmiAndPocoMiuiVersions.
  ///
  /// In zh, this message translates to:
  /// **'小米、Redmi、POCO 的部分 MIUI：在系统设置 → 通知管理 → 通知显示设置，将通知样式切为“原生样式”，再重新配对。'**
  String get someXiaomiRedmiAndPocoMiuiVersions;

  /// No description provided for @namesAndLocationsVaryAcrossHyperosAnd.
  ///
  /// In zh, this message translates to:
  /// **'HyperOS 或其他版本的入口、名称可能不同；如提供“Android”或“原生”通知样式，可尝试切换。Flit 无法自动检测或修改此设置。'**
  String get namesAndLocationsVaryAcrossHyperosAnd;

  /// No description provided for @ifThisOptionIsUnavailableKeepThe.
  ///
  /// In zh, this message translates to:
  /// **'找不到该选项时，可用分屏保留系统配对窗口，在“手动连接 / 其他设备”输入配对端口和配对码。'**
  String get ifThisOptionIsUnavailableKeepThe;

  /// No description provided for @keepsSearchingNoResponseAfterOpeningSettings.
  ///
  /// In zh, this message translates to:
  /// **'一直搜索端口 / 切到设置后没反应'**
  String get keepsSearchingNoResponseAfterOpeningSettings;

  /// No description provided for @enableWiFiAndWirelessDebuggingAnd.
  ///
  /// In zh, this message translates to:
  /// **'确认 Wi-Fi 和无线调试已开启，并保持“使用配对码配对设备”窗口打开。配对端口只在这个窗口打开时广播。'**
  String get enableWiFiAndWirelessDebuggingAnd;

  /// No description provided for @someSystemsRestrictLocalNetworkAccessFor.
  ///
  /// In zh, this message translates to:
  /// **'部分系统会限制不可见应用的本地网络访问。允许 Flit 后台运行，并在系统的联网管理中允许 Wi-Fi / 本地网络访问（如提供）。'**
  String get someSystemsRestrictLocalNetworkAccessFor;

  /// No description provided for @allowBackgroundExecution.
  ///
  /// In zh, this message translates to:
  /// **'允许后台运行'**
  String get allowBackgroundExecution;

  /// No description provided for @ifNothingIsFoundToggleWirelessDebugging.
  ///
  /// In zh, this message translates to:
  /// **'仍无结果可重新开关无线调试后再试。Flit 最多搜索 3 分钟；超时后重新开始，也可改用电脑 USB 激活。'**
  String get ifNothingIsFoundToggleWirelessDebugging;

  /// No description provided for @pairedButCannotConnect.
  ///
  /// In zh, this message translates to:
  /// **'配对成功，但连接失败'**
  String get pairedButCannotConnect;

  /// No description provided for @pairingAndConnectionPortsDifferForManual.
  ///
  /// In zh, this message translates to:
  /// **'配对端口与连接端口不同。手动连接时，请使用无线调试主页显示的连接端口，不要使用配对码窗口的端口。'**
  String get pairingAndConnectionPortsDifferForManual;

  /// No description provided for @tapScanAndConnectOnTheDevice.
  ///
  /// In zh, this message translates to:
  /// **'返回设备页点“扫描并连接”。仍找不到端口时，可以手动输入连接端口，或使用电脑 USB 激活。配对记录不代表设备当前在线。'**
  String get tapScanAndConnectOnTheDevice;

  /// No description provided for @unableToOpenReferencePage.
  ///
  /// In zh, this message translates to:
  /// **'无法打开参考页面'**
  String get unableToOpenReferencePage;

  /// No description provided for @referenceShizukuGuide.
  ///
  /// In zh, this message translates to:
  /// **'参考：Shizuku 使用指南'**
  String get referenceShizukuGuide;

  /// No description provided for @webServerRestarted.
  ///
  /// In zh, this message translates to:
  /// **'Web 服务已重新运行'**
  String get webServerRestarted;

  /// No description provided for @webStartupTimedOutCheckRunLogs.
  ///
  /// In zh, this message translates to:
  /// **'Web 启动超时，请查看运行日志'**
  String get webStartupTimedOutCheckRunLogs;

  /// No description provided for @webStartupFailedP.
  ///
  /// In zh, this message translates to:
  /// **'Web 启动失败：{p0}'**
  String webStartupFailedP(Object? p0);

  /// No description provided for @webRunFailedP.
  ///
  /// In zh, this message translates to:
  /// **'Web 运行失败：{p0}'**
  String webRunFailedP(Object? p0);

  /// No description provided for @updateFailedP.
  ///
  /// In zh, this message translates to:
  /// **'更新失败：{p0}'**
  String updateFailedP(Object? p0);

  /// No description provided for @webProcessExitedCodePCheckRun.
  ///
  /// In zh, this message translates to:
  /// **'Web 进程已退出（退出码 {p0}），请查看运行日志'**
  String webProcessExitedCodePCheckRun(Object? p0);

  /// No description provided for @webServerStopped.
  ///
  /// In zh, this message translates to:
  /// **'Web 服务已停止'**
  String get webServerStopped;

  /// No description provided for @runWebToPreviewHere.
  ///
  /// In zh, this message translates to:
  /// **'运行 Web 后在这里预览'**
  String get runWebToPreviewHere;

  /// No description provided for @compilingAndStartingTheWebServer.
  ///
  /// In zh, this message translates to:
  /// **'正在编译并启动 Web 服务'**
  String get compilingAndStartingTheWebServer;

  /// No description provided for @webStartupFailed.
  ///
  /// In zh, this message translates to:
  /// **'Web 启动失败'**
  String get webStartupFailed;

  /// No description provided for @viewRunLogs.
  ///
  /// In zh, this message translates to:
  /// **'查看运行日志'**
  String get viewRunLogs;

  /// No description provided for @thePageHasNotRenderedYetCheck.
  ///
  /// In zh, this message translates to:
  /// **'页面尚未完成首次渲染，请查看运行日志或重新加载'**
  String get thePageHasNotRenderedYetCheck;

  /// No description provided for @pageLoadFailedP.
  ///
  /// In zh, this message translates to:
  /// **'页面加载失败：{p0}'**
  String pageLoadFailedP(Object? p0);

  /// No description provided for @pageRequestFailedHttpP.
  ///
  /// In zh, this message translates to:
  /// **'页面请求失败：HTTP {p0}'**
  String pageRequestFailedHttpP(Object? p0);

  /// No description provided for @unableToLoadPreviewP.
  ///
  /// In zh, this message translates to:
  /// **'无法加载预览：{p0}'**
  String unableToLoadPreviewP(Object? p0);

  /// No description provided for @reloadPageResetPageState.
  ///
  /// In zh, this message translates to:
  /// **'重新加载页面（重置页面状态）'**
  String get reloadPageResetPageState;

  /// No description provided for @loadingPreview.
  ///
  /// In zh, this message translates to:
  /// **'正在加载预览…'**
  String get loadingPreview;

  /// No description provided for @reload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @updating.
  ///
  /// In zh, this message translates to:
  /// **'正在更新…'**
  String get updating;

  /// No description provided for @document.
  ///
  /// In zh, this message translates to:
  /// **'本文档'**
  String get document;

  /// No description provided for @symbol.
  ///
  /// In zh, this message translates to:
  /// **'符号'**
  String get symbol;

  /// No description provided for @keyword.
  ///
  /// In zh, this message translates to:
  /// **'关键字'**
  String get keyword;

  /// No description provided for @method.
  ///
  /// In zh, this message translates to:
  /// **'方法'**
  String get method;

  /// No description provided for @type.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get type;

  /// No description provided for @variable.
  ///
  /// In zh, this message translates to:
  /// **'变量'**
  String get variable;

  /// No description provided for @module.
  ///
  /// In zh, this message translates to:
  /// **'模块'**
  String get module;

  /// No description provided for @property.
  ///
  /// In zh, this message translates to:
  /// **'属性'**
  String get property;

  /// No description provided for @dartLanguageServiceCouldNotStart.
  ///
  /// In zh, this message translates to:
  /// **'Dart 语言服务无法启动'**
  String get dartLanguageServiceCouldNotStart;

  /// No description provided for @initializationFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败'**
  String get initializationFailed;

  /// No description provided for @languageServiceDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'语言服务连接已断开'**
  String get languageServiceDisconnected;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get saved;

  /// No description provided for @fileChangedExternallySavingStoppedTapThe.
  ///
  /// In zh, this message translates to:
  /// **'文件已被外部修改，保存已停止。点击标题下方状态可重新载入。'**
  String get fileChangedExternallySavingStoppedTapThe;

  /// No description provided for @fileChangedExternally.
  ///
  /// In zh, this message translates to:
  /// **'文件已被外部修改'**
  String get fileChangedExternally;

  /// No description provided for @pSavingStoppedToAvoidOverwritingDisk.
  ///
  /// In zh, this message translates to:
  /// **'{p0}\n\n为避免覆盖磁盘上的修改，已停止保存。重新载入将丢弃此文件尚未保存的编辑内容。'**
  String pSavingStoppedToAvoidOverwritingDisk(Object? p0);

  /// No description provided for @reloadFromDisk.
  ///
  /// In zh, this message translates to:
  /// **'重新载入'**
  String get reloadFromDisk;

  /// No description provided for @unableToReadP.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 {p0}'**
  String unableToReadP(Object? p0);

  /// No description provided for @aFileOperationIsInProgressWait.
  ///
  /// In zh, this message translates to:
  /// **'文件操作正在进行，请稍后再关闭'**
  String get aFileOperationIsInProgressWait;

  /// No description provided for @aFileOperationIsInProgressWait552.
  ///
  /// In zh, this message translates to:
  /// **'文件操作正在进行，请等待完成后再关闭项目'**
  String get aFileOperationIsInProgressWait552;

  /// No description provided for @fileChangedTapToResolve.
  ///
  /// In zh, this message translates to:
  /// **'文件已变更 · 点击处理'**
  String get fileChangedTapToResolve;

  /// No description provided for @saveFailedTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'保存失败 · 点击重试'**
  String get saveFailedTapToRetry;

  /// No description provided for @saving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存…'**
  String get saving;

  /// No description provided for @unsaved.
  ///
  /// In zh, this message translates to:
  /// **'未保存'**
  String get unsaved;

  /// No description provided for @project.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get project;

  /// No description provided for @versionControl.
  ///
  /// In zh, this message translates to:
  /// **'版本控制'**
  String get versionControl;

  /// No description provided for @closeProject.
  ///
  /// In zh, this message translates to:
  /// **'关闭项目'**
  String get closeProject;

  /// No description provided for @selectAFileFromTheProjectTool.
  ///
  /// In zh, this message translates to:
  /// **'从“项目”工具窗口选择文件以开始编辑'**
  String get selectAFileFromTheProjectTool;

  /// No description provided for @openProjectToolWindow.
  ///
  /// In zh, this message translates to:
  /// **'打开项目工具窗口'**
  String get openProjectToolWindow;

  /// No description provided for @editorOptions.
  ///
  /// In zh, this message translates to:
  /// **'编辑器选项'**
  String get editorOptions;

  /// No description provided for @settingsSaveAutomaticallyPinchInTheCode.
  ///
  /// In zh, this message translates to:
  /// **'设置自动保存，也可在代码区双指缩放。'**
  String get settingsSaveAutomaticallyPinchInTheCode;

  /// No description provided for @display.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get display;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'字号'**
  String get fontSize;

  /// No description provided for @font.
  ///
  /// In zh, this message translates to:
  /// **'字体'**
  String get font;

  /// No description provided for @builtIn.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get builtIn;

  /// No description provided for @colorScheme.
  ///
  /// In zh, this message translates to:
  /// **'配色方案'**
  String get colorScheme;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @terminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get terminal;

  /// No description provided for @editing.
  ///
  /// In zh, this message translates to:
  /// **'编辑行为'**
  String get editing;

  /// No description provided for @softWraps.
  ///
  /// In zh, this message translates to:
  /// **'软换行'**
  String get softWraps;

  /// No description provided for @wrapLongLinesWithoutInsertingLineBreaks.
  ///
  /// In zh, this message translates to:
  /// **'长行自动折行显示，不插入换行符'**
  String get wrapLongLinesWithoutInsertingLineBreaks;

  /// No description provided for @scrollLongLinesHorizontallyLineNumbersStay.
  ///
  /// In zh, this message translates to:
  /// **'长行横向滚动，行号保持可见'**
  String get scrollLongLinesHorizontallyLineNumbersStay;

  /// No description provided for @deleteP576.
  ///
  /// In zh, this message translates to:
  /// **'删除「{p0}」？'**
  String deleteP576(Object? p0);

  /// No description provided for @permanentlyDeleteTheSelectedFileOrDirectory.
  ///
  /// In zh, this message translates to:
  /// **'将永久删除所选文件或目录及其内容，此操作无法撤销。'**
  String get permanentlyDeleteTheSelectedFileOrDirectory;

  /// No description provided for @name.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @newDirectory.
  ///
  /// In zh, this message translates to:
  /// **'新建目录'**
  String get newDirectory;

  /// No description provided for @newFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get newFile;

  /// No description provided for @installMissingAndroidBuildComponents.
  ///
  /// In zh, this message translates to:
  /// **'补齐 Android 构建组件？'**
  String get installMissingAndroidBuildComponents;

  /// No description provided for @componentsCurrentlyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'组件暂时无法安装'**
  String get componentsCurrentlyUnavailable;

  /// No description provided for @theBuildFailedBecauseTheseComponentsAre.
  ///
  /// In zh, this message translates to:
  /// **'本次构建缺少或无法使用以下组件：'**
  String get theBuildFailedBecauseTheseComponentsAre;

  /// No description provided for @preflightFoundTheseMissingOrUnusableComponents.
  ///
  /// In zh, this message translates to:
  /// **'构建前检查发现以下组件缺失或不可用：'**
  String get preflightFoundTheseMissingOrUnusableComponents;

  /// No description provided for @theBuildWillPAfterInstallationDownload.
  ///
  /// In zh, this message translates to:
  /// **'安装完成后{p0}构建。下载进度会显示在控制台中。'**
  String theBuildWillPAfterInstallationDownload(Object? p0);

  /// No description provided for @installAndRetry.
  ///
  /// In zh, this message translates to:
  /// **'安装并重试'**
  String get installAndRetry;

  /// No description provided for @installAndContinue.
  ///
  /// In zh, this message translates to:
  /// **'安装并继续'**
  String get installAndContinue;

  /// No description provided for @starting.
  ///
  /// In zh, this message translates to:
  /// **'正在启动'**
  String get starting;

  /// No description provided for @rerun.
  ///
  /// In zh, this message translates to:
  /// **'重新运行'**
  String get rerun;

  /// No description provided for @run.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get run;

  /// No description provided for @hotReload.
  ///
  /// In zh, this message translates to:
  /// **'热重载'**
  String get hotReload;

  /// No description provided for @stopRun.
  ///
  /// In zh, this message translates to:
  /// **'停止运行'**
  String get stopRun;

  /// No description provided for @switchRunTarget.
  ///
  /// In zh, this message translates to:
  /// **'切换运行目标？'**
  String get switchRunTarget;

  /// No description provided for @stopTheCurrentRunAndStartThe.
  ///
  /// In zh, this message translates to:
  /// **'将停止当前运行，并在新目标上运行项目。'**
  String get stopTheCurrentRunAndStartThe;

  /// No description provided for @switchAndRun.
  ///
  /// In zh, this message translates to:
  /// **'切换并运行'**
  String get switchAndRun;

  /// No description provided for @tasks.
  ///
  /// In zh, this message translates to:
  /// **'任务'**
  String get tasks;

  /// No description provided for @currentProjectP.
  ///
  /// In zh, this message translates to:
  /// **'当前项目： {p0}'**
  String currentProjectP(Object? p0);

  /// No description provided for @currentTaskP.
  ///
  /// In zh, this message translates to:
  /// **'当前任务：{p0}'**
  String currentTaskP(Object? p0);

  /// No description provided for @tasksUseSeparateTerminalsConflictingActionsAre.
  ///
  /// In zh, this message translates to:
  /// **'各任务使用独立终端，冲突操作暂不可用。'**
  String get tasksUseSeparateTerminalsConflictingActionsAre;

  /// No description provided for @dependencies.
  ///
  /// In zh, this message translates to:
  /// **'依赖'**
  String get dependencies;

  /// No description provided for @fetchDependenciesAndWritePackageConfig.
  ///
  /// In zh, this message translates to:
  /// **'获取依赖并写入 package_config'**
  String get fetchDependenciesAndWritePackageConfig;

  /// No description provided for @upgradeDependenciesWithinConstraints.
  ///
  /// In zh, this message translates to:
  /// **'按约束升级依赖'**
  String get upgradeDependenciesWithinConstraints;

  /// No description provided for @listOutdatedDependencies.
  ///
  /// In zh, this message translates to:
  /// **'列出可升级的依赖'**
  String get listOutdatedDependencies;

  /// No description provided for @build.
  ///
  /// In zh, this message translates to:
  /// **'构建'**
  String get build;

  /// No description provided for @buildThenInstallOnTheSelectedAndroid.
  ///
  /// In zh, this message translates to:
  /// **'构建完成后通过 ADB 安装到选中的 Android 设备'**
  String get buildThenInstallOnTheSelectedAndroid;

  /// No description provided for @buildAReleaseApkThenChooseAdb.
  ///
  /// In zh, this message translates to:
  /// **'生成发布 APK；之后可选 ADB 设备或系统安装器'**
  String get buildAReleaseApkThenChooseAdb;

  /// No description provided for @outputDirectoryBuildWeb.
  ///
  /// In zh, this message translates to:
  /// **'输出目录：build/web'**
  String get outputDirectoryBuildWeb;

  /// No description provided for @dartCompileExeOutputBuildPackageName.
  ///
  /// In zh, this message translates to:
  /// **'dart compile exe，输出 build/<包名>；完成后可在终端直接运行'**
  String get dartCompileExeOutputBuildPackageName;

  /// No description provided for @code.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get code;

  /// No description provided for @runBatchAnalysisAndShowResultsIn.
  ///
  /// In zh, this message translates to:
  /// **'分析器批量诊断，输出到终端'**
  String get runBatchAnalysisAndShowResultsIn;

  /// No description provided for @runTestsInTheTestDirectory.
  ///
  /// In zh, this message translates to:
  /// **'运行 test/ 目录下的测试'**
  String get runTestsInTheTestDirectory;

  /// No description provided for @maintenance.
  ///
  /// In zh, this message translates to:
  /// **'维护'**
  String get maintenance;

  /// No description provided for @deleteBuildAndDartToolCaches.
  ///
  /// In zh, this message translates to:
  /// **'删除 build/ 与 .dart_tool 缓存'**
  String get deleteBuildAndDartToolCaches;

  /// No description provided for @checkFlutterAndAndroidToolchainHealth.
  ///
  /// In zh, this message translates to:
  /// **'检查 Flutter/Android 工具链健康度'**
  String get checkFlutterAndAndroidToolchainHealth;

  /// No description provided for @failedToReadDevicesP.
  ///
  /// In zh, this message translates to:
  /// **'读取设备失败： {p0}'**
  String failedToReadDevicesP(Object? p0);

  /// No description provided for @selectPlatform.
  ///
  /// In zh, this message translates to:
  /// **'选择平台'**
  String get selectPlatform;

  /// No description provided for @webPreview.
  ///
  /// In zh, this message translates to:
  /// **'Web 预览'**
  String get webPreview;

  /// No description provided for @runTarget.
  ///
  /// In zh, this message translates to:
  /// **'运行目标'**
  String get runTarget;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @previewInsideTheIdeWithoutADevice.
  ///
  /// In zh, this message translates to:
  /// **'在 IDE 内预览，无需连接设备'**
  String get previewInsideTheIdeWithoutADevice;

  /// No description provided for @connectAndroidDevice.
  ///
  /// In zh, this message translates to:
  /// **'连接 Android 设备'**
  String get connectAndroidDevice;

  /// No description provided for @closeOthers.
  ///
  /// In zh, this message translates to:
  /// **'关闭其他'**
  String get closeOthers;

  /// No description provided for @closeP.
  ///
  /// In zh, this message translates to:
  /// **'关闭 {p0}'**
  String closeP(Object? p0);

  /// No description provided for @fileDoesNotExist.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在'**
  String get fileDoesNotExist;

  /// No description provided for @cannotInstallAllowFlitToInstallUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法安装：请先在系统设置里授予 Flit“安装未知应用”权限'**
  String get cannotInstallAllowFlitToInstallUnknown;

  /// No description provided for @installLocally.
  ///
  /// In zh, this message translates to:
  /// **'安装到本机'**
  String get installLocally;

  /// No description provided for @noApplicationCanOpenThisFile.
  ///
  /// In zh, this message translates to:
  /// **'没有能打开此文件的应用'**
  String get noApplicationCanOpenThisFile;

  /// No description provided for @openWith.
  ///
  /// In zh, this message translates to:
  /// **'用其他应用打开'**
  String get openWith;

  /// No description provided for @unableToShareThisFile.
  ///
  /// In zh, this message translates to:
  /// **'无法分享该文件'**
  String get unableToShareThisFile;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @linePPIssues.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 行 · {p1} 个问题'**
  String linePPIssues(Object? p0, Object? p1);

  /// No description provided for @quickFix.
  ///
  /// In zh, this message translates to:
  /// **'快速修复'**
  String get quickFix;

  /// No description provided for @completionItemExpiredTypeAgain.
  ///
  /// In zh, this message translates to:
  /// **'补全项已失效，请重新输入'**
  String get completionItemExpiredTypeAgain;

  /// No description provided for @problemsCurrentFile.
  ///
  /// In zh, this message translates to:
  /// **'问题 · 当前文件'**
  String get problemsCurrentFile;

  /// No description provided for @noProblems.
  ///
  /// In zh, this message translates to:
  /// **'暂无问题'**
  String get noProblems;

  /// No description provided for @linePColumnP.
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 行 · 第 {p1} 列'**
  String linePColumnP(Object? p0, Object? p1);

  /// No description provided for @syntaxHighlighting.
  ///
  /// In zh, this message translates to:
  /// **'语法高亮'**
  String get syntaxHighlighting;

  /// No description provided for @startingDartAnalyzer.
  ///
  /// In zh, this message translates to:
  /// **'正在启动 Dart 分析器…'**
  String get startingDartAnalyzer;

  /// No description provided for @dartAnalysisReady.
  ///
  /// In zh, this message translates to:
  /// **'Dart · 代码分析就绪'**
  String get dartAnalysisReady;

  /// No description provided for @dartBasicCompletion.
  ///
  /// In zh, this message translates to:
  /// **'Dart · 基础补全'**
  String get dartBasicCompletion;

  /// No description provided for @problemsP.
  ///
  /// In zh, this message translates to:
  /// **'问题 {p0}'**
  String problemsP(Object? p0);

  /// No description provided for @browseSharedStorageAndSelectFilesTo.
  ///
  /// In zh, this message translates to:
  /// **'浏览共享存储，选择需要复制到当前项目的文件。此浏览器仅用于导入文件。'**
  String get browseSharedStorageAndSelectFilesTo;

  /// No description provided for @unableToReadDirectoryP.
  ///
  /// In zh, this message translates to:
  /// **'无法读取目录： {p0}'**
  String unableToReadDirectoryP(Object? p0);

  /// No description provided for @pasteHere.
  ///
  /// In zh, this message translates to:
  /// **'粘贴到此处'**
  String get pasteHere;

  /// No description provided for @copiedPLongPressTheDestinationDirectory.
  ///
  /// In zh, this message translates to:
  /// **'已复制 {p0}，长按目标目录可粘贴'**
  String copiedPLongPressTheDestinationDirectory(Object? p0);

  /// No description provided for @cut.
  ///
  /// In zh, this message translates to:
  /// **'剪切'**
  String get cut;

  /// No description provided for @cutPLongPressTheDestinationDirectory.
  ///
  /// In zh, this message translates to:
  /// **'已剪切 {p0}，长按目标目录可粘贴'**
  String cutPLongPressTheDestinationDirectory(Object? p0);

  /// No description provided for @copiedPReturnToTheProjectAnd.
  ///
  /// In zh, this message translates to:
  /// **'已复制 {p0}，返回项目后长按目标目录可粘贴'**
  String copiedPReturnToTheProjectAnd(Object? p0);

  /// No description provided for @sharedStorageImportOnly.
  ///
  /// In zh, this message translates to:
  /// **'共享存储（仅导入）'**
  String get sharedStorageImportOnly;

  /// No description provided for @newItem.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get newItem;

  /// No description provided for @switchLocation.
  ///
  /// In zh, this message translates to:
  /// **'切换位置'**
  String get switchLocation;

  /// No description provided for @copyFromSharedStorage.
  ///
  /// In zh, this message translates to:
  /// **'从共享存储复制…'**
  String get copyFromSharedStorage;

  /// No description provided for @svgPreviewFromEditorBuffer.
  ///
  /// In zh, this message translates to:
  /// **'SVG 预览(内容来自编辑缓冲)'**
  String get svgPreviewFromEditorBuffer;

  /// No description provided for @emptyFile.
  ///
  /// In zh, this message translates to:
  /// **'空文件'**
  String get emptyFile;

  /// No description provided for @unableToRenderSvgContentIsNot.
  ///
  /// In zh, this message translates to:
  /// **'无法渲染该 SVG：内容不是有效的 SVG'**
  String get unableToRenderSvgContentIsNot;

  /// No description provided for @unableToRenderSvgP.
  ///
  /// In zh, this message translates to:
  /// **'无法渲染该 SVG：{p0}'**
  String unableToRenderSvgP(Object? p0);

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get redo;

  /// No description provided for @commitStagedChanges.
  ///
  /// In zh, this message translates to:
  /// **'提交已暂存的更改'**
  String get commitStagedChanges;

  /// No description provided for @commitMessage.
  ///
  /// In zh, this message translates to:
  /// **'提交消息'**
  String get commitMessage;

  /// No description provided for @showStagedDiff.
  ///
  /// In zh, this message translates to:
  /// **'显示已暂存的差异'**
  String get showStagedDiff;

  /// No description provided for @showUnstagedDiff.
  ///
  /// In zh, this message translates to:
  /// **'显示未暂存的差异'**
  String get showUnstagedDiff;

  /// No description provided for @markConflictResolvedStage.
  ///
  /// In zh, this message translates to:
  /// **'标记冲突已解决（暂存）'**
  String get markConflictResolvedStage;

  /// No description provided for @stageFile.
  ///
  /// In zh, this message translates to:
  /// **'暂存文件'**
  String get stageFile;

  /// No description provided for @unstage.
  ///
  /// In zh, this message translates to:
  /// **'取消暂存'**
  String get unstage;

  /// No description provided for @rollbackUnstagedChanges.
  ///
  /// In zh, this message translates to:
  /// **'回滚未暂存的更改'**
  String get rollbackUnstagedChanges;

  /// No description provided for @rollbackChanges.
  ///
  /// In zh, this message translates to:
  /// **'回滚更改？'**
  String get rollbackChanges;

  /// No description provided for @discardUnstagedChangesInPStagedChanges.
  ///
  /// In zh, this message translates to:
  /// **'将丢弃 {p0} 未暂存的更改，已暂存的内容保留。此操作无法撤销。'**
  String discardUnstagedChangesInPStagedChanges(Object? p0);

  /// No description provided for @branches.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get branches;

  /// No description provided for @createAndSwitchBranch.
  ///
  /// In zh, this message translates to:
  /// **'新建并切换分支'**
  String get createAndSwitchBranch;

  /// No description provided for @newBranch.
  ///
  /// In zh, this message translates to:
  /// **'新建分支'**
  String get newBranch;

  /// No description provided for @branchName.
  ///
  /// In zh, this message translates to:
  /// **'分支名称'**
  String get branchName;

  /// No description provided for @commitHistory.
  ///
  /// In zh, this message translates to:
  /// **'提交历史'**
  String get commitHistory;

  /// No description provided for @remoteOrigin.
  ///
  /// In zh, this message translates to:
  /// **'远程仓库 · origin'**
  String get remoteOrigin;

  /// No description provided for @commitAuthorThisRepository.
  ///
  /// In zh, this message translates to:
  /// **'提交者信息（当前仓库）'**
  String get commitAuthorThisRepository;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @detachedHead.
  ///
  /// In zh, this message translates to:
  /// **'游离 HEAD'**
  String get detachedHead;

  /// No description provided for @refreshVersionControlStatus.
  ///
  /// In zh, this message translates to:
  /// **'刷新版本控制状态'**
  String get refreshVersionControlStatus;

  /// No description provided for @repositorySettings.
  ///
  /// In zh, this message translates to:
  /// **'仓库设置'**
  String get repositorySettings;

  /// No description provided for @remotes.
  ///
  /// In zh, this message translates to:
  /// **'远程仓库'**
  String get remotes;

  /// No description provided for @commitAuthor.
  ///
  /// In zh, this message translates to:
  /// **'提交者信息'**
  String get commitAuthor;

  /// No description provided for @pull.
  ///
  /// In zh, this message translates to:
  /// **'拉取'**
  String get pull;

  /// No description provided for @push.
  ///
  /// In zh, this message translates to:
  /// **'推送'**
  String get push;

  /// No description provided for @operationInProgressViewProgressOrStop.
  ///
  /// In zh, this message translates to:
  /// **'操作进行中，可在终端查看进度或停止。'**
  String get operationInProgressViewProgressOrStop;

  /// No description provided for @thisProjectHasNoGitRepositoryYet.
  ///
  /// In zh, this message translates to:
  /// **'此项目尚未创建 Git 仓库。'**
  String get thisProjectHasNoGitRepositoryYet;

  /// No description provided for @initializeRepository.
  ///
  /// In zh, this message translates to:
  /// **'初始化仓库'**
  String get initializeRepository;

  /// No description provided for @noLocalChanges.
  ///
  /// In zh, this message translates to:
  /// **'没有本地更改'**
  String get noLocalChanges;

  /// No description provided for @conflictsFoundResolveThemInTheEditor.
  ///
  /// In zh, this message translates to:
  /// **'存在冲突：编辑文件解决冲突后，逐个暂存。'**
  String get conflictsFoundResolveThemInTheEditor;

  /// No description provided for @conflicts.
  ///
  /// In zh, this message translates to:
  /// **'冲突'**
  String get conflicts;

  /// No description provided for @untracked.
  ///
  /// In zh, this message translates to:
  /// **'未跟踪'**
  String get untracked;

  /// No description provided for @stagedWithAdditionalUnstagedChanges.
  ///
  /// In zh, this message translates to:
  /// **'已暂存，另有未暂存更改'**
  String get stagedWithAdditionalUnstagedChanges;

  /// No description provided for @staged.
  ///
  /// In zh, this message translates to:
  /// **'已暂存'**
  String get staged;

  /// No description provided for @stageAllChanges.
  ///
  /// In zh, this message translates to:
  /// **'暂存所有更改'**
  String get stageAllChanges;

  /// No description provided for @commitChangesP.
  ///
  /// In zh, this message translates to:
  /// **'提交更改 · {p0}'**
  String commitChangesP(Object? p0);

  /// No description provided for @signOutOfGithub.
  ///
  /// In zh, this message translates to:
  /// **'退出 GitHub 登录？'**
  String get signOutOfGithub;

  /// No description provided for @removeGithubComCredentialsFromThisDevice.
  ///
  /// In zh, this message translates to:
  /// **'将移除此设备上 github.com 的登录凭据。'**
  String get removeGithubComCredentialsFromThisDevice;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get signOut;

  /// No description provided for @ghIsNotInstalledCompleteTheFlutter.
  ///
  /// In zh, this message translates to:
  /// **'未安装 gh · 在开发环境页完成 Flutter 阶段安装后可用'**
  String get ghIsNotInstalledCompleteTheFlutter;

  /// No description provided for @notSignedInSignInToClone.
  ///
  /// In zh, this message translates to:
  /// **'未登录 · 私有仓库的克隆与推送需要登录'**
  String get notSignedInSignInToClone;

  /// No description provided for @signedInGitCredentialHelperConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已登录 · git 凭据助手已接入'**
  String get signedInGitCredentialHelperConfigured;

  /// No description provided for @githubAccount.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 账户'**
  String get githubAccount;

  /// No description provided for @working.
  ///
  /// In zh, this message translates to:
  /// **'正在处理…'**
  String get working;

  /// No description provided for @waitingForBrowserAuthorization.
  ///
  /// In zh, this message translates to:
  /// **'等待浏览器授权…'**
  String get waitingForBrowserAuthorization;

  /// No description provided for @signedInP.
  ///
  /// In zh, this message translates to:
  /// **'已登录 · {p0}'**
  String signedInP(Object? p0);

  /// No description provided for @viewAuthorizationCode.
  ///
  /// In zh, this message translates to:
  /// **'查看授权码'**
  String get viewAuthorizationCode;

  /// No description provided for @signIn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get signIn;

  /// No description provided for @ghIsNotInstalledCompleteTheFlutter708.
  ///
  /// In zh, this message translates to:
  /// **'尚未安装 gh，请先在开发环境页完成 Flutter 阶段安装'**
  String get ghIsNotInstalledCompleteTheFlutter708;

  /// No description provided for @githubSignIn.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 登录'**
  String get githubSignIn;

  /// No description provided for @signInCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消登录'**
  String get signInCancelled;

  /// No description provided for @signInIncompleteExitCodePP.
  ///
  /// In zh, this message translates to:
  /// **'登录未完成（退出码 {p0}）{p1}'**
  String signInIncompleteExitCodePP(Object? p0, Object? p1);

  /// No description provided for @signInFailedP.
  ///
  /// In zh, this message translates to:
  /// **'登录失败：{p0}'**
  String signInFailedP(Object? p0);

  /// No description provided for @githubSignOut.
  ///
  /// In zh, this message translates to:
  /// **'退出 GitHub 登录'**
  String get githubSignOut;

  /// No description provided for @githubSignOutIncompleteExitCodeP.
  ///
  /// In zh, this message translates to:
  /// **'退出 GitHub 登录未完成（退出码 {p0}）'**
  String githubSignOutIncompleteExitCodeP(Object? p0);

  /// No description provided for @githubSignOutFailedP.
  ///
  /// In zh, this message translates to:
  /// **'退出 GitHub 登录失败：{p0}'**
  String githubSignOutFailedP(Object? p0);

  /// No description provided for @unableToOpenBrowserVisitGithubCom.
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器，请访问 github.com/login/device'**
  String get unableToOpenBrowserVisitGithubCom;

  /// No description provided for @failedToOpenBrowserP.
  ///
  /// In zh, this message translates to:
  /// **'打开浏览器失败：{p0}'**
  String failedToOpenBrowserP(Object? p0);

  /// No description provided for @signInToGithub.
  ///
  /// In zh, this message translates to:
  /// **'登录 GitHub'**
  String get signInToGithub;

  /// No description provided for @copyTheDeviceCodeAndAuthorizeIn.
  ///
  /// In zh, this message translates to:
  /// **'复制设备授权码后，在浏览器中授权。完成后自动更新登录状态。'**
  String get copyTheDeviceCodeAndAuthorizeIn;

  /// No description provided for @later.
  ///
  /// In zh, this message translates to:
  /// **'稍后处理'**
  String get later;

  /// No description provided for @cancelSignIn.
  ///
  /// In zh, this message translates to:
  /// **'取消登录'**
  String get cancelSignIn;

  /// No description provided for @copyAndOpenBrowser.
  ///
  /// In zh, this message translates to:
  /// **'复制并打开浏览器'**
  String get copyAndOpenBrowser;

  /// No description provided for @openTheGitRepositoryRootToUse.
  ///
  /// In zh, this message translates to:
  /// **'请打开 Git 仓库根目录后使用版本控制'**
  String get openTheGitRepositoryRootToUse;

  /// No description provided for @aTaskIsRunningStopItBefore.
  ///
  /// In zh, this message translates to:
  /// **'当前有任务正在运行，请先结束后再执行 Git 操作'**
  String get aTaskIsRunningStopItBefore;

  /// No description provided for @saveFailedGitOperationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，已取消 Git 操作'**
  String get saveFailedGitOperationCancelled;

  /// No description provided for @pIncompleteExitCodePSeeTerminal.
  ///
  /// In zh, this message translates to:
  /// **'{p0} 未完成（退出码 {p1}），请查看终端输出'**
  String pIncompleteExitCodePSeeTerminal(Object? p0, Object? p1);

  /// No description provided for @enterACommitMessage.
  ///
  /// In zh, this message translates to:
  /// **'请输入提交消息'**
  String get enterACommitMessage;

  /// No description provided for @resolveConflictsAndStageTheFilesFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先解决冲突并暂存文件'**
  String get resolveConflictsAndStageTheFilesFirst;

  /// No description provided for @stageTheFilesToCommitFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先暂存需要提交的文件'**
  String get stageTheFilesToCommitFirst;

  /// No description provided for @commit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get commit;

  /// No description provided for @theCurrentFileStatusDoesNotSupport.
  ///
  /// In zh, this message translates to:
  /// **'当前文件状态不支持回滚'**
  String get theCurrentFileStatusDoesNotSupport;

  /// No description provided for @commitOrRollbackChangesBeforeSwitchingBranches.
  ///
  /// In zh, this message translates to:
  /// **'请先提交或回滚当前更改，再切换分支'**
  String get commitOrRollbackChangesBeforeSwitchingBranches;

  /// No description provided for @switchBranch.
  ///
  /// In zh, this message translates to:
  /// **'切换分支'**
  String get switchBranch;

  /// No description provided for @commitOrRollbackChangesBeforePulling.
  ///
  /// In zh, this message translates to:
  /// **'请先提交或回滚当前更改，再拉取'**
  String get commitOrRollbackChangesBeforePulling;

  /// No description provided for @thisBranchHasNoUpstreamPushAnd.
  ///
  /// In zh, this message translates to:
  /// **'当前分支未设置上游分支，请先推送并关联远程分支'**
  String get thisBranchHasNoUpstreamPushAnd;

  /// No description provided for @switchToABranchAndCreateA.
  ///
  /// In zh, this message translates to:
  /// **'请先切换到分支并创建提交'**
  String get switchToABranchAndCreateA;

  /// No description provided for @resolveConflictsFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先解决冲突'**
  String get resolveConflictsFirst;

  /// No description provided for @firstPushRequiresARemoteConfigureOrigin.
  ///
  /// In zh, this message translates to:
  /// **'首次推送需要一个远程仓库，请在「远程仓库」中配置 origin'**
  String get firstPushRequiresARemoteConfigureOrigin;

  /// No description provided for @firstPush.
  ///
  /// In zh, this message translates to:
  /// **'首次推送'**
  String get firstPush;

  /// No description provided for @enterAValidRepositoryUrl.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的仓库地址'**
  String get enterAValidRepositoryUrl;

  /// No description provided for @enterTheCommitAuthorNameAndEmail.
  ///
  /// In zh, this message translates to:
  /// **'请填写提交者名称和邮箱'**
  String get enterTheCommitAuthorNameAndEmail;

  /// No description provided for @invalidSourcePath.
  ///
  /// In zh, this message translates to:
  /// **'源路径无效'**
  String get invalidSourcePath;

  /// No description provided for @filesCannotBeMovedOutsideTheirProject.
  ///
  /// In zh, this message translates to:
  /// **'不能将文件移出它所属的项目目录'**
  String get filesCannotBeMovedOutsideTheirProject;

  /// No description provided for @destinationMustBeInsideTheCurrentProject.
  ///
  /// In zh, this message translates to:
  /// **'目标必须位于当前项目目录内'**
  String get destinationMustBeInsideTheCurrentProject;

  /// No description provided for @cannotCopyOrMoveADirectoryInto.
  ///
  /// In zh, this message translates to:
  /// **'不能将目录复制或移动到它自己内部'**
  String get cannotCopyOrMoveADirectoryInto;

  /// No description provided for @onlyEntriesInsideTheCurrentProjectCan.
  ///
  /// In zh, this message translates to:
  /// **'只能删除当前项目目录中的条目'**
  String get onlyEntriesInsideTheCurrentProjectCan;

  /// No description provided for @invalidName.
  ///
  /// In zh, this message translates to:
  /// **'名称无效'**
  String get invalidName;

  /// No description provided for @renameIsOnlyAllowedWithinTheCurrent.
  ///
  /// In zh, this message translates to:
  /// **'只能在当前项目目录内重命名'**
  String get renameIsOnlyAllowedWithinTheCurrent;

  /// No description provided for @filesAndDirectoriesCanOnlyBeCreated.
  ///
  /// In zh, this message translates to:
  /// **'只能在当前项目目录中创建文件或目录'**
  String get filesAndDirectoriesCanOnlyBeCreated;

  /// No description provided for @operationFailedExitCodeP.
  ///
  /// In zh, this message translates to:
  /// **'操作失败（退出码 {p0}）'**
  String operationFailedExitCodeP(Object? p0);

  /// No description provided for @operationFailedP.
  ///
  /// In zh, this message translates to:
  /// **'操作失败：{p0}'**
  String operationFailedP(Object? p0);

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @unauthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get unauthorized;

  /// No description provided for @offline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get offline;

  /// No description provided for @authenticating.
  ///
  /// In zh, this message translates to:
  /// **'认证中'**
  String get authenticating;

  /// No description provided for @localDevice.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get localDevice;

  /// No description provided for @localDeviceP.
  ///
  /// In zh, this message translates to:
  /// **'本机 · {p0}'**
  String localDeviceP(Object? p0);

  /// No description provided for @lanP.
  ///
  /// In zh, this message translates to:
  /// **'局域网 {p0}'**
  String lanP(Object? p0);

  /// No description provided for @lan.
  ///
  /// In zh, this message translates to:
  /// **'局域网'**
  String get lan;

  /// No description provided for @failedToReadDevices.
  ///
  /// In zh, this message translates to:
  /// **'读取设备失败'**
  String get failedToReadDevices;

  /// No description provided for @adbDidNotReturnADeviceList.
  ///
  /// In zh, this message translates to:
  /// **'ADB 未返回设备列表：{p0}'**
  String adbDidNotReturnADeviceList(Object? p0);

  /// No description provided for @backgroundExecutionAndNotifications.
  ///
  /// In zh, this message translates to:
  /// **'后台运行与通知'**
  String get backgroundExecutionAndNotifications;

  /// No description provided for @setupAndBuildsMayTakeAWhile.
  ///
  /// In zh, this message translates to:
  /// **'初始化和构建可能耗时较长，建议开启：'**
  String get setupAndBuildsMayTakeAWhile;

  /// No description provided for @theForegroundServiceOnlyShowsGeneralTask.
  ///
  /// In zh, this message translates to:
  /// **'前台服务仅显示通用运行状态，开关在系统通知设置中，可稍后在「设置 → 后台与通知」里再调。'**
  String get theForegroundServiceOnlyShowsGeneralTask;

  /// No description provided for @continueAction.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueAction;

  /// No description provided for @allowSharedStorageAccess.
  ///
  /// In zh, this message translates to:
  /// **'允许访问共享存储？'**
  String get allowSharedStorageAccess;

  /// No description provided for @withPermissionFlitCanAccessSharedStorage.
  ///
  /// In zh, this message translates to:
  /// **'授权后，Flit 可以访问共享存储中的文件。你也可以暂不授权，继续使用应用内项目目录；应用内文件不会显示在普通文件管理器中，卸载 Flit 时会一并删除。'**
  String get withPermissionFlitCanAccessSharedStorage;

  /// No description provided for @notNow.
  ///
  /// In zh, this message translates to:
  /// **'暂不授权'**
  String get notNow;

  /// No description provided for @grantAccess.
  ///
  /// In zh, this message translates to:
  /// **'继续授权'**
  String get grantAccess;

  /// No description provided for @sharedStoragePermissionDeniedAppPrivateProjects.
  ///
  /// In zh, this message translates to:
  /// **'未授予共享存储权限，仍可使用应用内项目目录'**
  String get sharedStoragePermissionDeniedAppPrivateProjects;

  /// No description provided for @gitCommandFailedP.
  ///
  /// In zh, this message translates to:
  /// **'Git 执行失败（{p0}）'**
  String gitCommandFailedP(Object? p0);

  /// No description provided for @gitUnavailableCheckTheDevelopmentEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'Git 不可用，请检查开发环境'**
  String get gitUnavailableCheckTheDevelopmentEnvironment;

  /// No description provided for @theProjectIsInsideAParentGit.
  ///
  /// In zh, this message translates to:
  /// **'当前项目位于上级 Git 仓库中，请打开仓库根目录后使用版本控制'**
  String get theProjectIsInsideAParentGit;

  /// No description provided for @thisFileIsUntrackedStageItTo.
  ///
  /// In zh, this message translates to:
  /// **'此文件尚未跟踪，暂存后可查看完整差异。'**
  String get thisFileIsUntrackedStageItTo;

  /// No description provided for @noTextDiffPossiblyABinaryFile.
  ///
  /// In zh, this message translates to:
  /// **'没有文本差异（可能是二进制文件或文件模式变化）。'**
  String get noTextDiffPossiblyABinaryFile;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @refreshVersionsLater.
  ///
  /// In zh, this message translates to:
  /// **'可稍后点击刷新重试'**
  String get refreshVersionsLater;

  /// No description provided for @showingPreviousCatalog.
  ///
  /// In zh, this message translates to:
  /// **'暂时显示上次获取的目录'**
  String get showingPreviousCatalog;

  /// No description provided for @currentVersionSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 当前 {p0}'**
  String currentVersionSuffix(Object? p0);

  /// No description provided for @repairCountSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · {p0} 个需修复'**
  String repairCountSuffix(Object? p0);

  /// No description provided for @retryBuildVerb.
  ///
  /// In zh, this message translates to:
  /// **'重新尝试一次'**
  String get retryBuildVerb;

  /// No description provided for @continueBuildVerb.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueBuildVerb;

  /// No description provided for @startingEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在启动…'**
  String get startingEllipsis;

  /// No description provided for @prereleaseSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 预发布'**
  String get prereleaseSuffix;

  /// No description provided for @cannotRun.
  ///
  /// In zh, this message translates to:
  /// **'无法运行'**
  String get cannotRun;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get running;

  /// No description provided for @exited.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get exited;

  /// No description provided for @switchVersion.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get switchVersion;

  /// No description provided for @requestFailed.
  ///
  /// In zh, this message translates to:
  /// **'✗ 请求失败'**
  String get requestFailed;

  /// No description provided for @currentSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 当前'**
  String get currentSuffix;

  /// No description provided for @installed.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get installed;

  /// No description provided for @installationIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'安装不完整'**
  String get installationIncomplete;

  /// No description provided for @replaceSharedToolsSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 替换共用工具'**
  String get replaceSharedToolsSuffix;

  /// No description provided for @needsRepair.
  ///
  /// In zh, this message translates to:
  /// **'需修复'**
  String get needsRepair;

  /// No description provided for @compilationFailed.
  ///
  /// In zh, this message translates to:
  /// **'编译失败'**
  String get compilationFailed;

  /// No description provided for @unstaged.
  ///
  /// In zh, this message translates to:
  /// **'未暂存'**
  String get unstaged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
