package com.myfamily.safehome

/**
 * Định danh native của MaiYen và các giá trị SafeHome cũ phải tiếp tục được
 * hỗ trợ để không làm hỏng notification, intent hoặc dữ liệu Android hiện có.
 */
internal object MaiYenNativeIdentifiers {
    const val NATIVE_ALARM_PERMISSION_CHANNEL =
        "safehome/native_alarm_permission"

    const val GET_ACTION_METHOD = "getMaiYenAction"
    const val LEGACY_GET_ACTION_METHOD = "getSafeHomeAction"

    const val ACTION_EXTRA = "maiyen_action"
    const val LEGACY_ACTION_EXTRA = "safehome_action"

    const val LEGACY_MONITORING_PREFERENCES =
        "safehome_monitoring"

    const val LEGACY_BOOT_NOTIFICATION_CHANNEL_ID =
        "safehome_boot_channel"
}
