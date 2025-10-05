package com.app.payables.util

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

class SettingsManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("app_settings", Context.MODE_PRIVATE)

    companion object {
        const val KEY_DEFAULT_CURRENCY = "default_currency"
    }

    fun setDefaultCurrency(currencyCode: String) {
        prefs.edit {
            putString(KEY_DEFAULT_CURRENCY, currencyCode)
        }
    }

    fun getDefaultCurrency(): String {
        return prefs.getString(KEY_DEFAULT_CURRENCY, "EUR") ?: "EUR" // Default to EUR
    }
}
