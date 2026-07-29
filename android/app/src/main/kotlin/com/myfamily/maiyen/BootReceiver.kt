package com.myfamily.maiyen

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

class BootReceiver : BroadcastReceiver() {

    companion object {
        const val MONITORING_PREFERENCES_NAME =
            MaiYenNativeIdentifiers.MONITORING_PREFERENCES
        const val KEY_BOOT_RECEIVER_CONFIRMED =
            "boot_receiver_confirmed"
        const val KEY_CONFIRMED_BOOT_COUNT =
            "confirmed_boot_count"
        const val KEY_LAST_BOOT_RECEIVER_AT =
            "last_boot_receiver_at"
        const val KEY_LAST_BOOT_ACTION =
            "last_boot_action"
        const val KEY_PRESENCE_RECOVERY_REQUESTED =
            "presence_recovery_requested"
        const val KEY_LAST_PRESENCE_RECOVERY_REQUEST_AT =
            "last_presence_recovery_request_at"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        val isRecoveryAction =
            action == Intent.ACTION_BOOT_COMPLETED ||
                    action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
                    action == Intent.ACTION_USER_UNLOCKED ||
                    action == Intent.ACTION_MY_PACKAGE_REPLACED ||
                    action == "android.intent.action.QUICKBOOT_POWERON"

        if (!isRecoveryAction) {
            return
        }

        // Device-protected storage is available even before the first unlock.
        // The foreground-task plugin owns the actual service restart. This
        // receiver records the recovery request without falsely claiming that
        // the location heartbeat has already succeeded.
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

        storageContext
            .getSharedPreferences(
                MONITORING_PREFERENCES_NAME,
                Context.MODE_PRIVATE
            )
            .edit()
            .putBoolean(KEY_BOOT_RECEIVER_CONFIRMED, true)
            .putInt(KEY_CONFIRMED_BOOT_COUNT, bootCount)
            .putLong(
                KEY_LAST_BOOT_RECEIVER_AT,
                System.currentTimeMillis()
            )
            .putString(KEY_LAST_BOOT_ACTION, action)
            .putBoolean(KEY_PRESENCE_RECOVERY_REQUESTED, true)
            .putLong(
                KEY_LAST_PRESENCE_RECOVERY_REQUEST_AT,
                System.currentTimeMillis()
            )
            .apply()
    }
}
