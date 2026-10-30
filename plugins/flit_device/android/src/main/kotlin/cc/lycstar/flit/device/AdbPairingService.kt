package cc.lycstar.flit.device

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import cc.lycstar.flit.env.FlitEnv
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** Notification reply keeps Android's pairing dialog visible. Pair with the
 * SAME SDK adb, HOME and key as Flutter/terminal commands, never a second key.
 * Codes are passed via stdin, never persisted or included in logs/intents. */
class AdbPairingService : Service() {
    companion object {
        private const val CHANNEL = "flit_adb_pairing"
        private const val ID = 1042
        private const val CODE = "pairing_code"
        @Volatile private var running = false
        private fun prefs(context: Context) = context.getSharedPreferences("adb_pairing", Context.MODE_PRIVATE)
        fun status(context: Context): Map<String, Any> {
            val saved = prefs(context)
            val state = saved.getString("state", "idle") ?: "idle"
            val interrupted = !running && state in setOf("searching", "ready", "pairing")
            return mapOf("state" to if (interrupted) "failed" else state,
                "message" to if (interrupted) "配对已中断，请重试" else (saved.getString("message", "") ?: ""),
                "port" to saved.getInt("port", -1), "revision" to saved.getLong("revision", 0))
        }
        fun availability(context: Context): String? {
            FlitEnv.init(context)
            if (!File(FlitEnv.home, "toolchains/android-sdk/platform-tools/adb").canExecute()) return "请先安装 Android Platform Tools"
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) return "请先在系统设置中允许 Flit 通知，再开始配对"
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(CHANNEL, "无线调试配对", NotificationManager.IMPORTANCE_HIGH).apply {
                    setSound(null, null); setShowBadge(false)
                })
                if (manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) return "请在系统通知设置中开启“无线调试配对”通知"
            }
            return null
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var scanner: AdbDiscovery? = null
    private var port = -1
    private var serviceName: String? = null
    @Volatile private var process: Process? = null
    private var working = false
    @Volatile private var closed = false
    private val deadline = Runnable { finish(false, "等待配对超时，请重新开始") }

    override fun onBind(intent: Intent?): IBinder? = null
    override fun onCreate() {
        super.onCreate()
        FlitEnv.init(this)
        running = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop") { finish(false, "已取消配对"); return START_NOT_STICKY }
        if (Build.VERSION.SDK_INT < 30) { stopSelf(); return START_NOT_STICKY }
        if (intent?.action == "reply") {
            val code = RemoteInput.getResultsFromIntent(intent)?.getCharSequence(CODE)?.toString()?.trim().orEmpty()
            val requestedPort = intent.getIntExtra("port", -1)
            // The service is deliberately not redelivered: a killed process or a
            // lost/changed advertisement must not reuse a stale pairing endpoint.
            if (!running || closed || port < 1 || requestedPort != port) {
                finish(false, "配对端口已失效，请重新开始")
            } else if (!working) pair(code)
            return START_NOT_STICKY
        }
        if (scanner != null || working) return START_NOT_STICKY
        val problem = availability(this)
        if (problem != null) { finish(false, problem); return START_NOT_STICKY }
        save("searching", "在无线调试中打开“使用配对码配对设备”")
        try {
            startForeground(ID, notification("正在寻找配对端口", "打开系统配对码窗口，发现后可在此输入配对码"))
        } catch (_: Exception) {
            save("failed", "无法启动配对通知，请检查通知及后台运行权限")
            closed = true
            stopSelf()
            return START_NOT_STICKY
        }
        main.postDelayed(deadline, 180000)
        scanner = AdbDiscovery(this, "_adb-tls-pairing._tcp",
            onFound = { info ->
                if (!working && !closed) {
                    port = info.port; serviceName = info.serviceName
                    save("ready", "已找到端口 $port，请在通知中输入 6 位配对码")
                    update("已找到配对端口 $port", "保持系统配对窗口开启，在此输入配对码", input = true)
                }
            },
            onLost = { name ->
                if (!working && name == serviceName) {
                    port = -1; serviceName = null
                    save("searching", "配对窗口已关闭，请重新打开")
                    update("正在寻找配对端口", "请重新打开系统配对码窗口")
                }
            }, onError = { finish(false, it) }).also { it.start() }
        return START_NOT_STICKY
    }

    private fun pair(code: String) {
        if (!Regex("^[0-9]{6}$").matches(code)) {
            update("请输入 6 位配对码", "配对码位于系统配对窗口中", input = true)
            return
        }
        working = true
        save("pairing", "正在配对…")
        update("正在配对", "请保持系统配对窗口开启")
        val targetPort = port
        worker.execute {
            val result = runCatching {
                val builder = ProcessBuilder(File(FlitEnv.prefix, "bin/bash").absolutePath, "-c",
                    "set -e; . \"\$HOME/.flit/env.sh\"; exec \"\$HOME/toolchains/android-sdk/platform-tools/adb\" pair 127.0.0.1:$targetPort")
                    .directory(FlitEnv.home).redirectErrorStream(true)
                builder.environment().putAll(FlitEnv.environment())
                val client = builder.start()
                process = client
                // stopService can race process creation.
                if (closed) { client.destroyForcibly(); return@runCatching false }
                client.outputStream.bufferedWriter().use { it.write(code); it.newLine(); it.flush() }
                // Pair output is tiny; redirect to a bounded in-memory buffer and
                // drain concurrently so neither pipe capacity nor a hung daemon blocks timeout.
                val output = StringBuilder()
                val reader = Thread {
                    runCatching { client.inputStream.bufferedReader().useLines { lines ->
                        lines.forEach { line -> synchronized(output) {
                            if (output.length < 8192) output.append(line.take(512)).append('\n')
                        } }
                    } }
                }.apply { isDaemon = true; start() }
                val ended = client.waitFor(30, TimeUnit.SECONDS)
                if (!ended) client.destroyForcibly()
                reader.join(1000)
                ended && client.exitValue() == 0 && synchronized(output) { output.contains("Successfully paired to") }
            }
            process?.destroy(); process = null
            main.post {
                if (!closed) finish(result.getOrDefault(false),
                    if (result.getOrDefault(false)) "配对成功，返回 Flit 自动连接" else "配对失败，请重新打开配对窗口并核对配对码")
            }
        }
    }

    private fun save(state: String, message: String) {
        prefs(this).edit().putString("state", state).putString("message", message)
            .putInt("port", port).putLong("revision", System.currentTimeMillis()).apply()
    }
    private fun finish(success: Boolean, message: String) {
        if (closed) return
        save(if (success) "success" else "failed", message)
        closed = true
        scanner?.stop()
        main.removeCallbacks(deadline)
        process?.destroyForcibly()
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (Build.VERSION.SDK_INT >= 26 && getSystemService(NotificationManager::class.java).areNotificationsEnabled()) {
            getSystemService(NotificationManager::class.java).notify(ID, notification(
                if (success) "配对成功" else "配对未完成", message, completed = true))
        }
        stopSelf()
    }
    private fun update(title: String, text: String, input: Boolean = false) {
        getSystemService(NotificationManager::class.java).notify(ID, notification(title, text, input))
    }
    private fun notification(title: String, text: String, input: Boolean = false, completed: Boolean = false): Notification {
        val builder = Notification.Builder(this, CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentTitle(title).setContentText(text).setStyle(Notification.BigTextStyle().bigText(text))
            .setOnlyAlertOnce(true).setOngoing(!completed).setAutoCancel(completed)
        packageManager.getLaunchIntentForPackage(packageName)?.let {
            builder.setContentIntent(PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        }
        if (!completed) {
            val stop = PendingIntent.getService(this, 1,
                Intent(this, AdbPairingService::class.java).setAction("stop"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(Notification.Action.Builder(null, "取消", stop).build())
        }
        if (input) {
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
            val reply = PendingIntent.getService(this, 2,
                Intent(this, AdbPairingService::class.java).setAction("reply").putExtra("port", port), flags)
            builder.addAction(Notification.Action.Builder(null, "输入配对码", reply)
                .addRemoteInput(RemoteInput.Builder(CODE).setLabel("6 位配对码").build()).build())
        }
        return builder.build()
    }
    override fun onDestroy() {
        if (!closed) save("idle", "已取消配对")
        closed = true; running = false
        scanner?.stop(); main.removeCallbacksAndMessages(null)
        process?.destroyForcibly(); worker.shutdownNow()
        super.onDestroy()
    }
}
