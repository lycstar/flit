package cc.lycstar.flit.device

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
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

/**
 * 本机调试设备原生桥(flit/device): 无线调试端口 NSD 发现(本机过滤)、
 * 电池优化状态与申请。
 */
class FlitDevicePlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val discoveries = mutableSetOf<() -> Unit>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flit/device")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        discoveries.toList().forEach { it() }
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
                if (service !in setOf("_adb-tls-connect._tcp", "_adb-tls-pairing._tcp")) {
                    result.error("invalid_service", "不支持的扫描类型", null)
                    return
                }
                val timeoutMs = (call.argument<Number>("timeoutMs")?.toLong() ?: 6000L).coerceIn(1000, 30000)
                var replied = false
                lateinit var scanner: AdbDiscovery
                lateinit var cancel: () -> Unit
                var timeout: Runnable? = null
                fun finish(found: List<Map<String, Any>> = emptyList(), error: String? = null) {
                    if (replied) return
                    replied = true
                    timeout?.let { mainHandler.removeCallbacks(it) }
                    scanner.stop()
                    discoveries.remove(cancel)
                    if (error == null) result.success(found) else result.error("discovery_failed", error, null)
                }
                scanner = AdbDiscovery(context, service,
                    onFound = { info -> finish(listOf(mapOf("host" to "127.0.0.1", "port" to info.port))) },
                    onError = { finish(error = it) })
                cancel = { finish() }
                discoveries += cancel
                timeout = Runnable { finish() }
                mainHandler.postDelayed(timeout!!, timeoutMs)
                scanner.start()
            }
            "startPairing" -> {
                if (Build.VERSION.SDK_INT < 30) {
                    result.error("unsupported", "通知配对需要 Android 11 或更高版本", null)
                    return
                }
                val problem = AdbPairingService.availability(context)
                if (problem != null) { result.error("pairing_unavailable", problem, null); return }
                runCatching {
                    context.startForegroundService(Intent(context, AdbPairingService::class.java).setAction("start"))
                }.onSuccess { result.success(true) }
                    .onFailure { result.error("pairing_unavailable", it.message, null) }
            }
            "stopPairing" -> {
                context.stopService(Intent(context, AdbPairingService::class.java))
                result.success(true)
            }
            "pairingStatus" -> result.success(AdbPairingService.status(context))
            "pairingReadiness" -> result.success(mapOf(
                "supported" to (Build.VERSION.SDK_INT >= 30),
                "notificationsEnabled" to AdbPairingService.notificationsEnabled(context),
            ))
            "openWirelessSettings" -> {
                val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                    .putExtra(":settings:fragment_args_key", "toggle_adb_wireless")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                runCatching { (activity ?: context).startActivity(intent) }
                    .onSuccess { result.success(true) }
                    .onFailure { result.error("open_failed", it.message, null) }
            }

            "isIgnoringBatteryOptimizations" -> result.success(ignoringBatteryOptimizations())
            "openNotificationSettings" -> {
                // targetSdk 28 下系统不为 POST_NOTIFICATIONS 的运行时请求弹授权框,
                // 只能引导用户到通知设置页手动开关; API 26 以下无通知运行时权限,
                // 正常不会走到这里, 兜底跳应用详情页
                val intent = if (Build.VERSION.SDK_INT >= 26) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    }
                } else {
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${context.packageName}"),
                    )
                }.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                runCatching { (activity ?: context).startActivity(intent) }
                    .onSuccess { result.success(true) }
                    .onFailure { result.error("open_failed", it.message, null) }
            }
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

}
