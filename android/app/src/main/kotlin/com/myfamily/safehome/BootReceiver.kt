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
        // ứng dụng tự chạy trong lần khởi động hiện tại.
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
        val brandName = context.getString(R.string.app_name)

        val manager =
            context.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                bootChannelName(brandName),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description =
                    bootChannelDescription(brandName)
            }

            manager.createNotificationChannel(channel)
        }

        val notification =
            NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(brandName)
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

    private fun bootChannelName(brandName: String): String {
        return when (Locale.getDefault().language) {
            "vi" -> "Khởi động $brandName"
            "zh" -> "$brandName 启动"
            "ko" -> "$brandName 시작"
            "ja" -> "$brandName 起動"
            "de" -> "$brandName-Start"
            "ru" -> "Запуск $brandName"
            "fr" -> "Démarrage de $brandName"
            "es" -> "Inicio de $brandName"
            "id" -> "Mulai $brandName"
            "th" -> "การเริ่ม $brandName"
            "ms" -> "Permulaan $brandName"
            "fil" -> "Pagsisimula ng $brandName"
            "km" -> "ការចាប់ផ្ដើម $brandName"
            "my" -> "$brandName စတင်ခြင်း"
            "lo" -> "ການເລີ່ມ $brandName"
            else -> "$brandName startup"
        }
    }

    private fun bootChannelDescription(brandName: String): String {
        return when (Locale.getDefault().language) {
            "vi" -> "Thông báo $brandName đã tự khởi chạy"
            "en" -> "$brandName auto-start notification"
            "zh" -> "$brandName 自动启动通知"
            "ko" -> "$brandName 자동 시작 알림"
            "ja" -> "$brandName 自動起動通知"
            "de" -> "$brandName Autostart-Benachrichtigung"
            "ru" -> "Уведомление об автозапуске $brandName"
            "fr" -> "Notification de démarrage automatique $brandName"
            "es" -> "Notificación de inicio automático de $brandName"
            "id" -> "Notifikasi mulai otomatis $brandName"
            "th" -> "การแจ้งเตือนการเริ่มอัตโนมัติของ $brandName"
            "ms" -> "Pemberitahuan mula automatik $brandName"
            "fil" -> "Notipikasyon ng awtomatikong pagsisimula ng $brandName"
            "km" -> "សេចក្តីជូនដំណឹងអំពីការចាប់ផ្ដើមស្វ័យប្រវត្តិរបស់ $brandName"
            "my" -> "$brandName အလိုအလျောက်စတင်မှု အသိပေးချက်"
            "lo" -> "ແຈ້ງເຕືອນການເລີ່ມອັດຕະໂນມັດ $brandName"
            else -> "$brandName auto-start notification"
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
            "th" -> "พร้อมติดตามการป้องกันอัตโนมัติ"
            "ms" -> "Sedia memantau perlindungan automatik"
            "fil" -> "Handang subaybayan ang awtomatikong proteksiyon"
            "km" -> "រួចរាល់ដើម្បីតាមដានការការពារស្វ័យប្រវត្តិ"
            "my" -> "အလိုအလျောက်ကာကွယ်မှုကို စောင့်ကြည့်ရန် အသင့်ဖြစ်ပါပြီ"
            "lo" -> "ພ້ອມຕິດຕາມການປ້ອງກັນອັດຕະໂນມັດ"
            else -> "Ready to monitor automatic protection"
        }
    }
}
