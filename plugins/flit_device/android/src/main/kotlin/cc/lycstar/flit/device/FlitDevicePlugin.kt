package cc.lycstar.flit.device

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.net.InetSocketAddress
import java.net.ServerSocket

/**
 * 本机调试设备原生桥(flit/device): 无线调试端口 NSD 发现(本机过滤)、
 * 电池优化状态与申请。
 */
class FlitDevicePlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val discoveries = mutableSetOf<AdbDiscovery>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flit/device")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        synchronized(discoveries) { discoveries.toList() }.forEach { it.finish() }
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
        when (call.method) {
            "discoverAdb" -> {
                val service = call.argument<String>("service") ?: "_adb-tls-connect._tcp"
                val timeoutMs = call.argument<Number>("timeoutMs")?.toLong() ?: 6000L
                val nsd = context.getSystemService(Context.NSD_SERVICE) as? NsdManager
                if (nsd == null) {
                    result.success(emptyList<Map<String, Any?>>())
                    return
                }
                val discovery = AdbDiscovery(nsd, service, timeoutMs, result)
                synchronized(discoveries) { discoveries += discovery }
                discovery.start()
            }
            "isIgnoringBatteryOptimizations" -> result.success(ignoringBatteryOptimizations())
            "requestIgnoreBatteryOptimizations" -> {
                if (ignoringBatteryOptimizations()) {
                    result.success(true)
                    return
                }
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                runCatching { (activity ?: context).startActivity(intent) }
                result.success(false) // 用户还要在系统确认框里点"允许"
            }
            else -> result.notImplemented()
        }
    }

    /** MIUI 等系统会冻结后台应用/限制不可见时的网络, 配对发现依赖本机网络 */
    private fun ignoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < 23) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    /**
     * adbd 的无线调试监听绑在所有接口上: 本机绑 127.0.0.1:port 失败 = 它在听(接受);
     * 绑成功 = 本机没人听 = 同网段别的设备的广播(拒绝)。
     * 不比对网卡地址: 代理/VPN 的 TUN 接口会让地址比对失真(Shizuku 同款判据)。
     */
    private fun listeningLocally(port: Int): Boolean = try {
        ServerSocket().use { it.bind(InetSocketAddress("127.0.0.1", port), 1) }
        false
    } catch (_: IOException) {
        true
    }

    /**
     * 一次无线调试端口发现(NSD, Shizuku 同款): 持续发现直到超时, 每个解析出的
     * 服务用"本机端口占用"验证后收集; 每次调用独立状态, 可与别的发现并行。
     */
    private inner class AdbDiscovery(
        private val nsd: NsdManager,
        private val service: String,
        timeoutMs: Long,
        private val result: MethodChannel.Result,
    ) : NsdManager.DiscoveryListener {
        private val found = mutableListOf<Map<String, Any?>>()
        private val seen = HashSet<String>()
        private val queue = ArrayDeque<NsdServiceInfo>()
        private var resolving = false
        private var replied = false
        private val timeout = Runnable { finish() }

        init {
            mainHandler.postDelayed(timeout, timeoutMs)
        }

        fun start() {
            runCatching { nsd.discoverServices(service, NsdManager.PROTOCOL_DNS_SD, this) }
                .onFailure { finish() }
        }

        /** 只回复一次; 停止发现与回复都回主线程(Result 只能在主线程用) */
        fun finish() {
            synchronized(this) {
                if (replied) return
                replied = true
            }
            mainHandler.post {
                mainHandler.removeCallbacks(timeout)
                runCatching { nsd.stopServiceDiscovery(this) }
                synchronized(discoveries) { discoveries -= this }
                runCatching { result.success(synchronized(found) { found.toList() }) }
            }
        }

        override fun onServiceFound(info: NsdServiceInfo) {
            // Android 12 之前同一时刻只能有一个 resolve, 并发会 FAILURE_ALREADY_ACTIVE
            // 直接丢掉服务(多台设备在同一网段时会漏掉本机): 排队串行解析
            synchronized(queue) { queue.addLast(info) }
            resolveNext()
        }

        private fun resolveNext() {
            val next = synchronized(queue) {
                if (resolving) return
                val info = queue.removeFirstOrNull() ?: return
                resolving = true
                info
            }
            runCatching {
                nsd.resolveService(next, object : NsdManager.ResolveListener {
                    override fun onServiceResolved(resolved: NsdServiceInfo) {
                        accept(resolved)
                        resolveDone()
                    }

                    override fun onResolveFailed(info: NsdServiceInfo, errorCode: Int) = resolveDone()
                })
            }.onFailure { resolveDone() }
        }

        private fun resolveDone() {
            synchronized(queue) { resolving = false }
            resolveNext()
        }

        private fun accept(resolved: NsdServiceInfo) {
            val host = resolved.host?.hostAddress ?: return
            val port = resolved.port
            if (!listeningLocally(port)) return
            synchronized(seen) { if (!seen.add("$host:$port")) return }
            synchronized(found) { found += mapOf("host" to host, "port" to port) }
        }

        override fun onServiceLost(info: NsdServiceInfo) {}
        override fun onDiscoveryStarted(serviceType: String) {}
        override fun onDiscoveryStopped(serviceType: String) {}
        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) = finish()
        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
    }
}
