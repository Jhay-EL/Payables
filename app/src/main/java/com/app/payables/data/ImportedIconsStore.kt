package com.app.payables.data

import android.content.Context
import androidx.core.content.edit
import org.json.JSONArray

object ImportedIconsStore {
    private const val PREF_NAME = "custom_icons_prefs"
    private const val KEY_URIS = "uris_json"

    fun getIcons(context: Context): List<String> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_URIS, "[]") ?: "[]"
        return try {
            val array = JSONArray(json)
            buildList(array.length()) {
                for (i in 0 until array.length()) add(array.optString(i))
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    fun addIcon(context: Context, uriString: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val current = getIcons(context).toMutableList()
        if (!current.contains(uriString)) current.add(uriString)
        val array = JSONArray()
        current.forEach { array.put(it) }
        prefs.edit { putString(KEY_URIS, array.toString()) }
    }

    fun removeIcon(context: Context, uriString: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val current = getIcons(context).toMutableList()
        current.remove(uriString)
        val array = JSONArray()
        current.forEach { array.put(it) }
        prefs.edit { putString(KEY_URIS, array.toString()) }
    }
}



