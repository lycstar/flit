package cc.lycstar.flit.work

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
                CHANNEL_ID, nativeText(this, R.string.flit_work_0), NotificationManager.IMPORTANCE_LOW
            )
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun notification(): Notification {
        // 点击通知回到应用(singleTop 复用已有实例); 缺 NEW_TASK 时
        // Service 发出的 PendingIntent 点按会静默失败。
        val content = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.flit_work_notification)
            .setContentTitle(nativeText(this, R.string.flit_work_1))
            .setContentText(nativeText(this, R.string.flit_work_2))
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setOngoing(true)
        content?.let {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    this, 0, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            )
        }
        return builder.build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: nativeText(this, R.string.flit_work_0)
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
