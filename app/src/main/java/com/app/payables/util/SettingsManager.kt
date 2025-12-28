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


    // Widget Settings
    fun setWidgetTransparency(transparency: Float) {
        prefs.edit { putFloat(KEY_WIDGET_TRANSPARENCY, transparency) }
    }

    fun getWidgetTransparency(): Float {
        return prefs.getFloat(KEY_WIDGET_TRANSPARENCY, 0.15f)
    }

    fun setWidgetBackgroundColor(color: Long) {
        prefs.edit { putLong(KEY_WIDGET_BACKGROUND_COLOR, color) }
    }

    fun getWidgetBackgroundColor(): Long {
        // Default to MaterialTheme.colorScheme.primaryContainer (approximate default if not set)
        // We can't access MaterialTheme here easily, so use a hardcoded fallback or 0
        // 0 usually indicates "not set" or transparent, but here we want a valid color.
        // Let's use a standard default (e.g., surface color)
        return prefs.getLong(KEY_WIDGET_BACKGROUND_COLOR, 0xFFE7E0EC) // 0xFFE7E0EC is often surface variant light
    }

    fun setWidgetTextColor(color: Long) {
        prefs.edit { putLong(KEY_WIDGET_TEXT_COLOR, color) }
    }

    fun getWidgetTextColor(): Long {
        return prefs.getLong(KEY_WIDGET_TEXT_COLOR, 0xFF1D1B20) // 0xFF1D1B20 is often onSurface light
    }

    fun setWidgetBackgroundImageUri(uri: String?) {
        prefs.edit { putString(KEY_WIDGET_BACKGROUND_IMAGE_URI, uri) }
    }

    fun getWidgetBackgroundImageUri(): String? {
        return prefs.getString(KEY_WIDGET_BACKGROUND_IMAGE_URI, null)
    }

    fun setWidgetBackgroundBlur(blur: Float) {
        prefs.edit { putFloat(KEY_WIDGET_BACKGROUND_BLUR, blur) }
    }

    fun getWidgetBackgroundBlur(): Float {
        return prefs.getFloat(KEY_WIDGET_BACKGROUND_BLUR, 0f)
    }

    fun setWidgetShowTomorrow(show: Boolean) {
        prefs.edit { putBoolean(KEY_WIDGET_SHOW_TOMORROW, show) }
    }

    fun getWidgetShowTomorrow(): Boolean {
        return prefs.getBoolean(KEY_WIDGET_SHOW_TOMORROW, true)
    }

    fun setWidgetShowUpcoming(show: Boolean) {
        prefs.edit { putBoolean(KEY_WIDGET_SHOW_UPCOMING, show) }
    }

    fun getWidgetShowUpcoming(): Boolean {
        return prefs.getBoolean(KEY_WIDGET_SHOW_UPCOMING, true)
    }

    fun setWidgetShowCount(show: Boolean) {
        prefs.edit { putBoolean(KEY_WIDGET_SHOW_COUNT, show) }
    }

    fun getWidgetShowCount(): Boolean {
        return prefs.getBoolean(KEY_WIDGET_SHOW_COUNT, true)
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

        // Custom API Keys
        const val KEY_CUSTOM_BRANDFETCH_KEY = "custom_brandfetch_key"
        const val KEY_CUSTOM_FREECURRENCY_KEY = "custom_freecurrency_key"

        // Widget Settings
        const val KEY_WIDGET_TRANSPARENCY = "widget_transparency"
        const val KEY_WIDGET_BACKGROUND_COLOR = "widget_background_color"
        const val KEY_WIDGET_TEXT_COLOR = "widget_text_color"
        const val KEY_WIDGET_BACKGROUND_IMAGE_URI = "widget_background_image_uri"
        const val KEY_WIDGET_BACKGROUND_BLUR = "widget_background_blur"
        const val KEY_WIDGET_SHOW_TOMORROW = "widget_show_tomorrow"
        const val KEY_WIDGET_SHOW_UPCOMING = "widget_show_upcoming"
        const val KEY_WIDGET_SHOW_COUNT = "widget_show_count"
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

    // Custom API Keys
    fun setCustomBrandfetchKey(key: String) {
        prefs.edit { putString(KEY_CUSTOM_BRANDFETCH_KEY, key) }
    }

    fun getCustomBrandfetchKey(): String {
        return prefs.getString(KEY_CUSTOM_BRANDFETCH_KEY, "") ?: ""
    }

    fun setCustomFreecurrencyKey(key: String) {
        prefs.edit { putString(KEY_CUSTOM_FREECURRENCY_KEY, key) }
    }

    fun getCustomFreecurrencyKey(): String {
        return prefs.getString(KEY_CUSTOM_FREECURRENCY_KEY, "") ?: ""
    }
}
