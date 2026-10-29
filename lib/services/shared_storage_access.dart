import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shared permission flow for the project location picker and the editor's
/// import browser. Declining it never blocks app-private project work.
class SharedStorageAccess {
  SharedStorageAccess._();

  static Future<bool> isGranted() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    return Permission.storage.isGranted;
  }

  static Future<bool> requestPermission() async {
    if (await isGranted()) return true;
    await Permission.manageExternalStorage.request();
    if (await isGranted()) return true;
    await Permission.storage.request();
    return isGranted();
  }

  static Future<bool> request(
    BuildContext context, {
    required String purpose,
  }) async {
    if (await isGranted()) return true;
    if (!context.mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('允许访问共享存储？'),
        content: Text(
          '$purpose\n\n'
          '授权后，Flit 可以访问共享存储中的文件。你也可以暂不授权，继续使用应用内项目目录；应用内文件不会显示在普通文件管理器中，卸载 Flit 时会一并删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('暂不授权'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续授权'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return false;

    final granted = await requestPermission();
    if (!context.mounted) return false;
    if (!granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未授予共享存储权限，仍可使用应用内项目目录')));
    }
    return granted;
  }
}
