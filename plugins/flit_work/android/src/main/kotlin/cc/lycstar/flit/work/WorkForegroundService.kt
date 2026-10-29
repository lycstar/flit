package cc.lycstar.flit.work

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * 终端/构建保活前台服务(specialUse): MIUI 等系统会冻结后台应用,
 * 长构建与终端会话需要前台服务保活。工作中有会话时启动, 空闲时停止。
 */
class WorkForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "flit_work"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "cc.lycstar.flit.work.START"
        const val ACTION_STOP = "cc.lycstar.flit.work.STOP"
        const val EXTRA_TITLE = "title"

        fun start(context: Context, title: String) {
            val intent = Intent(context, WorkForegroundService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TITLE, title)
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.startService(
                Intent(context, WorkForegroundService::class.java).setAction(ACTION_STOP)
            )
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Flit 工作中", NotificationManager.IMPORTANCE_LOW
            )
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun notification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.flit_work_notification)
            .setContentTitle("Flit 任务运行中")
            .setContentText("终端会话与构建运行中")
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setOngoing(true)
            .build()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Flit 工作中"
        ensureChannel()
        val notification = notification()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        // 进程被杀即会话全没, 服务不可独自复活(否则留一条僵尸"运行中"通知)
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
