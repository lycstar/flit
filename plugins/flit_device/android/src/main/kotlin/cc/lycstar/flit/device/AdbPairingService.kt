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
        /** Read-only check for the tutorial. Do not start discovery or create a channel here. */
        fun notificationsEnabled(context: Context): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java)
            return manager.areNotificationsEnabled() &&
                (Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)
        }
        fun status(context: Context): Map<String, Any> {
            val saved = prefs(context)
            val state = saved.getString("state", "idle") ?: "idle"
            val interrupted = !running && state in setOf("searching", "ready", "pairing")
            return mapOf("state" to if (interrupted) "failed" else state,
                "message" to if (interrupted) nativeText(context, R.string.flit_device_5) else (saved.getString("message", "") ?: ""),
                "port" to saved.getInt("port", -1), "revision" to saved.getLong("revision", 0))
        }
        fun availability(context: Context): String? {
            FlitEnv.init(context)
            if (!File(FlitEnv.home, "toolchains/android-sdk/platform-tools/adb").canExecute()) return nativeText(context, R.string.flit_device_6)
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) return nativeText(context, R.string.flit_device_7)
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(CHANNEL, nativeText(context, R.string.flit_device_8), NotificationManager.IMPORTANCE_HIGH).apply {
                    setSound(null, null); setShowBadge(false)
                })
                if (manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) return nativeText(context, R.string.flit_device_9)
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
    private val deadline = Runnable { finish(false, nativeText(this, R.string.flit_device_10)) }

    override fun onBind(intent: Intent?): IBinder? = null
    override fun onCreate() {
        super.onCreate()
        FlitEnv.init(this)
        running = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop") { finish(false, nativeText(this, R.string.flit_device_11)); return START_NOT_STICKY }
        if (Build.VERSION.SDK_INT < 30) { stopSelf(); return START_NOT_STICKY }
        if (intent?.action == "reply") {
            val code = RemoteInput.getResultsFromIntent(intent)?.getCharSequence(CODE)?.toString()?.trim().orEmpty()
            val requestedPort = intent.getIntExtra("port", -1)
            // The service is deliberately not redelivered: a killed process or a
            // lost/changed advertisement must not reuse a stale pairing endpoint.
            if (!running || closed || port < 1 || requestedPort != port) {
                finish(false, nativeText(this, R.string.flit_device_12))
            } else if (!working) pair(code)
            return START_NOT_STICKY
        }
        if (scanner != null || working) return START_NOT_STICKY
        val problem = availability(this)
        if (problem != null) { finish(false, problem); return START_NOT_STICKY }
        save("searching", nativeText(this, R.string.flit_device_13))
        try {
            startForeground(ID, notification(nativeText(this, R.string.flit_device_14), nativeText(this, R.string.flit_device_15)))
        } catch (_: Exception) {
            save("failed", nativeText(this, R.string.flit_device_16))
            closed = true
            stopSelf()
            return START_NOT_STICKY
        }
        main.postDelayed(deadline, 180000)
        scanner = AdbDiscovery(this, "_adb-tls-pairing._tcp",
            onFound = { info ->
                if (!working && !closed) {
                    port = info.port; serviceName = info.serviceName
                    save("ready", nativeText(this, R.string.flit_device_17 , port))
                    update(nativeText(this, R.string.flit_device_18 , port), nativeText(this, R.string.flit_device_19), input = true)
                }
            },
            onLost = { name ->
                if (!working && name == serviceName) {
                    port = -1; serviceName = null
                    save("searching", nativeText(this, R.string.flit_device_20))
                    update(nativeText(this, R.string.flit_device_14), nativeText(this, R.string.flit_device_21))
                }
            }, onError = { finish(false, it) }).also { it.start() }
        return START_NOT_STICKY
    }

    private fun pair(code: String) {
        if (!Regex("^[0-9]{6}$").matches(code)) {
            update(nativeText(this, R.string.flit_device_22), nativeText(this, R.string.flit_device_23), input = true)
            return
        }
        working = true
        save("pairing", nativeText(this, R.string.flit_device_24))
        update(nativeText(this, R.string.flit_device_25), nativeText(this, R.string.flit_device_26))
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
                    if (result.getOrDefault(false)) nativeText(this, R.string.flit_device_27) else nativeText(this, R.string.flit_device_28))
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
                if (success) nativeText(this, R.string.flit_device_29) else nativeText(this, R.string.flit_device_30), message, completed = true))
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
            // Service 发出的 PendingIntent 必须 NEW_TASK 才能起 Activity,
            // singleTop 保证回到已有实例而不是重建。
            it.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            builder.setContentIntent(
                PendingIntent.getActivity(
                    this, 0, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            )
        }
        if (!completed) {
            val stop = PendingIntent.getService(this, 1,
                Intent(this, AdbPairingService::class.java).setAction("stop"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(Notification.Action.Builder(null, nativeText(this, R.string.flit_device_31), stop).build())
        }
        if (input) {
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
            val reply = PendingIntent.getService(this, 2,
                Intent(this, AdbPairingService::class.java).setAction("reply").putExtra("port", port), flags)
            builder.addAction(Notification.Action.Builder(null, nativeText(this, R.string.flit_device_32), reply)
                .addRemoteInput(RemoteInput.Builder(CODE).setLabel(nativeText(this, R.string.flit_device_33)).build()).build())
        }
        return builder.build()
    }
    override fun onDestroy() {
        if (!closed) save("idle", nativeText(this, R.string.flit_device_11))
        closed = true; running = false
        scanner?.stop(); main.removeCallbacksAndMessages(null)
        process?.destroyForcibly(); worker.shutdownNow()
        super.onDestroy()
    }
}
