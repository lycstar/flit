package cc.lycstar.flit.lsp

import android.os.Handler
import android.os.Looper
import cc.lycstar.flit.env.FlitEnv
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 官方 dart language-server 的进程传输(flit/lsp + flit/lspEvents)。
 * 原生只管进程与 JSON-RPC 帧; 握手与协议语义在 Dart 侧 LspClient。
 */
class FlitLspPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private var sink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FlitEnv.init(binding.applicationContext)
        channel = MethodChannel(binding.binaryMessenger, "flit/lsp")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "flit/lspEvents")
        events.setStreamHandler(this)
        // 分析器通知流(publishDiagnostics 等); EventSink 只能在主线程用
        LspServer.onNotify = { json ->
            mainHandler.post { runCatching { sink?.success(json) } }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        LspServer.onNotify = null
        LspServer.stop()
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                // 拉起官方分析器(Flutter SDK 内置), 工作目录 = 工程根
                val root = call.argument<String>("rootPath") ?: ""
                val session = call.argument<Int>("session") ?: 0
                Thread {
                    val dartBin = File(
                        FlitEnv.prefix,
                        "opt/flutter/bin/cache/dart-sdk/bin/dart",
                    ).absolutePath
                    val ok = runCatching { LspServer.start(dartBin, root, session) }
                        .getOrElse { false }
                    mainHandler.post { runCatching { result.success(ok) } }
                }.start()
            }
            "request" -> {
                val method = call.argument<String>("method") ?: ""
                val params = call.argument<String>("params") ?: ""
                val ok = LspServer.request(method, params) { json ->
                    mainHandler.post { runCatching { result.success(json) } }
                }
                if (!ok) runCatching { result.success(null) }
            }
            "notify" -> {
                val method = call.argument<String>("method") ?: ""
                val params = call.argument<String>("params") ?: ""
                result.success(LspServer.notify(method, params))
            }
            "stop" -> {
                LspServer.stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
