import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局视觉常量(GitHub Dark 调色板)。
/// 页面与组件统一从这里取色, 禁止再散落硬编码色值。
class AppColors {
  AppColors._();

  static const bg = Color(0xFF10141C); // 页面/终端底色
  static const surface = Color(0xFF191F2A); // 卡片/栏
  static const border = Color(0xFF303A49);
  static const divider = Color(0xFF21262D);

  static const accent = Color(0xFF58A6FF); // 蓝: 主操作/选中
  static const success = Color(0xFF3FB950); // 绿: 完成
  static const danger = Color(0xFFF85149); // 红: 失败
  static const warn = Color(0xFFD29922); // 黄: 注意/未就绪

  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF8B949E);
  static const textFaint = Color(0xFF8592A6);
  static const textDisabled = Color(0xFF484F58);

  static const primaryButton = Color(0xFF387CE8);

  /// 代码编辑/终端共用的 monospace 文字样式
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.4,
    color: textPrimary,
  );
}

/// 代码高亮配色(highlight 风格 theme): 内置 dark/light 两套,
/// 编辑器设置里切换(CodeTheme.current)。覆盖编辑面/行号槽/诊断盒全部用色。
class CodeTheme {
  const CodeTheme({
    required this.background,
    required this.plain,
    required this.keyword,
    required this.string,
    required this.comment,
    required this.number,
    required this.clazz,
    required this.annotation,
    required this.gutterBackground,
    required this.gutterText,
    required this.gutterActive,
    required this.cursor,
    required this.diagBoxBackground,
  });

  final Color background; // 编辑区底色
  final Color plain; // 普通文本
  final Color keyword; // 关键字
  final Color string; // 字符串
  final Color comment; // 注释
  final Color number; // 数字
  final Color clazz; // 类型/类名
  final Color annotation; // 注解 @xxx
  final Color gutterBackground; // 行号槽底色
  final Color gutterText; // 行号
  final Color gutterActive; // 光标行行号
  final Color cursor; // 光标
  final Color diagBoxBackground; // 行内诊断消息盒底色

  /// 当前主题(编辑器设置切换; 默认 dark)
  static CodeTheme current = dark;

  static const dark = CodeTheme(
    background: Color(0xFF10141C),
    plain: Color(0xFFE2E8F0),
    keyword: Color(0xFFFF7B72),
    string: Color(0xFFA5D6FF),
    comment: Color(0xFF8B949E),
    number: Color(0xFF79C0FF),
    clazz: Color(0xFFFFA657),
    annotation: Color(0xFFD2A8FF),
    gutterBackground: Color(0xFF191F2A),
    gutterText: Color(0xFF484F58),
    gutterActive: Color(0xFF58A6FF),
    cursor: Color(0xFF58A6FF),
    diagBoxBackground: Color(0xF2161B22),
  );

  static const light = CodeTheme(
    background: Color(0xFFFFFFFF),
    plain: Color(0xFF1F2328),
    keyword: Color(0xFFCF222E),
    string: Color(0xFF0A3069),
    comment: Color(0xFF6E7781),
    number: Color(0xFF0550AE),
    clazz: Color(0xFF953800),
    annotation: Color(0xFF8250DF),
    gutterBackground: Color(0xFFF6F8FA),
    gutterText: Color(0xFF8C959F),
    gutterActive: Color(0xFF0969DA),
    cursor: Color(0xFF0969DA),
    diagBoxBackground: Color(0xF2FFFFFF),
  );
}

/// 输入法工具: 单行/多行代码区共用
class AppInputFormatters {
  AppInputFormatters._();

  /// 代码区常用过滤(留空: 缩进与括号由 CodeInputFormatter 处理)
  static List<TextInputFormatter> code() => const [];
}

ThemeData flitTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    primary: AppColors.accent,
    onPrimary: AppColors.bg,
  );
  final typography = ThemeData.dark().textTheme.apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: typography,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: typography.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryButton,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      // 暗色下无边框输入框与卡片底色融为一体, 全局给可见描边
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: typography.bodyMedium!.copyWith(fontSize: 14),
      subtitleTextStyle: typography.bodySmall!.copyWith(
        fontSize: 12,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      iconColor: AppColors.textSecondary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      showDragHandle: true,
      modalBackgroundColor: AppColors.bg,
    ),
    popupMenuTheme: const PopupMenuThemeData(color: AppColors.surface),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.clipBehavior = Clip.none,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: clipBehavior,
    child: Padding(padding: padding, child: child),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
