package com.app.payables.util

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

class SettingsManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("app_settings", Context.MODE_PRIVATE)

    companion object {
        const val KEY_DEFAULT_CURRENCY = "default_currency"
        const val KEY_PAYABLE_NOTIFICATIONS = "payable_notifications"
        const val KEY_NOTIFICATION_HOUR = "notification_hour"
        const val KEY_NOTIFICATION_MINUTE = "notification_minute"
        const val KEY_REMINDER_PREFERENCE = "reminder_preference"
        const val KEY_PERMISSIONS_REQUESTED = "permissions_requested"
        const val KEY_PUSH_NOTIFICATIONS_ENABLED = "push_notifications_enabled"
        const val KEY_SHOW_ON_LOCKSCREEN = "show_on_lockscreen"
    }

    fun setDefaultCurrency(currencyCode: String) {
        prefs.edit {
            putString(KEY_DEFAULT_CURRENCY, currencyCode)
        }
    }

    fun getDefaultCurrency(): String {
        return prefs.getString(KEY_DEFAULT_CURRENCY, "EUR") ?: "EUR" // Default to EUR
    }

    fun setNotificationTime(hour: Int, minute: Int) {
        prefs.edit {
            putInt(KEY_NOTIFICATION_HOUR, hour)
            putInt(KEY_NOTIFICATION_MINUTE, minute)
        }
    }

    fun getNotificationTime(): Pair<Int, Int> {
        val hour = prefs.getInt(KEY_NOTIFICATION_HOUR, 9) // Default 9 AM
        val minute = prefs.getInt(KEY_NOTIFICATION_MINUTE, 0)
        return Pair(hour, minute)
    }

    fun setReminderPreference(daysBefore: Int) {
        prefs.edit {
            putInt(KEY_REMINDER_PREFERENCE, daysBefore)
        }
    }

    fun getReminderPreference(): Int {
        return prefs.getInt(KEY_REMINDER_PREFERENCE, 0) // Default "On due date"
    }

    fun hasRequestedPermissions(): Boolean {
        return prefs.getBoolean(KEY_PERMISSIONS_REQUESTED, false)
    }

    fun setPermissionsRequested() {
        prefs.edit {
            putBoolean(KEY_PERMISSIONS_REQUESTED, true)
        }
    }

    fun setPushNotificationsEnabled(enabled: Boolean) {
        prefs.edit {
            putBoolean(KEY_PUSH_NOTIFICATIONS_ENABLED, enabled)
        }
    }

    fun isPushNotificationsEnabled(): Boolean {
        return prefs.getBoolean(KEY_PUSH_NOTIFICATIONS_ENABLED, false)
    }

    fun setShowOnLockscreen(enabled: Boolean) {
        prefs.edit {
            putBoolean(KEY_SHOW_ON_LOCKSCREEN, enabled)
        }
    }

    fun getShowOnLockscreen(): Boolean {
        return prefs.getBoolean(KEY_SHOW_ON_LOCKSCREEN, true) // Default to true
    }
}
