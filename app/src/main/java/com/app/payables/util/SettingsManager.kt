@file:Suppress("unused")

package com.app.payables.util

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import androidx.security.crypto.EncryptedSharedPreferences

class SettingsManager(context: Context) {
    // Encrypted Preferences
    private val prefs: SharedPreferences

    init {
        val secureFileName = "secret_payables_prefs"
        val oldFileName = "app_settings"

        // Try to initialize EncryptedSharedPreferences with error handling for keystore corruption
        prefs = try {
            // Master Key Alias for encryption (1.0.0 API)
            val masterKeyAlias = androidx.security.crypto.MasterKeys.getOrCreate(
                androidx.security.crypto.MasterKeys.AES256_GCM_SPEC
            )
            
            // Initialize EncryptedSharedPreferences (1.0.0 API)
            EncryptedSharedPreferences.create(
                secureFileName,
                masterKeyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Handle corrupted keystore or encrypted preferences
            android.util.Log.e("SettingsManager", "EncryptedSharedPreferences failed, recreating...", e)
            
            // Delete corrupted encrypted preferences file
            try {
                context.deleteSharedPreferences(secureFileName)
                android.util.Log.i("SettingsManager", "Deleted corrupted preferences file")
            } catch (deleteException: Exception) {
                android.util.Log.w("SettingsManager", "Could not delete corrupted file", deleteException)
            }
            
            // Recreate with new master key
            try {
                val masterKeyAlias = androidx.security.crypto.MasterKeys.getOrCreate(
                    androidx.security.crypto.MasterKeys.AES256_GCM_SPEC
                )
                
                EncryptedSharedPreferences.create(
                    secureFileName,
                    masterKeyAlias,
                    context,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                )
            } catch (retryException: Exception) {
                // If still failing, fall back to regular SharedPreferences
                android.util.Log.e("SettingsManager", "Failed to recreate encrypted prefs, using plaintext fallback", retryException)
                context.getSharedPreferences("app_settings_fallback", Context.MODE_PRIVATE)
            }
        }
        
        // Migration Logic: Check for old plaintext prefs
        val oldPrefs = context.getSharedPreferences(oldFileName, Context.MODE_PRIVATE)
        // Use safe call on .all as it can be null in some contexts (like Preview)
        val allOldPrefs = oldPrefs.all
        if (!allOldPrefs.isNullOrEmpty()) {
            android.util.Log.i("SettingsManager", "Migrating plaintext preferences to encrypted storage...")
            // Copy all values to secure prefs
            prefs.edit {
                allOldPrefs.forEach { (key, value) ->
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
        
        // Cloud backup settings
        const val KEY_CLOUD_BACKUP_ENABLED = "cloud_backup_enabled"
        const val KEY_CLOUD_BACKUP_FREQUENCY = "cloud_backup_frequency"
        const val KEY_LAST_CLOUD_BACKUP = "last_cloud_backup_timestamp"
        
        // Backup frequency options
        const val BACKUP_FREQUENCY_NEVER = "never"
        const val BACKUP_FREQUENCY_ON_CHANGE = "on_change"
        const val BACKUP_FREQUENCY_DAILY = "daily"
        const val BACKUP_FREQUENCY_WEEKLY = "weekly"
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

    // Cloud Backup Settings
    
    fun setCloudBackupEnabled(enabled: Boolean) {
        prefs.edit {
            putBoolean(KEY_CLOUD_BACKUP_ENABLED, enabled)
        }
    }

    fun isCloudBackupEnabled(): Boolean {
        return prefs.getBoolean(KEY_CLOUD_BACKUP_ENABLED, false) // Default to disabled
    }

    fun setCloudBackupFrequency(frequency: String) {
        prefs.edit {
            putString(KEY_CLOUD_BACKUP_FREQUENCY, frequency)
        }
    }

    fun getCloudBackupFrequency(): String {
        return prefs.getString(KEY_CLOUD_BACKUP_FREQUENCY, BACKUP_FREQUENCY_NEVER) ?: BACKUP_FREQUENCY_NEVER
    }

    fun setLastCloudBackup(timestamp: Long) {
        prefs.edit {
            putLong(KEY_LAST_CLOUD_BACKUP, timestamp)
        }
    }

    fun getLastCloudBackup(): Long {
        return prefs.getLong(KEY_LAST_CLOUD_BACKUP, 0L)
    }
}
