package com.myfamily.safehome

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import java.util.Locale

class BootReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME = "safehome_monitoring"
        const val KEY_BOOT_RECEIVER_CONFIRMED =
            "boot_receiver_confirmed"
        const val KEY_CONFIRMED_BOOT_COUNT =
            "confirmed_boot_count"
        const val KEY_LAST_BOOT_RECEIVER_AT =
            "last_boot_receiver_at"
        const val KEY_LAST_BOOT_ACTION =
            "last_boot_action"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        val isBootAction =
            action == Intent.ACTION_BOOT_COMPLETED ||
                    action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
                    action == "android.intent.action.QUICKBOOT_POWERON"

        if (!isBootAction) {
            return
        }

        // Dùng vùng lưu trữ có thể truy cập ngay cả khi máy
        // chưa được mở khóa sau khi khởi động.
        val storageContext =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }

        val bootCount =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Settings.Global.getInt(
                    context.contentResolver,
                    Settings.Global.BOOT_COUNT,
                    -1
                )
            } else {
                -1
            }

        // Đây là bằng chứng thực tế rằng Android đã cho phép
        // SafeHome tự chạy trong lần khởi động hiện tại.
        storageContext
            .getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )
            .edit()
            .putBoolean(
                KEY_BOOT_RECEIVER_CONFIRMED,
                true
            )
            .putInt(
                KEY_CONFIRMED_BOOT_COUNT,
                bootCount
            )
            .putLong(
                KEY_LAST_BOOT_RECEIVER_AT,
                System.currentTimeMillis()
            )
            .putString(
                KEY_LAST_BOOT_ACTION,
                action
            )
            .apply()

        showBootNotification(context)
    }

    private fun showBootNotification(context: Context) {
        val channelId = "safehome_boot_channel"

        val manager =
            context.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "SafeHome Boot",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description =
                    bootChannelDescription()
            }

            manager.createNotificationChannel(channel)
        }

        val notification =
            NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("SafeHome")
                .setContentText(
                    bootNotificationText()
                )
                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
                )
                .setAutoCancel(true)
                .build()

        manager.notify(999001, notification)
    }

    private fun bootChannelDescription(): String {
        return when (Locale.getDefault().language) {
            "vi" -> "Thông báo SafeHome đã tự khởi chạy"
            "en" -> "SafeHome auto-start notification"
            "zh" -> "SafeHome 自动启动通知"
            "ko" -> "SafeHome 자동 시작 알림"
            "ja" -> "SafeHome 自動起動通知"
            "de" -> "SafeHome Autostart-Benachrichtigung"
            "ru" -> "Уведомление об автозапуске SafeHome"
            "fr" -> "Notification de démarrage automatique SafeHome"
            "es" -> "Notificación de inicio automático de SafeHome"
            "id" -> "Notifikasi mulai otomatis SafeHome"
            else -> "Thông báo SafeHome đã tự khởi chạy"
        }
    }

    private fun bootNotificationText(): String {
        return when (Locale.getDefault().language) {
            "vi" -> "Đã sẵn sàng theo dõi bảo vệ tự động"
            "en" -> "Ready to monitor automatic protection"
            "zh" -> "已准备好监控自动保护"
            "ko" -> "자동 보호 모니터링 준비 완료"
            "ja" -> "自動保護の監視準備ができました"
            "de" -> "Bereit zur Überwachung des automatischen Schutzes"
            "ru" -> "Готово к мониторингу автоматической охраны"
            "fr" -> "Prêt à surveiller la protection automatique"
            "es" -> "Listo para supervisar la protección automática"
            "id" -> "Siap memantau perlindungan otomatis"
            else -> "Đã sẵn sàng theo dõi bảo vệ tự động"
        }
    }
}
