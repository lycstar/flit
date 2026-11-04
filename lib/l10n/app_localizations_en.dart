// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addWebSupport => 'Add Web support?';

  @override
  String get addWebSupportDescription =>
      'This project has no web directory. Flit will run flutter create --platforms web . to add Web support before starting the preview.';

  @override
  String get addAndRun => 'Add and Run';

  @override
  String get recommended => 'Recommended';

  @override
  String get space => 'Space';

  @override
  String get enter => 'Enter';

  @override
  String get backspace => 'Backspace';

  @override
  String get capsLock => 'Caps Lock';

  @override
  String environmentCommandFailedExitCodeP(Object? p0) {
    return 'Environment command failed (exit code $p0)';
  }

  @override
  String readFailedP(Object? p0) {
    return 'Read failed: $p0';
  }

  @override
  String get environmentVariables => 'Environment Variables';

  @override
  String get refreshSnapshot => 'Refresh snapshot';

  @override
  String get searchVariablesOrValues => 'Search variables or values';

  @override
  String get retry => 'Retry';

  @override
  String get noMatchingVariables => 'No matching variables';

  @override
  String get readOnlyEnvironmentSnapshotForNewTasks =>
      'Read-only environment snapshot for new tasks\nDoes not include temporary exports in terminals. Expand a variable to view its full value.';

  @override
  String searchResultsP(Object? p0) {
    return 'Search results · $p0';
  }

  @override
  String get toolchains => 'Toolchains';

  @override
  String get pathCommandLookupOrder => 'PATH · Command lookup order';

  @override
  String get commandSearchPaths => 'Command search paths';

  @override
  String pDirectoriesInLookupOrder(Object? p0) {
    return '$p0 directories · In lookup order';
  }

  @override
  String get currentDirectory => '(Current directory)';

  @override
  String get directoriesAndCaches => 'Directories and caches';

  @override
  String otherVariablesP(Object? p0) {
    return 'Other variables · $p0';
  }

  @override
  String get copyValue => 'Copy value';

  @override
  String get variableValueCopied => 'Variable value copied';

  @override
  String get empty => '(Empty)';

  @override
  String get allowInstallationFromUnknownSourcesThenTap =>
      'Allow installation from unknown sources, then tap Install again';

  @override
  String downloadCompleteP(Object? p0) {
    return 'Download complete: $p0';
  }

  @override
  String downloadFailedP(Object? p0) {
    return 'Download failed: $p0';
  }

  @override
  String get appUpdates => 'App Updates';

  @override
  String get compareThisBuildWithGithubReleasesOr =>
      'Compare this build with GitHub releases, or download a previous version.';

  @override
  String failedToFetchReleasesP(Object? p0) {
    return 'Failed to fetch releases: $p0';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get localBuildVersionComparisonUnavailable =>
      'Local build; version comparison unavailable';

  @override
  String get upToDate => 'Up to date';

  @override
  String updateAvailableP(Object? p0) {
    return 'Update available: $p0';
  }

  @override
  String get currentBuild => 'Current build';

  @override
  String get latestRelease => 'Latest release';

  @override
  String get noAssets => 'No assets';

  @override
  String get downloadAndInstall => 'Download and install';

  @override
  String get download => 'Download';

  @override
  String get systemMonospace => 'System monospace';

  @override
  String get settingsStorageUnavailable => 'Settings storage unavailable';

  @override
  String get checking => 'Checking…';

  @override
  String failedToSaveOrLoadSettingsP(Object? p0) {
    return 'Failed to save or load settings: $p0';
  }

  @override
  String get unableToRequestPermissionYouCanChange =>
      'Unable to request permission. You can change it later in system app settings.';

  @override
  String get proxySettingsUpdatedAppliesToNewTerminals =>
      'Proxy settings updated; applies to new terminals and tasks';

  @override
  String get settings => 'Settings';

  @override
  String get ideSettings => 'IDE Settings';

  @override
  String get configureDevelopmentToolsDeviceConnectionsAndThe =>
      'Configure development tools, device connections, and the editor.';

  @override
  String get general => 'General';

  @override
  String get account => 'Account';

  @override
  String get developmentEnvironment => 'Development Environment';

  @override
  String get viewToolchainPathsAndCommandEnvironmentSnapshots =>
      'View toolchain paths and command environment snapshots';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String get wirelessDebuggingPairingAndAuthorization =>
      'Wireless debugging · Pairing and authorization';

  @override
  String get useSystemProxy => 'Use system proxy';

  @override
  String get noSystemProxyDetectedItWillBe =>
      'No system proxy detected; it will be used when available';

  @override
  String get backgroundAndNotifications => 'Background and Notifications';

  @override
  String get foregroundService => 'Foreground service';

  @override
  String get showBuildAndTaskStatusInA =>
      'Show build and task status in a persistent notification';

  @override
  String get backgroundExecution => 'Background execution';

  @override
  String get ignoreBatteryOptimizationToReduceBackgroundTask =>
      'Ignore battery optimization to reduce background task interruptions';

  @override
  String get editorAndTerminal => 'Editor and Terminal';

  @override
  String get editorSettings => 'Editor Settings';

  @override
  String get fontColorSchemeSoftWraps => 'Font · Color scheme · Soft wraps';

  @override
  String get terminalSettings => 'Terminal Settings';

  @override
  String get pinchToZoomFontSizeMonospaceFont =>
      'Pinch to zoom · Font size · Monospace font · Line height';

  @override
  String get aboutFlit => 'About Flit';

  @override
  String get checkForUpdatesDownloadPreviousVersions =>
      'Check for updates · Download previous versions';

  @override
  String get buildCommit => 'Build commit';

  @override
  String get platform => 'Platform';

  @override
  String get enabled => 'Enabled';

  @override
  String get denied => 'Denied';

  @override
  String get disabled => 'Disabled';

  @override
  String get allowed => 'Allowed';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get flutterProject => 'Flutter project';

  @override
  String get dartProject => 'Dart project';

  @override
  String get folder => 'Folder';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get nameCannotContainPathSeparators =>
      'Name cannot contain path separators';

  @override
  String get nameCannotBeOr => 'Name cannot be . or ..';

  @override
  String get justNow => 'Just now';

  @override
  String pMinutesAgo(Object? p0) {
    return '$p0 minutes ago';
  }

  @override
  String pHoursAgo(Object? p0) {
    return '$p0 hours ago';
  }

  @override
  String pDaysAgo(Object? p0) {
    return '$p0 days ago';
  }

  @override
  String get projectDirectoryIsNotReadable =>
      'Project directory is not readable';

  @override
  String get aToolchainTaskIsRunningWaitBefore =>
      'A toolchain task is running. Wait before opening a project.';

  @override
  String get closeThisProjectBeforeRenamingOrDeleting =>
      'Close this project before renaming or deleting it';

  @override
  String get whereAreProjectsStored => 'Where are projects stored?';

  @override
  String projectDirectoryP(Object? p0) {
    return 'Project directory\n$p0\n\n';
  }

  @override
  String get uninstallingTheAppOrClearingItsData =>
      'Uninstalling the app or clearing its data also deletes projects. Back up using:\n';

  @override
  String get pushToGithubFromVersionControl =>
      '• Push to GitHub from Version Control\n';

  @override
  String get openFilesFlitProjectsAndCopyThe =>
      '• Open Files → Flit Projects and copy the directory to shared storage or another location\n';

  @override
  String get longPressAFileInTheEditor =>
      '• Long-press a file in the editor tree → Share';

  @override
  String get gotIt => 'Got it';

  @override
  String deleteProjectP(Object? p0) {
    return 'Delete project “$p0”?';
  }

  @override
  String get theDirectoryAndAllItsFilesWill =>
      'The directory and all its files will be permanently deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get cloneProject => 'Clone Project';

  @override
  String get createProject => 'Create Project';

  @override
  String get clone => 'Clone';

  @override
  String get create => 'Create';

  @override
  String pPSucceeded(Object? p0, Object? p1) {
    return '✓ $p0: $p1 succeeded';
  }

  @override
  String pCancelled(Object? p0) {
    return '$p0 cancelled';
  }

  @override
  String get cloneFailedSignInToGithubFirst =>
      'Clone failed: sign in to GitHub first for private repositories (Clone → GitHub Account → Sign In)';

  @override
  String pFailedExitCodePSeeTerminal(Object? p0, Object? p1) {
    return '✗ $p0 failed (exit code $p1); see terminal output';
  }

  @override
  String get newProject => 'New Project';

  @override
  String get cloneRepository => 'Clone Repository';

  @override
  String get projectsAreStoredInTheAppAnd =>
      'Projects are stored in the app and deleted on uninstall · Backup options';

  @override
  String get checkingDevelopmentEnvironment =>
      'Checking development environment';

  @override
  String get openDevelopmentEnvironmentForDetails =>
      'Open Development Environment for details.';

  @override
  String get viewDevelopmentEnvironment => 'View Development Environment';

  @override
  String get developmentEnvironmentIsNotReady =>
      'Development environment is not ready';

  @override
  String get yourProjectsWillAppearHereAfterSetup =>
      'Your projects will appear here after setup';

  @override
  String get setUpDevelopmentEnvironment => 'Set Up Development Environment';

  @override
  String get failedToReadProjectDirectory => 'Failed to read project directory';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get createAProjectOrCloneAGit =>
      'Create a project or clone a Git repository';

  @override
  String projectsP(Object? p0) {
    return 'Projects · $p0';
  }

  @override
  String get more => 'More';

  @override
  String get rename => 'Rename';

  @override
  String get renameProject => 'Rename Project';

  @override
  String get projectDirectoryName => 'Project directory name';

  @override
  String get ok => 'OK';

  @override
  String pAlreadyExistsChooseAnotherDirectoryName(Object? p0) {
    return '$p0 already exists. Choose another directory name.';
  }

  @override
  String get unableToCheckDestinationCheckTheDevelopment =>
      'Unable to check destination. Check the development environment and retry.';

  @override
  String clonePreflightFailedP(Object? p0) {
    return 'Clone preflight failed: $p0';
  }

  @override
  String get getFromVersionControl => 'Get from Version Control';

  @override
  String get cloneARemoteRepositoryToLocalStorage =>
      'Clone a remote repository to local storage, then open the project.';

  @override
  String get repository => 'Repository';

  @override
  String get repositoryUrl => 'Repository URL';

  @override
  String get directoryNameOptional => 'Directory name (optional)';

  @override
  String get leaveEmptyToUseTheRepositoryName =>
      'Leave empty to use the repository name';

  @override
  String get branchOptional => 'Branch (optional)';

  @override
  String get leaveEmptyToUseTheRemoteDefault =>
      'Leave empty to use the remote default branch';

  @override
  String get shallowClone => 'Shallow clone';

  @override
  String get fetchOnlyTheLatestCommitUseGit =>
      'Fetch only the latest commit. Use git fetch --unshallow to get the full history.';

  @override
  String get clonePreflight => 'Clone preflight';

  @override
  String get signInToGithubBeforeCloningA =>
      'Sign in to GitHub before cloning a private repository.';

  @override
  String get ready => 'Ready';

  @override
  String get gitNotFoundCheckItsInstallationAnd =>
      'Git not found. Check its installation and PATH.';

  @override
  String unableToRunP(Object? p0) {
    return 'Unable to run: $p0';
  }

  @override
  String get location => 'Location';

  @override
  String get startWithALowercaseLetterUseOnly =>
      'Start with a lowercase letter; use only lowercase letters, numbers, and underscores';

  @override
  String get dartReservedWordsAndToolNamesCannot =>
      'Dart reserved words and tool names cannot be used';

  @override
  String get useAReverseDomainNameSuchAs =>
      'Use a reverse domain name, such as com.example';

  @override
  String projectPAlreadyExistsChooseAnotherName(Object? p0) {
    return 'Project $p0 already exists. Choose another name.';
  }

  @override
  String get unableToCheckDestinationCheckTheDevelopment146 =>
      'Unable to check destination. Check the development environment and retry.';

  @override
  String projectPreflightFailedP(Object? p0) {
    return 'Project preflight failed: $p0';
  }

  @override
  String get projectConfiguration => 'Project Configuration';

  @override
  String chooseTheProjectTypeNameAndTarget(Object? p0) {
    return 'Choose the project type, name, and target platforms. Open it after creation.\nLocation: $p0';
  }

  @override
  String get projectDetails => 'Project Details';

  @override
  String get projectName => 'Project name';

  @override
  String get lowercaseLettersNumbersAndUnderscores =>
      'Lowercase letters, numbers, and underscores';

  @override
  String get organizationOptional => 'Organization (optional)';

  @override
  String get targetPlatforms => 'Target Platforms';

  @override
  String get projectTemplate => 'Project template';

  @override
  String get consoleApplication => 'Console application';

  @override
  String get dartPackage => 'Dart package';

  @override
  String get serverApplication => 'Server application';

  @override
  String get runConsoleProjectsUsingDartRunIn =>
      'Run console projects using dart run in the terminal.';

  @override
  String get selectAtLeastOnePlatform => 'Select at least one platform.';

  @override
  String get buildAndroidAndPreviewWebOnThis =>
      'Build Android and preview Web on this device. Other platforms require their respective operating systems.';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get emptyProject => 'Empty project';

  @override
  String get excludeTheCounterExample => 'Exclude the counter example';

  @override
  String get androidSourceLanguage => 'Android source language';

  @override
  String get projectDescriptionOptional => 'Project description (optional)';

  @override
  String get projectPreflight => 'Project preflight';

  @override
  String get checkAgain => 'Check Again';

  @override
  String get buildApkDebug => 'Build APK (Debug)';

  @override
  String get buildApkRelease => 'Build APK (Release)';

  @override
  String get buildWebRelease => 'Build Web (Release)';

  @override
  String get getDependencies => 'Get Dependencies';

  @override
  String get upgradeDependencies => 'Upgrade Dependencies';

  @override
  String get checkOutdatedDependencies => 'Check Outdated Dependencies';

  @override
  String get cleanBuildOutputs => 'Clean Build Outputs';

  @override
  String get analyzeCode => 'Analyze Code';

  @override
  String get runTests => 'Run Tests';

  @override
  String get environmentDiagnostics => 'Environment Diagnostics';

  @override
  String get projectIsClosed => 'Project is closed';

  @override
  String get theDevelopmentEnvironmentIsBeingInstalledOr =>
      'The development environment is being installed or switched. Please wait.';

  @override
  String get aGitOperationIsInProgressPlease =>
      'A Git operation is in progress. Please wait.';

  @override
  String get saveFailedPleaseRetry => 'Save failed. Please retry.';

  @override
  String get aTaskIsAlreadyStartingPleaseWait =>
      'A task is already starting. Please wait.';

  @override
  String targetPIsNotConnected(Object? p0) {
    return 'Target $p0 is not connected';
  }

  @override
  String get runDart => 'Run Dart';

  @override
  String get compileExecutable => 'Compile Executable';

  @override
  String get waitForTheBuildOrDependencyUpdate =>
      'Wait for the build or dependency update before hot reload';

  @override
  String get filesAreSyncingPleaseRetryShortly =>
      'Files are syncing. Please retry shortly.';

  @override
  String get invalidFilePath => 'Invalid file path';

  @override
  String get fileIsUnreadableOrOutsideTheProject =>
      'File is unreadable or outside the project directory';

  @override
  String get aFileIsAlreadyOpenAtThe =>
      'A file is already open at the destination path';

  @override
  String get saveFailedFileOperationCancelled =>
      'Save failed; file operation cancelled';

  @override
  String fileDoesNotExistP(Object? p0) {
    return 'File does not exist: $p0';
  }

  @override
  String unableToReloadPTheFileWas(Object? p0) {
    return 'Unable to reload $p0. The file was closed; reopen it from the Project tool window.';
  }

  @override
  String unableToReadProjectDirectoryP(Object? p0) {
    return 'Unable to read project directory: $p0';
  }

  @override
  String get fileIsOutsideTheCurrentProject =>
      'File is outside the current project';

  @override
  String get noFilesToPaste => 'No files to paste';

  @override
  String get filesCanOnlyBeMovedWithinThe =>
      'Files can only be moved within the current project. Use Copy instead.';

  @override
  String get aGitOperationIsRunningWaitOr =>
      'A Git operation is running. Wait or stop it in the terminal.';

  @override
  String get aFileOperationIsRunningWaitBefore =>
      'A file operation is running. Wait before switching projects.';

  @override
  String get failedToSaveTheCurrentProjectRetry =>
      'Failed to save the current project. Retry before switching projects.';

  @override
  String fontSizeAppliedButSavingFailedP(Object? p0) {
    return 'Font size applied, but saving failed: $p0';
  }

  @override
  String get terminalAppearance => 'Terminal Appearance';

  @override
  String get closeTerminalSettings => 'Close terminal settings';

  @override
  String get collapseTerminal => 'Collapse terminal';

  @override
  String get expandTerminal => 'Expand terminal';

  @override
  String get stopping => 'Stopping…';

  @override
  String get stopCurrentTask => 'Stop current task';

  @override
  String get terminateAndClose => 'Terminate and Close';

  @override
  String get close => 'Close';

  @override
  String get terminalFontAndZoom => 'Terminal Font and Zoom';

  @override
  String get clearTerminal => 'Clear Terminal';

  @override
  String get exitFullScreen => 'Exit Full Screen';

  @override
  String get fullScreenTerminal => 'Full Screen Terminal';

  @override
  String get paste => 'Paste';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get selectAll => 'Select All';

  @override
  String closePSession(Object? p0) {
    return 'Close $p0 session';
  }

  @override
  String get developmentEnvironmentIsNotReadyCompleteSetup =>
      'Development environment is not ready. Complete setup first.';

  @override
  String get aTaskCannotBeTheDefaultShell =>
      'A task cannot be the default shell';

  @override
  String pRequiresExclusiveProjectAccessStopIt(Object? p0) {
    return '“$p0” requires exclusive project access. Stop it and retry.';
  }

  @override
  String pIsUpdatingDependenciesOrBuildFiles(Object? p0) {
    return '“$p0” is updating dependencies or build files. Please wait.';
  }

  @override
  String get sessionIsClosed => 'Session is closed';

  @override
  String get theCurrentTaskHasNotFinished =>
      'The current task has not finished';

  @override
  String failedToReadOutputP(Object? p0) {
    return 'Failed to read output: $p0';
  }

  @override
  String failedToStartP(Object? p0) {
    return 'Failed to start: $p0';
  }

  @override
  String get stopped => 'Stopped';

  @override
  String get processExitedWithCode => 'Process exited with code 0';

  @override
  String processExitedWithCodeP(Object? p0) {
    return 'Process exited with code $p0';
  }

  @override
  String get executionTimedOutStopping => 'Execution timed out; stopping';

  @override
  String get sharedByAllTerminalsAndSavedAutomatically =>
      'Shared by all terminals and saved automatically. Pinch in the terminal to zoom.';

  @override
  String settingsAppliedButSavingFailedP(Object? p0) {
    return 'Settings applied, but saving failed: $p0';
  }

  @override
  String get terminalFontSize => 'Terminal font size';

  @override
  String get decreaseTerminalFontSize => 'Decrease terminal font size';

  @override
  String get increaseTerminalFontSize => 'Increase terminal font size';

  @override
  String get monospaceFont => 'Monospace font';

  @override
  String get lineHeight => 'Line height';

  @override
  String p(Object? p0) {
    return '$p0×';
  }

  @override
  String get flitFlutterBuildApkBuildComplete =>
      'flit ~ \$ flutter build apk\n✓ Build complete\n0123456789  []{\'} <> !=';

  @override
  String get resetTerminalAppearance => 'Reset Terminal Appearance';

  @override
  String get thisAssetHasNoShaDigest => 'This asset has no SHA-256 digest';

  @override
  String unsupportedComponentP(Object? p0) {
    return 'Unsupported component: $p0';
  }

  @override
  String get aToolchainIsBeingInstalledPleaseWait =>
      'A toolchain is being installed. Please wait.';

  @override
  String get projectClosedOrTaskCancelled => 'Project closed or task cancelled';

  @override
  String get requiredComponentsAreMissingBuildNotStarted =>
      'Required components are missing; build not started';

  @override
  String componentRepairIncompleteP(Object? p0) {
    return 'Component repair incomplete: $p0';
  }

  @override
  String androidEnvironmentCheckFailedCompleteSetupIn(Object? p0) {
    return 'Android environment check failed. Complete setup in Development Environment.\n$p0';
  }

  @override
  String get installingComponentsChangesTheSharedDevelopmentEnvironment =>
      'Installing components changes the shared development environment. Stop running tasks and retry.';

  @override
  String matchingVersionOrDownloadInformationUnavailableP(Object? p0) {
    return 'Matching version or download information unavailable: $p0';
  }

  @override
  String get aTaskIsRunningStopItAnd => 'A task is running. Stop it and retry.';

  @override
  String get installAndroidBuildComponents =>
      'Install Android Build Components';

  @override
  String stillUnavailableAfterInstallationP(Object? p0) {
    return 'Still unavailable after installation: $p0';
  }

  @override
  String automaticInstallationIsNotSupportedForP(Object? p0) {
    return 'Automatic installation is not supported for $p0';
  }

  @override
  String get invalidNdkVersion => 'Invalid NDK version';

  @override
  String unableToLocateNdkP(Object? p0) {
    return 'Unable to locate NDK $p0';
  }

  @override
  String get androidSdkLicensesHaveNotBeenAccepted =>
      'Android SDK licenses have not been accepted. Run \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses in the environment terminal, accept the licenses, and retry.';

  @override
  String get theSdkNdkCmakePathInThe =>
      'The SDK/NDK/CMake path in the project is invalid. Check local.properties or Gradle settings; installing into the default directory will not fix a custom path.';

  @override
  String unknownComponentP(Object? p0) {
    return 'Unknown component: $p0';
  }

  @override
  String noValidPReleaseConfiguredP(Object? p0, Object? p1) {
    return 'No valid $p0 release configured: $p1';
  }

  @override
  String releaseUnavailableP(Object? p0) {
    return 'Release unavailable: $p0';
  }

  @override
  String noUniquePFoundInP(Object? p0, Object? p1) {
    return 'No unique $p1 found in $p0';
  }

  @override
  String pPIsMissingAValidDownload(Object? p0, Object? p1) {
    return '$p0 / $p1 is missing a valid download URL or SHA-256 digest';
  }

  @override
  String get invalidGithubReleasesResponse =>
      'Invalid GitHub Releases response';

  @override
  String get baseEnvironment => 'Base Environment';

  @override
  String get bashPackageManager => 'Bash · Package manager';

  @override
  String get androidToolchain => 'Android Toolchain';

  @override
  String get openjdkAndroidSdkNdkCmakeGradleConfiguration =>
      'OpenJDK 17 · Android SDK · NDK · CMake · Gradle configuration';

  @override
  String get flutterToolchain => 'Flutter Toolchain';

  @override
  String get flutterSdkGitAndGhWarmUp => 'Flutter SDK · Git and gh · Warm-up';

  @override
  String get gradleConfiguration => 'Gradle Configuration';

  @override
  String get gitAndGh => 'Git and gh';

  @override
  String get warmUp => 'Warm-up';

  @override
  String get projectTasksAreUsingTheDevelopmentEnvironment =>
      'Project tasks are using the development environment. Stop them before installing, switching, or deleting components.';

  @override
  String get aTaskIsRunningWaitBeforeInstalling =>
      'A task is running. Wait before installing another version.';

  @override
  String get installTheBaseEnvironmentBeforeAddingOther =>
      'Install the base environment before adding other versions';

  @override
  String installP(Object? p0) {
    return 'Install $p0';
  }

  @override
  String fetchingDownloadInformationForP(Object? p0) {
    return 'Fetching download information for $p0…';
  }

  @override
  String pInstalled(Object? p0) {
    return '✓ $p0 installed';
  }

  @override
  String installationFailedExitCodePSeeOutput(Object? p0) {
    return 'Installation failed, exit code $p0 (see output above)';
  }

  @override
  String installationFailedP(Object? p0) {
    return 'Installation failed: $p0';
  }

  @override
  String operationFailedExitCodePSeeOutput(Object? p0) {
    return 'Operation failed, exit code $p0 (see output above)';
  }

  @override
  String get installTheBaseEnvironmentBeforeCheckingThe =>
      'Install the base environment before checking the network';

  @override
  String get networkCheck => 'Network Check';

  @override
  String environmentCheckFailedP(Object? p0) {
    return 'Environment check failed: $p0';
  }

  @override
  String get environmentCheck => 'Environment Check';

  @override
  String environmentCheckIncompleteExitCodeP(Object? p0) {
    return 'Environment check incomplete, exit code $p0';
  }

  @override
  String get componentsAreNotReadyCheckAgain =>
      'Components are not ready. Check again.';

  @override
  String get componentDirectoryCheckFailed =>
      'Component directory check failed';

  @override
  String unableToReadInstalledComponentsCheckAgain(Object? p0) {
    return 'Unable to read installed components. Check again: $p0';
  }

  @override
  String get environmentSetup => 'Environment Setup';

  @override
  String baseEnvironmentInstallationFailedP(Object? p0) {
    return '✗ Base environment installation failed: $p0';
  }

  @override
  String pInstallationFailedRemainingStepsSkipped(Object? p0) {
    return '✗ $p0 installation failed; remaining steps skipped';
  }

  @override
  String pComplete(Object? p0) {
    return '✓ $p0 complete';
  }

  @override
  String get installationCompleteDevelopmentEnvironmentReady =>
      '✓ Installation complete; development environment ready';

  @override
  String get environmentVerificationFailedCheckMissingOrFailed =>
      'Environment verification failed. Check missing or failed components.';

  @override
  String get stoppedYouCanResumeInstallationLater =>
      'Stopped; you can resume installation later';

  @override
  String preparingP(Object? p0) {
    return 'Preparing $p0…';
  }

  @override
  String failedToFetchInstallationInformationP(Object? p0) {
    return 'Failed to fetch installation information: $p0';
  }

  @override
  String get keepMultipleVersionsAndChooseTheActive =>
      'Keep multiple versions and choose the active one. Installing a new version switches to it automatically.';

  @override
  String get matchesTheProjectCompilesdkMultipleApiVersions =>
      'Matches the project compileSdk. Multiple API versions can coexist.';

  @override
  String get androidPackagingToolsInstallAndKeepVersions =>
      'Android packaging tools. Install and keep versions required by your projects.';

  @override
  String get nativeCompilerToolsTheProjectSelectsThe =>
      'Native compiler tools. The project selects the version; multiple versions can coexist.';

  @override
  String get nativeBuildToolsTheProjectSelectsThe =>
      'Native build tools. The project selects the version; multiple versions can coexist.';

  @override
  String get adbAndOtherSharedDeviceToolsInstalling =>
      'ADB and other shared device tools. Installing the bundled version replaces existing tools.';

  @override
  String get sdkmanagerAndOtherSharedSdkManagementTools =>
      'sdkmanager and other shared SDK management tools. Installing the bundled version replaces existing tools.';

  @override
  String companionToolsP(Object? p0) {
    return 'Companion tools · $p0';
  }

  @override
  String get unknownVersion => 'Unknown version';

  @override
  String get closeTheProjectBeforeChangingSdksOr =>
      'Close the project before changing SDKs or toolchains';

  @override
  String get back => 'Back';

  @override
  String get proxySettings => 'Proxy Settings';

  @override
  String get sdksAndToolchains => 'SDKs and Toolchains';

  @override
  String get manageSdksAndBuildToolsViewInstallation =>
      'Manage SDKs and build tools. View installation output in the terminal.';

  @override
  String get setupDetails => 'Setup Details';

  @override
  String get checkingEnvironment => 'Checking Environment';

  @override
  String get managingToolchains => 'Managing Toolchains';

  @override
  String get environmentReady => 'Environment Ready';

  @override
  String get installingComponents => 'Installing Components';

  @override
  String get installationFailed => 'Installation Failed';

  @override
  String get environmentNotReady => 'Environment Not Ready';

  @override
  String get checkingLocalComponentsPleaseWait =>
      'Checking local components. Please wait.';

  @override
  String get seeTerminalForDetails => 'See terminal for details';

  @override
  String get componentsReadyYouCanCreateProjectsAnd =>
      'Components ready. You can create projects and build APKs.';

  @override
  String pPReady(Object? p0, Object? p1) {
    return '$p0/$p1 ready';
  }

  @override
  String get done => 'Done';

  @override
  String get resumeInstallation => 'Resume Installation';

  @override
  String get startInstallation => 'Start Installation';

  @override
  String networkP(Object? p0) {
    return 'Network: $p0';
  }

  @override
  String get baseEnvironmentDownloadConfigurationIsIncompleteUpdate =>
      'Base environment download configuration is incomplete. Update the app and retry.';

  @override
  String get downloadingBaseEnvironment => 'Downloading base environment…';

  @override
  String downloadUrlP(Object? p0) {
    return 'Download URL: $p0';
  }

  @override
  String downloadFailedHttpPCheckTheUrl(Object? p0) {
    return 'Download failed: HTTP $p0. Check the URL and network, then retry.';
  }

  @override
  String downloadedPPMb(Object? p0, Object? p1) {
    return 'Downloaded $p0% ($p1 MB)';
  }

  @override
  String downloadCompletePMb(Object? p0) {
    return 'Download complete ($p0 MB)';
  }

  @override
  String verifyingShaP(Object? p0) {
    return 'Verifying SHA-256: $p0';
  }

  @override
  String baseEnvironmentChecksumMismatchExpectedPActual(
    Object? p0,
    Object? p1,
  ) {
    return 'Base environment checksum mismatch:\nExpected: $p0\nActual: $p1';
  }

  @override
  String get shaVerified => 'SHA-256 verified';

  @override
  String get installingBaseEnvironmentExtractingAndConfiguring =>
      'Installing base environment (extracting and configuring)…';

  @override
  String get nativeInstallerDidNotConfirmASuccessful =>
      'Native installer did not confirm a successful installation';

  @override
  String get baseEnvironmentReady => 'Base environment ready';

  @override
  String get checkFailedOpenDevelopmentEnvironment =>
      'Check failed · Open Development Environment';

  @override
  String get notInstalledSetUpDevelopmentEnvironment =>
      'Not installed · Set up Development Environment';

  @override
  String get allComponentsReady => 'All components ready';

  @override
  String pPComponentsReady(Object? p0, Object? p1) {
    return '$p0/$p1 components ready';
  }

  @override
  String get manageVersions => 'Manage Versions';

  @override
  String deleteP(Object? p0) {
    return 'Delete $p0?';
  }

  @override
  String get projectsUsingThisVersionWillNeedIt =>
      'Projects using this version will need it reinstalled. Removing a required version also requires environment repair.';

  @override
  String get repairInstallation => 'Repair Installation';

  @override
  String get useThisVersion => 'Use This Version';

  @override
  String get switchVersionsBeforeDeleting => 'Switch versions before deleting';

  @override
  String get deleteVersion => 'Delete Version';

  @override
  String replaceP(Object? p0) {
    return 'Replace $p0?';
  }

  @override
  String installTheCompanionToolsFromPReplacing(Object? p0) {
    return 'Install the companion tools from $p0, replacing the current shared tools.';
  }

  @override
  String get replace => 'Replace';

  @override
  String get refreshAvailableVersions => 'Refresh available versions';

  @override
  String get localVersions => 'Local Versions';

  @override
  String get checkingLocalComponents => 'Checking local components…';

  @override
  String get installationStatusUnconfirmed => 'Installation status unconfirmed';

  @override
  String get notInstalled => 'Not installed';

  @override
  String get companionTools => 'Companion Tools';

  @override
  String get availableVersions => 'Available Versions';

  @override
  String failedToFetchVersionsPP(Object? p0, Object? p1) {
    return 'Failed to fetch versions: $p0.\n$p1';
  }

  @override
  String get noDownloadableCompanionVersionsInTheRepository =>
      'No downloadable companion versions in the repository.';

  @override
  String get allCatalogVersionsAreInstalledUseThe =>
      'All catalog versions are installed. Use the management menu to reinstall versions needing repair.';

  @override
  String get installingTheSameNdkVersionKeepsThe =>
      'Installing the same NDK version keeps the existing usable version.';

  @override
  String get componentManager => 'Component Manager';

  @override
  String get manageInstalledVersionsDownloadsAndRepairsBy =>
      'Manage installed versions, downloads, and repairs by component. The full SDK bundle is only used for setup.';

  @override
  String get setUpTheBaseEnvironmentFirstThen =>
      'Set up the base environment first, then manage components as your projects need them.';

  @override
  String pVersionsPP(Object? p0, Object? p1, Object? p2) {
    return '$p0 versions$p1$p2';
  }

  @override
  String get availableAfterSetup => 'Available after setup';

  @override
  String get checking372 => 'Checking…';

  @override
  String get installing => 'Installing';

  @override
  String get failed => 'Failed';

  @override
  String get waitingForDependencies => 'Waiting for dependencies';

  @override
  String get pendingInstallation => 'Pending installation';

  @override
  String pInstalling(Object? p0) {
    return '$p0 · Installing';
  }

  @override
  String pFailed(Object? p0) {
    return '$p0 · Failed';
  }

  @override
  String pWaitingForPreviousSteps(Object? p0) {
    return '$p0 · Waiting for previous steps';
  }

  @override
  String pPendingInstallation(Object? p0) {
    return '$p0 · Pending installation';
  }

  @override
  String get deviceConnection => 'Device Connection';

  @override
  String get enterAnIpAddressOrHostnameWithout =>
      'Enter an IP address or hostname without a protocol or port';

  @override
  String get portMustBeBetweenAnd => 'Port must be between 1 and 65535';

  @override
  String get unableToReadDevicesSeeTerminalOutput =>
      'Unable to read devices. See terminal output.';

  @override
  String get adbFailedToStartCheckTheDevelopment =>
      'ADB failed to start. Check the development environment.';

  @override
  String operationFailedPSeeTerminalForDetails(Object? p0) {
    return 'Operation failed: $p0. See terminal for details.';
  }

  @override
  String get enterADigitPairingCode => 'Enter a 6-digit pairing code';

  @override
  String get pairingFailedKeepTheSystemPairingDialog =>
      'Pairing failed. Keep the system pairing dialog open and check the port and code. See terminal for details.';

  @override
  String get pairedSuccessfully => 'Paired successfully';

  @override
  String get unableToConfirmDeviceIsOnlineRefresh =>
      'Unable to confirm device is online. Refresh devices or check logs.';

  @override
  String get connectedToLocalWirelessDebugging =>
      '✓ Connected to local wireless debugging';

  @override
  String get allowUsbDebuggingOnThePhoneThen =>
      'Allow USB debugging on the phone, then retry';

  @override
  String get pairingRequiredTapNotificationPairing =>
      'Pairing required. Tap Notification Pairing.';

  @override
  String get connectionFailedCheckLogsOrConnectManually =>
      'Connection failed. Check logs or connect manually using the current port.';

  @override
  String get noWirelessPortFoundScanAgainEnter =>
      'No wireless port found. Scan again, enter the port manually, or activate via USB from a computer.';

  @override
  String get connectedLocallyUsbActivatedYouCanUnplug =>
      '✓ Connected locally · USB activated; you can unplug the cable';

  @override
  String get unableToConfirmConnectionInstallAdbFirst =>
      'Unable to confirm connection. Install ADB first.';

  @override
  String get unableToConfirmConnectionFailedToRead =>
      '✗ Unable to confirm connection: failed to read devices. See terminal output.';

  @override
  String connectedToP(Object? p0) {
    return '✓ Connected to $p0';
  }

  @override
  String get deviceUnauthorizedAllowUsbDebuggingOnThe =>
      'Device unauthorized. Allow USB debugging on the phone, then connect again.';

  @override
  String get localAdbIsOfflineRunTheActivation =>
      'Local ADB is offline. Run the activation command on the computer and retry.';

  @override
  String get adbAuthenticationFailedConfirmUsbDebuggingAuthorization =>
      'ADB authentication failed. Confirm USB debugging authorization and connect again.';

  @override
  String get notActivatedConnectViaUsbAndRun =>
      'Not activated. Connect via USB and run the activation command on a computer. Reactivate after a phone restart.';

  @override
  String get unableToConnectToLocalPortCheck =>
      'Unable to connect to local port 5555. Check activation and phone authorization; some systems restrict this method.';

  @override
  String get deviceUnauthorizedConfirmAuthorizationOnTheTarget =>
      'Device unauthorized. Confirm authorization on the target device. For wireless debugging, pair again and use the connection port.';

  @override
  String get deviceOfflineEnableWirelessDebuggingThenDisconnect =>
      'Device offline. Enable wireless debugging, then disconnect and reconnect using the current connection port.';

  @override
  String get adbAuthenticationFailedPairAgainInWireless =>
      'ADB authentication failed. Pair again in wireless debugging, then connect.';

  @override
  String get connectionRefusedEnableWirelessDebuggingAndUse =>
      'Connection refused. Enable wireless debugging and use its connection port.';

  @override
  String get connectionTimedOutCheckTheAddressNetwork =>
      'Connection timed out. Check the address, network, and wireless debugging status.';

  @override
  String get deviceIsNotOnlineCheckTerminalOutput =>
      'Device is not online. Check terminal output and the wireless connection port.';

  @override
  String disconnectedFromPPairingAuthorizationIsRetained(Object? p0) {
    return 'Disconnected from $p0; pairing authorization is retained.';
  }

  @override
  String get unableToConfirmDisconnectionCheckTerminalOutput =>
      'Unable to confirm disconnection. Check terminal output and refresh devices.';

  @override
  String connectedButFailedToSaveDeviceSettings(Object? p0) {
    return 'Connected, but failed to save device settings: $p0';
  }

  @override
  String get unableToReadAdbDeviceStatus => 'Unable to read ADB device status';

  @override
  String tryingPreviousConnectionPortP(Object? p0) {
    return 'Trying previous connection port $p0';
  }

  @override
  String get scanningLocalWirelessDebuggingPorts =>
      'Scanning local wireless debugging ports…';

  @override
  String foundConnectionPortP(Object? p0) {
    return 'Found connection port $p0';
  }

  @override
  String scanOrConnectionFailedP(Object? p0) {
    return 'Scan or connection failed: $p0';
  }

  @override
  String get connectedLocallyYouCanUnplugTheCable =>
      'Connected locally. You can unplug the cable.';

  @override
  String get waitTimedOutCheckTheComputerCommand =>
      'Wait timed out. Check the computer command output, then reconnect.';

  @override
  String get allowUsbDebuggingOnThePhoneFlit =>
      'Allow USB debugging on the phone. Flit will continue automatically.';

  @override
  String get unableToReadAdbStatusCheckThe =>
      'Unable to read ADB status. Check the development environment. Retrying…';

  @override
  String get waitingForComputerActivationFlitWillConnect =>
      'Waiting for computer activation… Flit will connect automatically.';

  @override
  String get activateViaComputerUsb => 'Activate via Computer USB';

  @override
  String get enableUsbDebuggingConnectThePhoneTo =>
      '1. Enable USB debugging, connect the phone to a computer, and authorize debugging. Connect only this phone.';

  @override
  String get downloadAndExtractPlatformToolsOnThe =>
      '2. Download and extract Platform Tools on the computer. Open a terminal in that directory.';

  @override
  String get unableToOpenTheDownloadPage => 'Unable to open the download page';

  @override
  String get onTheComputerVisitDeveloperAndroidCom =>
      'On the computer, visit developer.android.com/tools/releases/platform-tools';

  @override
  String get platformToolsWebsite => 'Platform Tools Website';

  @override
  String get runThisCommandOnTheComputerKeep =>
      '3. Run this command on the computer. Keep this guide open and wait for connection.';

  @override
  String get computerOs => 'Computer OS';

  @override
  String get copyFailedLongPressTheCommandTo =>
      'Copy failed. Long-press the command to copy it.';

  @override
  String get copyCommand => 'Copy Command';

  @override
  String get afterTheComputerShowsRestartingInTcp =>
      'After the computer shows restarting in TCP mode port: 5555, Flit will try to connect. Allow any new debugging authorization prompt.';

  @override
  String get waitsAutomaticallyForUpToMinutesClosing =>
      'Waits automatically for up to 2 minutes; closing this guide stops checks. You can still tap Connect Locally on the device page. Reactivation is usually needed after a phone restart.';

  @override
  String tcpDebuggingMayAlsoListenOnNetwork(Object? p0) {
    return 'TCP debugging may also listen on network interfaces. Reconnect to the computer and run $p0 -d usb to disable it. Disconnect in Flit only disconnects the client.';
  }

  @override
  String get reconnect => 'Reconnect';

  @override
  String get connectNow => 'Connect Now';

  @override
  String get unableToReadPairingStatusGoBack =>
      'Unable to read pairing status. Go back and retry.';

  @override
  String get systemOperationFailed => 'System operation failed';

  @override
  String get openTheSystemPairingDialogAndEnter =>
      'Open the system pairing dialog and enter the code in the notification';

  @override
  String get noPairingPortFoundKeepTheSystem =>
      'No pairing port found. Keep the system pairing dialog open.';

  @override
  String get refreshDevices => 'Refresh Devices';

  @override
  String get manualConnectionOtherDevices =>
      'Manual Connection / Other Devices';

  @override
  String get deviceAddress => 'Device address';

  @override
  String get connectionPort => 'Connection port';

  @override
  String get connect => 'Connect';

  @override
  String get pairingRecorded => 'Pairing recorded';

  @override
  String get keepTheSystemPairingDialogOpenIn =>
      'Keep the system pairing dialog open in split screen for manual pairing.';

  @override
  String get pairingPort => 'Pairing port';

  @override
  String get pairingCodeDigits => 'Pairing code (6 digits)';

  @override
  String get scanning => 'Scanning…';

  @override
  String get scanPairingPorts => 'Scan Pairing Ports';

  @override
  String get pair => 'Pair';

  @override
  String get wirelessPairingGuide => 'Wireless Pairing Guide';

  @override
  String get notificationStylePairingStepsAndTroubleshooting =>
      'Notification style, pairing steps, and troubleshooting';

  @override
  String get connectViaWirelessDebugging => 'Connect via Wireless Debugging';

  @override
  String get androidPairAndConnectOverWiFi =>
      'Android 11+ · Pair and connect over Wi-Fi';

  @override
  String get wirelessDebuggingSettings => 'Wireless Debugging Settings';

  @override
  String get notificationPairing => 'Notification Pairing';

  @override
  String get scanAndConnect => 'Scan and Connect';

  @override
  String get searchingForPairingPort => 'Searching for pairing port…';

  @override
  String get cancelPairing => 'Cancel Pairing';

  @override
  String get activateFromAComputerThenUnplugThe =>
      'Activate from a computer, then unplug the cable';

  @override
  String get viewSteps => 'View Steps';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectLocally => 'Connect Locally';

  @override
  String get deviceStatus => 'Device Status';

  @override
  String pOnline(Object? p0) {
    return '$p0 online';
  }

  @override
  String get adbNotFoundInstallTheAndroidToolchain =>
      'ADB not found. Install the Android toolchain in Development Environment.';

  @override
  String get noConnections => 'No connections';

  @override
  String disconnectP(Object? p0) {
    return 'Disconnect $p0';
  }

  @override
  String get unableToReadNotificationStatus =>
      'Unable to read notification status';

  @override
  String get unableToReadNotificationStatusRetry =>
      'Unable to read notification status. Retry.';

  @override
  String get unableToOpenSystemSettings => 'Unable to open system settings';

  @override
  String get unableToOpenRetryLater => 'Unable to open. Retry later.';

  @override
  String get enterThePairingCodeInTheNotification =>
      'Enter the Pairing Code in the Notification';

  @override
  String get androidPhoneMustBeConnectedToWi =>
      'Android 11+ · Phone must be connected to Wi-Fi';

  @override
  String get checkingNotificationPermission =>
      'Checking notification permission…';

  @override
  String get wirelessPairingIsNotSupportedOnThis =>
      'Wireless pairing is not supported on this system';

  @override
  String get pairingNotificationsEnabled => 'Pairing notifications enabled';

  @override
  String get allowFlitNotificationsFirst => 'Allow Flit notifications first';

  @override
  String get notificationStatusUnknown => 'Notification status unknown';

  @override
  String get wirelessPairingRequiresAndroidOrLaterGo =>
      'Wireless pairing requires Android 11 or later. Go back to activate via USB from a computer.';

  @override
  String get allowFlitNotificationsIncludingTheWirelessDebugging =>
      'Allow Flit notifications, including the Wireless Debugging Pairing category if present. Enter the pairing code from the notification.';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get checkAgain487 => 'Check Again';

  @override
  String get xiaomiPocoSomeMiuiVersionsRequireThe =>
      'Xiaomi / POCO: some MIUI versions require the Native notification style to enter a pairing code. See instructions below.';

  @override
  String get finishTheCurrentDeviceOperationOrInstall =>
      'Finish the current device operation or install ADB before pairing.';

  @override
  String get startPairing => 'Start Pairing';

  @override
  String get tapStartPairingBelowFlitStartsThe =>
      'Tap Start Pairing below. Flit starts the pairing notification and opens Developer options. Enable Developer options and USB debugging first.';

  @override
  String get openThePairingCodeDialog => 'Open the Pairing Code Dialog';

  @override
  String get enableWirelessDebuggingTapItsLabelTo =>
      'Enable Wireless debugging, tap its label to open details, then tap Pair device with pairing code. Keep the 6-digit code dialog open.';

  @override
  String get enablingTheSwitchAloneIsNotEnough =>
      'Enabling the switch alone is not enough; open the wireless debugging details.';

  @override
  String get expandTheNotificationAndEnterTheDigit =>
      'Expand the Notification and Enter the 6-Digit Code';

  @override
  String get expandTheFlitPairingNotificationTapEnter =>
      'Expand the Flit pairing notification, tap Enter Pairing Code, enter the code from the system dialog, and send. Do not switch back to Flit; doing so may close the pairing dialog.';

  @override
  String get theEnterPairingCodeButtonAppearsOnce =>
      'The Enter Pairing Code button appears once the pairing port is found.';

  @override
  String get returnToFlitToConnect => 'Return to Flit to Connect';

  @override
  String get returnToFlitAfterSuccessfulPairingIt =>
      'Return to Flit after successful pairing; it will try connecting automatically. If already paired, use Scan and Connect. The connection port may change when wireless debugging restarts.';

  @override
  String get noNotificationInputEnteringTheCodeFails =>
      'No notification input / Entering the code fails';

  @override
  String get expandTheNotificationAndCheckThatEnter =>
      'Expand the notification and check that Enter Pairing Code is shown. If it is still searching for a port, see the next item.';

  @override
  String get someXiaomiRedmiAndPocoMiuiVersions =>
      'Some Xiaomi, Redmi, and POCO MIUI versions: in system Settings → Notifications → Notification display settings, select the Native notification style, then pair again.';

  @override
  String get namesAndLocationsVaryAcrossHyperosAnd =>
      'Names and locations vary across HyperOS and other systems. Try Android or Native style if offered. Flit cannot detect or change this setting automatically.';

  @override
  String get ifThisOptionIsUnavailableKeepThe =>
      'If this option is unavailable, keep the system pairing dialog open in split screen and enter the port and code under Manual Connection / Other Devices.';

  @override
  String get keepsSearchingNoResponseAfterOpeningSettings =>
      'Keeps searching / No response after opening settings';

  @override
  String get enableWiFiAndWirelessDebuggingAnd =>
      'Enable Wi-Fi and wireless debugging, and keep Pair device with pairing code open. The pairing port is advertised only while that dialog is open.';

  @override
  String get someSystemsRestrictLocalNetworkAccessFor =>
      'Some systems restrict local network access for background apps. Allow Flit to run in the background and access Wi-Fi / local networks in system settings, if available.';

  @override
  String get allowBackgroundExecution => 'Allow Background Execution';

  @override
  String get ifNothingIsFoundToggleWirelessDebugging =>
      'If nothing is found, toggle wireless debugging and retry. Flit searches for up to 3 minutes. Restart after timeout or activate via USB from a computer.';

  @override
  String get pairedButCannotConnect => 'Paired, but cannot connect';

  @override
  String get pairingAndConnectionPortsDifferForManual =>
      'Pairing and connection ports differ. For manual connection, use the port on the main wireless debugging page, not the pairing dialog port.';

  @override
  String get tapScanAndConnectOnTheDevice =>
      'Tap Scan and Connect on the device page. If needed, enter the port manually or activate via USB from a computer. A pairing record does not mean the device is online.';

  @override
  String get unableToOpenReferencePage => 'Unable to open reference page';

  @override
  String get referenceShizukuGuide => 'Reference: Shizuku Guide';

  @override
  String get webServerRestarted => 'Web server restarted';

  @override
  String get webStartupTimedOutCheckRunLogs =>
      'Web startup timed out. Check run logs.';

  @override
  String webStartupFailedP(Object? p0) {
    return 'Web startup failed: $p0';
  }

  @override
  String webRunFailedP(Object? p0) {
    return 'Web run failed: $p0';
  }

  @override
  String updateFailedP(Object? p0) {
    return 'Update failed: $p0';
  }

  @override
  String webProcessExitedCodePCheckRun(Object? p0) {
    return 'Web process exited (code $p0). Check run logs.';
  }

  @override
  String get webServerStopped => 'Web server stopped';

  @override
  String get runWebToPreviewHere => 'Run Web to preview here';

  @override
  String get compilingAndStartingTheWebServer =>
      'Compiling and starting the Web server';

  @override
  String get webStartupFailed => 'Web startup failed';

  @override
  String get viewRunLogs => 'View Run Logs';

  @override
  String get thePageHasNotRenderedYetCheck =>
      'The page has not rendered yet. Check run logs or reload.';

  @override
  String pageLoadFailedP(Object? p0) {
    return 'Page load failed: $p0';
  }

  @override
  String pageRequestFailedHttpP(Object? p0) {
    return 'Page request failed: HTTP $p0';
  }

  @override
  String unableToLoadPreviewP(Object? p0) {
    return 'Unable to load preview: $p0';
  }

  @override
  String get reloadPageResetPageState => 'Reload Page (Reset Page State)';

  @override
  String get loadingPreview => 'Loading preview…';

  @override
  String get reload => 'Reload';

  @override
  String get updating => 'Updating…';

  @override
  String get document => 'Document';

  @override
  String get symbol => 'Symbol';

  @override
  String get keyword => 'Keyword';

  @override
  String get method => 'Method';

  @override
  String get type => 'Type';

  @override
  String get variable => 'Variable';

  @override
  String get module => 'Module';

  @override
  String get property => 'Property';

  @override
  String get dartLanguageServiceCouldNotStart =>
      'Dart language service could not start';

  @override
  String get initializationFailed => 'Initialization failed';

  @override
  String get languageServiceDisconnected => 'Language service disconnected';

  @override
  String get saved => 'Saved';

  @override
  String get fileChangedExternallySavingStoppedTapThe =>
      'File changed externally; saving stopped. Tap the status below the title to reload.';

  @override
  String get fileChangedExternally => 'File Changed Externally';

  @override
  String pSavingStoppedToAvoidOverwritingDisk(Object? p0) {
    return '$p0\n\nSaving stopped to avoid overwriting disk changes. Reloading discards unsaved edits to this file.';
  }

  @override
  String get reloadFromDisk => 'Reload from Disk';

  @override
  String unableToReadP(Object? p0) {
    return 'Unable to read $p0';
  }

  @override
  String get aFileOperationIsInProgressWait =>
      'A file operation is in progress. Wait before closing.';

  @override
  String get aFileOperationIsInProgressWait552 =>
      'A file operation is in progress. Wait before closing the project.';

  @override
  String get fileChangedTapToResolve => 'File changed · Tap to resolve';

  @override
  String get saveFailedTapToRetry => 'Save failed · Tap to retry';

  @override
  String get saving => 'Saving…';

  @override
  String get unsaved => 'Unsaved';

  @override
  String get project => 'Project';

  @override
  String get versionControl => 'Version Control';

  @override
  String get closeProject => 'Close Project';

  @override
  String get selectAFileFromTheProjectTool =>
      'Select a file from the Project tool window to start editing';

  @override
  String get openProjectToolWindow => 'Open Project Tool Window';

  @override
  String get editorOptions => 'Editor Options';

  @override
  String get settingsSaveAutomaticallyPinchInTheCode =>
      'Settings save automatically. Pinch in the code area to zoom.';

  @override
  String get display => 'Display';

  @override
  String get fontSize => 'Font size';

  @override
  String get font => 'Font';

  @override
  String get builtIn => 'Built-in';

  @override
  String get colorScheme => 'Color Scheme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get terminal => 'Terminal';

  @override
  String get editing => 'Editing';

  @override
  String get softWraps => 'Soft wraps';

  @override
  String get wrapLongLinesWithoutInsertingLineBreaks =>
      'Wrap long lines without inserting line breaks';

  @override
  String get scrollLongLinesHorizontallyLineNumbersStay =>
      'Scroll long lines horizontally; line numbers stay visible';

  @override
  String deleteP576(Object? p0) {
    return 'Delete “$p0”?';
  }

  @override
  String get permanentlyDeleteTheSelectedFileOrDirectory =>
      'Permanently delete the selected file or directory and its contents? This cannot be undone.';

  @override
  String get name => 'Name';

  @override
  String get newDirectory => 'New Directory';

  @override
  String get newFile => 'New File';

  @override
  String get installMissingAndroidBuildComponents =>
      'Install Missing Android Build Components?';

  @override
  String get componentsCurrentlyUnavailable =>
      'Components Currently Unavailable';

  @override
  String get theBuildFailedBecauseTheseComponentsAre =>
      'The build failed because these components are missing or unusable:';

  @override
  String get preflightFoundTheseMissingOrUnusableComponents =>
      'Preflight found these missing or unusable components:';

  @override
  String theBuildWillPAfterInstallationDownload(Object? p0) {
    return 'The build will $p0 after installation. Download progress appears in the console.';
  }

  @override
  String get installAndRetry => 'Install and Retry';

  @override
  String get installAndContinue => 'Install and Continue';

  @override
  String get starting => 'Starting';

  @override
  String get rerun => 'Rerun';

  @override
  String get run => 'Run';

  @override
  String get hotReload => 'Hot Reload';

  @override
  String get stopRun => 'Stop Run';

  @override
  String get switchRunTarget => 'Switch Run Target?';

  @override
  String get stopTheCurrentRunAndStartThe =>
      'Stop the current run and start the project on the new target.';

  @override
  String get switchAndRun => 'Switch and Run';

  @override
  String get tasks => 'Tasks';

  @override
  String currentProjectP(Object? p0) {
    return 'Current project: $p0';
  }

  @override
  String currentTaskP(Object? p0) {
    return 'Current task: $p0';
  }

  @override
  String get tasksUseSeparateTerminalsConflictingActionsAre =>
      'Tasks use separate terminals. Conflicting actions are temporarily unavailable.';

  @override
  String get dependencies => 'Dependencies';

  @override
  String get fetchDependenciesAndWritePackageConfig =>
      'Fetch dependencies and write package_config';

  @override
  String get upgradeDependenciesWithinConstraints =>
      'Upgrade dependencies within constraints';

  @override
  String get listOutdatedDependencies => 'List outdated dependencies';

  @override
  String get build => 'Build';

  @override
  String get buildThenInstallOnTheSelectedAndroid =>
      'Build, then install on the selected Android device via ADB';

  @override
  String get buildAReleaseApkThenChooseAdb =>
      'Build a release APK; then choose ADB or the system installer';

  @override
  String get outputDirectoryBuildWeb => 'Output directory: build/web';

  @override
  String get dartCompileExeOutputBuildPackageName =>
      'dart compile exe; output: build/<package-name>. Run it in the terminal when complete.';

  @override
  String get code => 'Code';

  @override
  String get runBatchAnalysisAndShowResultsIn =>
      'Run batch analysis and show results in the terminal';

  @override
  String get runTestsInTheTestDirectory => 'Run tests in the test/ directory';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get deleteBuildAndDartToolCaches =>
      'Delete build/ and .dart_tool caches';

  @override
  String get checkFlutterAndAndroidToolchainHealth =>
      'Check Flutter and Android toolchain health';

  @override
  String failedToReadDevicesP(Object? p0) {
    return 'Failed to read devices: $p0';
  }

  @override
  String get selectPlatform => 'Select Platform';

  @override
  String get webPreview => 'Web Preview';

  @override
  String get runTarget => 'Run Target';

  @override
  String get refresh => 'Refresh';

  @override
  String get previewInsideTheIdeWithoutADevice =>
      'Preview inside the IDE without a device connection';

  @override
  String get connectAndroidDevice => 'Connect Android Device';

  @override
  String get closeOthers => 'Close Others';

  @override
  String closeP(Object? p0) {
    return 'Close $p0';
  }

  @override
  String get fileDoesNotExist => 'File does not exist';

  @override
  String get cannotInstallAllowFlitToInstallUnknown =>
      'Cannot install. Allow Flit to install unknown apps in system settings first.';

  @override
  String get installLocally => 'Install Locally';

  @override
  String get noApplicationCanOpenThisFile =>
      'No application can open this file';

  @override
  String get openWith => 'Open With';

  @override
  String get unableToShareThisFile => 'Unable to share this file';

  @override
  String get share => 'Share';

  @override
  String linePPIssues(Object? p0, Object? p1) {
    return 'Line $p0 · $p1 issues';
  }

  @override
  String get quickFix => 'Quick Fix';

  @override
  String get completionItemExpiredTypeAgain =>
      'Completion item expired. Type again.';

  @override
  String get problemsCurrentFile => 'Problems · Current File';

  @override
  String get noProblems => 'No problems';

  @override
  String linePColumnP(Object? p0, Object? p1) {
    return 'Line $p0 · Column $p1';
  }

  @override
  String get syntaxHighlighting => 'Syntax Highlighting';

  @override
  String get startingDartAnalyzer => 'Starting Dart analyzer…';

  @override
  String get dartAnalysisReady => 'Dart · Analysis ready';

  @override
  String get dartBasicCompletion => 'Dart · Basic completion';

  @override
  String problemsP(Object? p0) {
    return 'Problems $p0';
  }

  @override
  String get browseSharedStorageAndSelectFilesTo =>
      'Browse shared storage and select files to copy into the project. This browser is for importing only.';

  @override
  String unableToReadDirectoryP(Object? p0) {
    return 'Unable to read directory: $p0';
  }

  @override
  String get pasteHere => 'Paste Here';

  @override
  String copiedPLongPressTheDestinationDirectory(Object? p0) {
    return 'Copied $p0. Long-press the destination directory to paste.';
  }

  @override
  String get cut => 'Cut';

  @override
  String cutPLongPressTheDestinationDirectory(Object? p0) {
    return 'Cut $p0. Long-press the destination directory to paste.';
  }

  @override
  String copiedPReturnToTheProjectAnd(Object? p0) {
    return 'Copied $p0. Return to the project and long-press the destination directory to paste.';
  }

  @override
  String get sharedStorageImportOnly => 'Shared Storage (Import Only)';

  @override
  String get newItem => 'New';

  @override
  String get switchLocation => 'Switch Location';

  @override
  String get copyFromSharedStorage => 'Copy from Shared Storage…';

  @override
  String get svgPreviewFromEditorBuffer => 'SVG Preview (From Editor Buffer)';

  @override
  String get emptyFile => 'Empty file';

  @override
  String get unableToRenderSvgContentIsNot =>
      'Unable to render SVG: content is not valid SVG';

  @override
  String unableToRenderSvgP(Object? p0) {
    return 'Unable to render SVG: $p0';
  }

  @override
  String get preview => 'Preview';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get commitStagedChanges => 'Commit Staged Changes';

  @override
  String get commitMessage => 'Commit message';

  @override
  String get showStagedDiff => 'Show Staged Diff';

  @override
  String get showUnstagedDiff => 'Show Unstaged Diff';

  @override
  String get markConflictResolvedStage => 'Mark Conflict Resolved (Stage)';

  @override
  String get stageFile => 'Stage File';

  @override
  String get unstage => 'Unstage';

  @override
  String get rollbackUnstagedChanges => 'Rollback Unstaged Changes';

  @override
  String get rollbackChanges => 'Rollback Changes?';

  @override
  String discardUnstagedChangesInPStagedChanges(Object? p0) {
    return 'Discard unstaged changes in $p0? Staged changes will be kept. This cannot be undone.';
  }

  @override
  String get branches => 'Branches';

  @override
  String get createAndSwitchBranch => 'Create and Switch Branch';

  @override
  String get newBranch => 'New Branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get commitHistory => 'Commit History';

  @override
  String get remoteOrigin => 'Remote · origin';

  @override
  String get commitAuthorThisRepository => 'Commit Author (This Repository)';

  @override
  String get email => 'Email';

  @override
  String get detachedHead => 'Detached HEAD';

  @override
  String get refreshVersionControlStatus => 'Refresh Version Control Status';

  @override
  String get repositorySettings => 'Repository Settings';

  @override
  String get remotes => 'Remotes';

  @override
  String get commitAuthor => 'Commit Author';

  @override
  String get pull => 'Pull';

  @override
  String get push => 'Push';

  @override
  String get operationInProgressViewProgressOrStop =>
      'Operation in progress. View progress or stop it in the terminal.';

  @override
  String get thisProjectHasNoGitRepositoryYet =>
      'This project has no Git repository yet.';

  @override
  String get initializeRepository => 'Initialize Repository';

  @override
  String get noLocalChanges => 'No local changes';

  @override
  String get conflictsFoundResolveThemInTheEditor =>
      'Conflicts found. Resolve them in the editor, then stage each file.';

  @override
  String get conflicts => 'Conflicts';

  @override
  String get untracked => 'Untracked';

  @override
  String get stagedWithAdditionalUnstagedChanges =>
      'Staged with additional unstaged changes';

  @override
  String get staged => 'Staged';

  @override
  String get stageAllChanges => 'Stage All Changes';

  @override
  String commitChangesP(Object? p0) {
    return 'Commit Changes · $p0';
  }

  @override
  String get signOutOfGithub => 'Sign Out of GitHub?';

  @override
  String get removeGithubComCredentialsFromThisDevice =>
      'Remove github.com credentials from this device.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get ghIsNotInstalledCompleteTheFlutter =>
      'gh is not installed. Complete the Flutter setup stage in Development Environment first.';

  @override
  String get notSignedInSignInToClone =>
      'Not signed in. Sign in to clone and push private repositories.';

  @override
  String get signedInGitCredentialHelperConfigured =>
      'Signed in · Git credential helper configured';

  @override
  String get githubAccount => 'GitHub Account';

  @override
  String get working => 'Working…';

  @override
  String get waitingForBrowserAuthorization =>
      'Waiting for browser authorization…';

  @override
  String signedInP(Object? p0) {
    return 'Signed in · $p0';
  }

  @override
  String get viewAuthorizationCode => 'View Authorization Code';

  @override
  String get signIn => 'Sign In';

  @override
  String get ghIsNotInstalledCompleteTheFlutter708 =>
      'gh is not installed. Complete the Flutter setup stage in Development Environment first.';

  @override
  String get githubSignIn => 'GitHub Sign-In';

  @override
  String get signInCancelled => 'Sign-in cancelled';

  @override
  String signInIncompleteExitCodePP(Object? p0, Object? p1) {
    return 'Sign-in incomplete (exit code $p0)$p1';
  }

  @override
  String signInFailedP(Object? p0) {
    return 'Sign-in failed: $p0';
  }

  @override
  String get githubSignOut => 'GitHub Sign-Out';

  @override
  String githubSignOutIncompleteExitCodeP(Object? p0) {
    return 'GitHub sign-out incomplete (exit code $p0)';
  }

  @override
  String githubSignOutFailedP(Object? p0) {
    return 'GitHub sign-out failed: $p0';
  }

  @override
  String get unableToOpenBrowserVisitGithubCom =>
      'Unable to open browser. Visit github.com/login/device.';

  @override
  String failedToOpenBrowserP(Object? p0) {
    return 'Failed to open browser: $p0';
  }

  @override
  String get signInToGithub => 'Sign In to GitHub';

  @override
  String get copyTheDeviceCodeAndAuthorizeIn =>
      'Copy the device code and authorize in your browser. Sign-in status updates automatically.';

  @override
  String get later => 'Later';

  @override
  String get cancelSignIn => 'Cancel Sign-In';

  @override
  String get copyAndOpenBrowser => 'Copy and Open Browser';

  @override
  String get openTheGitRepositoryRootToUse =>
      'Open the Git repository root to use version control';

  @override
  String get aTaskIsRunningStopItBefore =>
      'A task is running. Stop it before performing Git operations.';

  @override
  String get saveFailedGitOperationCancelled =>
      'Save failed; Git operation cancelled';

  @override
  String pIncompleteExitCodePSeeTerminal(Object? p0, Object? p1) {
    return '$p0 incomplete (exit code $p1); see terminal output';
  }

  @override
  String get enterACommitMessage => 'Enter a commit message';

  @override
  String get resolveConflictsAndStageTheFilesFirst =>
      'Resolve conflicts and stage the files first';

  @override
  String get stageTheFilesToCommitFirst => 'Stage the files to commit first';

  @override
  String get commit => 'Commit';

  @override
  String get theCurrentFileStatusDoesNotSupport =>
      'The current file status does not support rollback';

  @override
  String get commitOrRollbackChangesBeforeSwitchingBranches =>
      'Commit or rollback changes before switching branches';

  @override
  String get switchBranch => 'Switch Branch';

  @override
  String get commitOrRollbackChangesBeforePulling =>
      'Commit or rollback changes before pulling';

  @override
  String get thisBranchHasNoUpstreamPushAnd =>
      'This branch has no upstream. Push and track a remote branch first.';

  @override
  String get switchToABranchAndCreateA =>
      'Switch to a branch and create a commit first';

  @override
  String get resolveConflictsFirst => 'Resolve conflicts first';

  @override
  String get firstPushRequiresARemoteConfigureOrigin =>
      'First push requires a remote. Configure origin in Remotes.';

  @override
  String get firstPush => 'First Push';

  @override
  String get enterAValidRepositoryUrl => 'Enter a valid repository URL';

  @override
  String get enterTheCommitAuthorNameAndEmail =>
      'Enter the commit author name and email';

  @override
  String get invalidSourcePath => 'Invalid source path';

  @override
  String get filesCannotBeMovedOutsideTheirProject =>
      'Files cannot be moved outside their project';

  @override
  String get destinationMustBeInsideTheCurrentProject =>
      'Destination must be inside the current project';

  @override
  String get cannotCopyOrMoveADirectoryInto =>
      'Cannot copy or move a directory into itself';

  @override
  String get onlyEntriesInsideTheCurrentProjectCan =>
      'Only entries inside the current project can be deleted';

  @override
  String get invalidName => 'Invalid name';

  @override
  String get renameIsOnlyAllowedWithinTheCurrent =>
      'Rename is only allowed within the current project';

  @override
  String get filesAndDirectoriesCanOnlyBeCreated =>
      'Files and directories can only be created within the current project';

  @override
  String operationFailedExitCodeP(Object? p0) {
    return 'Operation failed (exit code $p0)';
  }

  @override
  String operationFailedP(Object? p0) {
    return 'Operation failed: $p0';
  }

  @override
  String get connected => 'Connected';

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get offline => 'Offline';

  @override
  String get authenticating => 'Authenticating';

  @override
  String get localDevice => 'Local device';

  @override
  String localDeviceP(Object? p0) {
    return 'Local device · $p0';
  }

  @override
  String lanP(Object? p0) {
    return 'LAN $p0';
  }

  @override
  String get lan => 'LAN';

  @override
  String get failedToReadDevices => 'Failed to read devices';

  @override
  String adbDidNotReturnADeviceList(Object? p0) {
    return 'ADB did not return a device list: $p0';
  }

  @override
  String get backgroundExecutionAndNotifications =>
      'Background Execution and Notifications';

  @override
  String get setupAndBuildsMayTakeAWhile =>
      'Setup and builds may take a while. Recommended permissions:';

  @override
  String get theForegroundServiceOnlyShowsGeneralTask =>
      'The foreground service only shows general task status. You can change notification and background settings later in Settings → Background and Notifications.';

  @override
  String get continueAction => 'Continue';

  @override
  String get allowSharedStorageAccess => 'Allow Shared Storage Access?';

  @override
  String get withPermissionFlitCanAccessSharedStorage =>
      'With permission, Flit can access shared storage files. You can skip this and use app-private projects. Private files are hidden from regular file managers and deleted when Flit is uninstalled.';

  @override
  String get notNow => 'Not Now';

  @override
  String get grantAccess => 'Grant Access';

  @override
  String get sharedStoragePermissionDeniedAppPrivateProjects =>
      'Shared storage permission denied. App-private projects remain available.';

  @override
  String gitCommandFailedP(Object? p0) {
    return 'Git command failed ($p0)';
  }

  @override
  String get gitUnavailableCheckTheDevelopmentEnvironment =>
      'Git unavailable. Check the development environment.';

  @override
  String get theProjectIsInsideAParentGit =>
      'The project is inside a parent Git repository. Open the repository root to use version control.';

  @override
  String get thisFileIsUntrackedStageItTo =>
      'This file is untracked. Stage it to view the full diff.';

  @override
  String get noTextDiffPossiblyABinaryFile =>
      'No text diff (possibly a binary file or mode change).';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'Follow System';

  @override
  String get refreshVersionsLater => 'Tap Refresh to retry later';

  @override
  String get showingPreviousCatalog => 'Showing the previous catalog';

  @override
  String currentVersionSuffix(Object? p0) {
    return ' · Current: $p0';
  }

  @override
  String repairCountSuffix(Object? p0) {
    return ' · $p0 need repair';
  }

  @override
  String get retryBuildVerb => 'retry';

  @override
  String get continueBuildVerb => 'continue';

  @override
  String get startingEllipsis => 'Starting…';

  @override
  String get prereleaseSuffix => ' · Pre-release';

  @override
  String get cannotRun => 'Cannot run';

  @override
  String get running => 'Running';

  @override
  String get exited => 'Exited';

  @override
  String get switchVersion => 'Switch';

  @override
  String get requestFailed => '✗ Request failed';

  @override
  String get currentSuffix => ' · Current';

  @override
  String get installed => 'Installed';

  @override
  String get installationIncomplete => 'Installation incomplete';

  @override
  String get replaceSharedToolsSuffix => ' · Replaces shared tools';

  @override
  String get needsRepair => 'Needs repair';

  @override
  String get compilationFailed => 'Compilation failed';

  @override
  String get unstaged => 'Unstaged';
}
