package com.myfamily.safehome

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat

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
                    "Thông báo SafeHome đã tự khởi chạy"
            }

            manager.createNotificationChannel(channel)
        }

        val notification =
            NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("SafeHome")
                .setContentText(
                    "Đã sẵn sàng theo dõi bảo vệ tự động"
                )
                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
                )
                .setAutoCancel(true)
                .build()

        manager.notify(999001, notification)
    }
}