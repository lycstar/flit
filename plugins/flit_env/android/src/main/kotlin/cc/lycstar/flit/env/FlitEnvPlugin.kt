package cc.lycstar.flit.env

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Termux 运行环境原生桥(flit/env): bootstrap 部署与状态、一次性 exec、
 * 文件 sha256、系统代理跟随、系统页/浏览器跳转。
 * 交互终端由 Dart 侧 flutter_pty 直连 bash, 原生不持有 shell。
 */
class FlitEnvPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var proxyWatcher: ConnectivityManager.NetworkCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        FlitEnv.init(context)
        channel = MethodChannel(binding.binaryMessenger, "flit/env")
        channel.setMethodCallHandler(this)
        watchSystemProxy()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        proxyWatcher?.let { cb ->
            runCatching {
                context.getSystemService(ConnectivityManager::class.java)
                    ?.unregisterNetworkCallback(cb)
            }
        }
        proxyWatcher = null
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

    /**
     * 系统代理实时跟随: 默认网络的代理变化(开关代理软件、改 Wi-Fi 代理)时
     * 把最新地址推给 Dart(onSystemProxyChanged), 不用等 app 重启。
     */
    private fun watchSystemProxy() {
        val cm = context.getSystemService(ConnectivityManager::class.java) ?: return
        val push: (String?) -> Unit = { addr ->
            mainHandler.post { runCatching { channel.invokeMethod("onSystemProxyChanged", addr) } }
        }
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onLinkPropertiesChanged(network: Network, lp: LinkProperties) {
                push(lp.httpProxy?.let { "${it.host}:${it.port}" } ?: systemProxy())
            }

            override fun onAvailable(network: Network) = push(systemProxy())

            override fun onLost(network: Network) = push(null)
        }
        if (runCatching { cm.registerDefaultNetworkCallback(cb) }.isSuccess) proxyWatcher = cb
    }

    /** Android 系统代理(Wi-Fi 代理 / clash 仅代理模式); 未设置返回 null */
    private fun systemProxy(): String? {
        val host = System.getProperty("http.proxyHost")
        val port = System.getProperty("http.proxyPort")
        return if (!host.isNullOrBlank() && !port.isNullOrBlank()) "$host:$port" else null
    }

    /** 有 Activity 从它起(返回键回到本应用); 没有就只能新任务 */
    private fun launch(intent: Intent): Boolean = runCatching {
        val host = activity
        if (host != null) {
            host.startActivity(intent)
        } else {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        true
    }.getOrDefault(false)

    /** 耗时工作放后台线程, 回复必须回主线程 */
    private fun background(work: () -> Unit) = Thread(work).start()

    private fun reply(block: () -> Unit) {
        mainHandler.post { runCatching(block) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "deployBootstrap" -> {
                // 全量解压下载的 bootstrap; 后台线程防 ANR
                val zip = call.argument<String>("zipPath") ?: ""
                background {
                    val err = runCatching { FlitEnv.bootstrapInstallFrom(zip) }
                        .getOrElse { it.message ?: "unknown" }
                    reply {
                        if (err == null) result.success(true)
                        else result.error("BOOTSTRAP_INSTALL", err, null)
                    }
                }
            }
            "bootstrapStatus" -> result.success(
                mapOf(
                    "bootstrapped" to FlitEnv.isBootstrapped,
                    "prefix" to FlitEnv.prefix.absolutePath,
                    "home" to FlitEnv.home.absolutePath,
                    "tz" to java.util.TimeZone.getDefault().id,
                )
            )
            "systemProxy" -> result.success(systemProxy())
            "openSettings" -> {
                // 直达系统设置页(如开发者选项)。配对码等场景要在系统页与本应用间
                // 来回切换, 必须新任务窗口, 同窗口会把本应用顶掉
                val action = call.argument<String>("action") ?: ""
                result.success(launch(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)))
            }
            "openUrl" -> {
                // git 认证等场景唤起系统浏览器(终端进程无法自己打开 Intent)
                val url = call.argument<String>("url") ?: ""
                result.success(launch(Intent(Intent.ACTION_VIEW, Uri.parse(url))))
            }
            "exec" -> {
                // 一次性执行(管道式); 超时可选(默认 120s)
                val cmd = call.argument<String>("cmd") ?: ""
                val timeoutMs = call.argument<Number>("timeoutMs")?.toLong() ?: 120_000L
                background {
                    val payload = runCatching {
                        val (code, out) = FlitEnv.exec(cmd, timeoutMs)
                        mapOf("exitCode" to code, "output" to out)
                    }.getOrElse { e ->
                        mapOf("exitCode" to -1, "output" to "exec failed: ${e.message}")
                    }
                    reply { result.success(payload) }
                }
            }
            "sha256" -> {
                // 大文件分块哈希(产物校验)
                val path = call.argument<String>("path") ?: ""
                background {
                    val hex = runCatching { sha256(File(path)) }.getOrElse { "" }
                    reply { result.success(hex) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun sha256(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buf = ByteArray(1 shl 20)
            while (true) {
                val n = input.read(buf)
                if (n == -1) break
                md.update(buf, 0, n)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }
}
