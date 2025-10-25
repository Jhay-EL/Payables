package com.app.payables.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi

object NotificationErrorHandler {
    private const val TAG = "NotificationErrorHandler"
    
    /**
     * Handle scheduling errors with user-visible feedback
     */
    fun handleSchedulingError(context: Context, error: Exception) {
        Log.e(TAG, "Notification scheduling error", error)
        
        val message = when (error) {
            is SecurityException -> "Permission denied to schedule notifications. Please check app permissions."
            is IllegalStateException -> "Unable to schedule notification. Please try again."
            else -> "Failed to schedule notification: ${error.message}"
        }
        
        Toast.makeText(context, message, Toast.LENGTH_LONG).show()
    }
    
    /**
     * Show error when notification permission is missing
     */
    fun showPermissionErrorDialog(context: Context) {
        Log.w(TAG, "Notification permission not granted")
        Toast.makeText(
            context,
            "Notification permission is required to receive payable reminders. Please enable it in app settings.",
            Toast.LENGTH_LONG
        ).show()
    }
    
    /**
     * Show error when exact alarm permission is missing (Android 12+)
     */
    @RequiresApi(Build.VERSION_CODES.S)
    fun showAlarmPermissionMissing(context: Context) {
        Log.w(TAG, "Exact alarm permission not granted")
        Toast.makeText(
            context,
            "This app needs permission to schedule exact alarms for timely notifications. Please enable it in settings.",
            Toast.LENGTH_LONG
        ).show()
    }
    
    /**
     * Open app notification settings
     */
    fun openNotificationSettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open notification settings", e)
            Toast.makeText(context, "Unable to open settings", Toast.LENGTH_SHORT).show()
        }
    }
    
    /**
     * Open exact alarm settings (Android 12+)
     */
    @RequiresApi(Build.VERSION_CODES.S)
    fun openAlarmSettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open alarm settings", e)
            Toast.makeText(context, "Unable to open alarm settings", Toast.LENGTH_SHORT).show()
        }
    }
    
    /**
     * Handle notification send failures
     */
    fun handleNotificationSendError(context: Context, payableTitle: String, error: Exception) {
        Log.e(TAG, "Failed to send notification for $payableTitle", error)
        // Could be enhanced to store failed notifications for retry
    }
}

