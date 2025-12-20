package com.app.payables.util

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import androidx.security.crypto.EncryptedSharedPreferences

class SettingsManager(context: Context) {
    // Encrypted Preferences
    private val prefs: SharedPreferences

    init {
        // Master Key Alias for encryption (1.0.0 API)
        val masterKeyAlias = androidx.security.crypto.MasterKeys.getOrCreate(androidx.security.crypto.MasterKeys.AES256_GCM_SPEC)
            
        val secureFileName = "secret_payables_prefs"
        val oldFileName = "app_settings"

        // Initialize EncryptedSharedPreferences (1.0.0 API: fileName, masterKeyAlias, context, scheme, scheme)
        prefs = EncryptedSharedPreferences.create(
            secureFileName,
            masterKeyAlias,
            context,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
        
        // Migration Logic: Check for old plaintext prefs
        val oldPrefs = context.getSharedPreferences(oldFileName, Context.MODE_PRIVATE)
        if (oldPrefs.all.isNotEmpty()) {
            android.util.Log.i("SettingsManager", "Migrating plaintext preferences to encrypted storage...")
            // Copy all values to secure prefs
            prefs.edit {
                oldPrefs.all.forEach { (key, value) ->
                    when (value) {
                        is String -> putString(key, value)
                        is Int -> putInt(key, value)
                        is Boolean -> putBoolean(key, value)
                        is Float -> putFloat(key, value)
                        is Long -> putLong(key, value)
                        is Set<*> -> {
                            @Suppress("UNCHECKED_CAST")
                            putStringSet(key, value as Set<String>)
                        }
                    }
                }
            }
            // Clear old prefs to remove sensitive data from plaintext file
            oldPrefs.edit { clear() }
            android.util.Log.i("SettingsManager", "Migration complete. Old preferences cleared.")
        }
    }

    companion object {
        const val KEY_DEFAULT_CURRENCY = "default_currency"
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
        return prefs.getBoolean(KEY_PUSH_NOTIFICATIONS_ENABLED, true) // Default to true
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
