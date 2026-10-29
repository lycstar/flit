import 'package:flutter/services.dart';

/// 文件与系统交互的原生薄方法(通道 flit/files)。
class FlitFiles {
  FlitFiles._();

  static const channel = MethodChannel('flit/files');

  /// 系统分享面板(FileProvider 授权读取); false = 文件不存在
  static Future<bool> share(String path) async =>
      await channel.invokeMethod('share', {'path': path}) == true;

  /// 调起系统安装器安装 APK。
  /// false = 文件不存在, 或需要先在系统设置里授权"安装未知应用"(已跳过去), 授权后重试
  static Future<bool> installApk(String path) async =>
      await channel.invokeMethod('installApk', {'path': path}) == true;

  /// 交给系统选择器用其他应用打开(按后缀推 MIME); false = 文件不存在
  static Future<bool> open(String path) async =>
      await channel.invokeMethod('open', {'path': path}) == true;
}
