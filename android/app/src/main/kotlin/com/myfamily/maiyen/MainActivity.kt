package com.myfamily.maiyen

import android.app.ActivityManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MaiYenNativeIdentifiers.NATIVE_ALARM_PERMISSION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    result.success(canUseFullScreenIntent())
                }

                "openFullScreenIntentSettings" -> {
                    openFullScreenIntentSettings()
                    result.success(true)
                }

                "isAlarmScreenLaunch" -> {
                    result.success(isAlarmScreenLaunch())
                }

                MaiYenNativeIdentifiers.GET_ACTION_METHOD -> {
                    result.success(readMaiYenAction(intent))
                }

                // Kiểm tra MaiYen đã được đặt thành
                // Không hạn chế pin hay chưa.
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }

                // Kiểm tra Android có đang hạn chế app chạy nền không.
                "isBackgroundRestricted" -> {
                    result.success(isBackgroundRestricted())
                }

                // Mở danh sách ứng dụng được miễn tối ưu pin.
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }

                // Mở trang chi tiết MaiYen.
                // Người dùng có thể bật Tự khởi chạy trên máy hỗ trợ.
                "openAppDetailsSettings" -> {
                    openAppDetailsSettings()
                    result.success(true)
                }
                "isBootReceiverConfirmed" -> {
                    result.success(
                        isBootReceiverConfirmedForCurrentBoot()
                    )
                }
                "getDeviceManufacturer" -> {
                    result.success(
                        Build.MANUFACTURER
                            ?.trim()
                            ?.lowercase()
                            ?: ""
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        syncAlarmScreenMode(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        syncAlarmScreenMode(intent)
    }

    override fun onResume() {
        super.onResume()
        if (!isAlarmLaunchIntent(intent) || !isAlarmScreenLaunch()) {
            disableAlarmScreenMode()
        }
    }

    private fun syncAlarmScreenMode(launchIntent: Intent?) {
        if (isAlarmLaunchIntent(launchIntent)) {
            enableAlarmScreenMode()
        } else {
            disableAlarmScreenMode()
        }
    }

    private fun enableAlarmScreenMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
    }

    private fun disableAlarmScreenMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }

        window.clearFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
    }

    private fun isAlarmLaunchIntent(launchIntent: Intent?): Boolean {
        if (launchIntent == null) {
            return false
        }

        if (isAlarmLaunchValue(launchIntent.action)) {
            return true
        }

        if (isAlarmLaunchValue(launchIntent.dataString)) {
            return true
        }

        if (isAlarmLaunchValue(readMaiYenAction(launchIntent))) {
            return true
        }

        val extras = launchIntent.extras ?: return false

        for (key in extras.keySet()) {
            val value = extras.get(key)?.toString()

            if (isAlarmLaunchValue(value)) {
                return true
            }

            val cleanKey = key.trim().lowercase()

            if ((cleanKey.contains("alarm") ||
                        cleanKey.contains("siren") ||
                        cleanKey.contains("fullscreen")) &&
                value != "false"
            ) {
                return true
            }
        }

        return false
    }

    private fun readMaiYenAction(sourceIntent: Intent?): String {
        if (sourceIntent == null) {
            return ""
        }

        return sourceIntent
            .getStringExtra(MaiYenNativeIdentifiers.ACTION_EXTRA)
            ?.trim()
            .orEmpty()
    }

    private fun isAlarmLaunchValue(rawValue: String?): Boolean {
        val value = rawValue
            ?.trim()
            ?.lowercase()
            ?: return false

        return value == "alarm" ||
                value == "siren" ||
                value == "alarm_siren" ||
                value == "fullscreen_alarm" ||
                value == "alarm_fullscreen" ||
                value.startsWith("alarm_siren::") ||
                value.startsWith("priority_alarm::") ||
                value.startsWith("alarm_summary|")
    }

    private fun isAlarmScreenLaunch(): Boolean {
        val keyguardManager =
            getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

        val powerManager =
            getSystemService(Context.POWER_SERVICE) as PowerManager

        return keyguardManager.isKeyguardLocked ||
                !powerManager.isInteractive
    }

    private fun canUseFullScreenIntent(): Boolean {
        return if (Build.VERSION.SDK_INT >= 34) {
            val manager =
                getSystemService(
                    Context.NOTIFICATION_SERVICE
                ) as NotificationManager

            manager.canUseFullScreenIntent()
        } else {
            true
        }
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT >= 34) {
            val settingsIntent = Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT
            ).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(settingsIntent)
        } else {
            openAppDetailsSettings()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val powerManager =
            getSystemService(Context.POWER_SERVICE) as PowerManager

        return powerManager.isIgnoringBatteryOptimizations(
            packageName
        )
    }

    private fun isBackgroundRestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return false
        }

        val activityManager =
            getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

        return activityManager.isBackgroundRestricted
    }

    private fun openBatteryOptimizationSettings() {
        try {
            val settingsIntent = Intent(
                Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(settingsIntent)
        } catch (_: Exception) {
            openAppDetailsSettings()
        }
    }
    private fun isBootReceiverConfirmedForCurrentBoot(): Boolean {
        val storageContext =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                createDeviceProtectedStorageContext()
            } else {
                this
            }

        val preferences =
            storageContext.getSharedPreferences(
                BootReceiver.MONITORING_PREFERENCES_NAME,
                Context.MODE_PRIVATE
            )

        val receiverConfirmed =
            preferences.getBoolean(
                BootReceiver.KEY_BOOT_RECEIVER_CONFIRMED,
                false
            )

        if (!receiverConfirmed) {
            return false
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return true
        }

        val confirmedBootCount =
            preferences.getInt(
                BootReceiver.KEY_CONFIRMED_BOOT_COUNT,
                -1
            )

        val currentBootCount =
            Settings.Global.getInt(
                contentResolver,
                Settings.Global.BOOT_COUNT,
                -2
            )

        return confirmedBootCount >= 0 &&
                confirmedBootCount == currentBootCount
    }
    private fun openAppDetailsSettings() {
        val settingsIntent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS
        ).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(settingsIntent)
    }
}
