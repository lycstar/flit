package cc.lycstar.flit.work

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** 终端/构建保活原生桥(flit/work): 启停前台服务 */
class FlitWorkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flit/work")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val title = call.argument<String>("title") ?: "Flit 工作中"
                runCatching { WorkForegroundService.start(context, title) }
                result.success(true)
            }
            "stop" -> {
                runCatching { WorkForegroundService.stop(context) }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
