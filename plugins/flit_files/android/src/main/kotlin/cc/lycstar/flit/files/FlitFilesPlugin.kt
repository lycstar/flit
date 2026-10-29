package cc.lycstar.flit.files

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** 文件与系统交互原生桥(flit/files): 系统分享面板、系统安装器 */
class FlitFilesPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flit/files")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path") ?: ""
        val work: (() -> Boolean) = when (call.method) {
            "share" -> ({ share(File(path)) })
            "installApk" -> ({ installApk(File(path)) })
            "open" -> ({ openWith(File(path)) })
            else -> {
                result.notImplemented()
                return
            }
        }
        // FileProvider 要解析 paths 配置、查文件: 放后台线程, 回复回主线程
        Thread {
            val ok = runCatching(work).getOrElse { false }
            mainHandler.post { runCatching { result.success(ok) } }
        }.start()
    }

    /** 有 Activity 从它起(分享面板盖在本应用上); 没有就只能新任务 */
    private fun launch(intent: Intent) {
        val host = activity
        if (host != null) {
            host.startActivity(intent)
        } else {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    private fun contentUri(file: File): Uri =
        FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

    private fun mimeOf(file: File): String =
        MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(file.extension.lowercase())
            ?: "application/octet-stream"

    private fun share(file: File): Boolean {
        if (!file.exists()) return false
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mimeOf(file)
            putExtra(Intent.EXTRA_STREAM, contentUri(file))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        launch(Intent.createChooser(send, file.name))
        return true
    }

    /** 用其他应用打开: 走选择器, 没有能处理的应用时系统自己提示 */
    private fun openWith(file: File): Boolean {
        if (!file.exists()) return false
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri(file), mimeOf(file))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        launch(Intent.createChooser(view, file.name))
        return true
    }

    private fun installApk(file: File): Boolean {
        if (!file.exists()) return false
        if (Build.VERSION.SDK_INT >= 26 && !context.packageManager.canRequestPackageInstalls()) {
            // 先去系统设置授权"安装未知应用", 授权后用户重试
            launch(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return false
        }
        launch(
            Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                setDataAndType(contentUri(file), "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
        return true
    }
}
