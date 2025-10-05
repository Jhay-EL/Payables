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
    }

    fun setDefaultCurrency(currencyCode: String) {
        prefs.edit {
            putString(KEY_DEFAULT_CURRENCY, currencyCode)
        }
    }

    fun getDefaultCurrency(): String {
        return prefs.getString(KEY_DEFAULT_CURRENCY, "EUR") ?: "EUR" // Default to EUR
    }

    fun setEnabledPayableIds(ids: Set<String>) {
        prefs.edit {
            putStringSet(KEY_PAYABLE_NOTIFICATIONS, ids)
        }
    }

    fun getEnabledPayableIds(): MutableSet<String> {
        return prefs.getStringSet(KEY_PAYABLE_NOTIFICATIONS, emptySet())?.toMutableSet() ?: mutableSetOf()
    }

    fun hasNotificationSetting(): Boolean {
        return prefs.contains(KEY_PAYABLE_NOTIFICATIONS)
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
}
