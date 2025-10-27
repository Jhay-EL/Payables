package com.app.payables.util

import android.content.Context
import android.util.Log
import android.widget.Toast

object NotificationErrorHandler {
    private const val TAG = "NotificationErrorHandler"
    
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
     * Handle notification send failures
     */
    fun handleNotificationSendError(payableTitle: String, error: Exception) {
        Log.e(TAG, "Failed to send notification for $payableTitle", error)
        // Could be enhanced to store failed notifications for retry
    }
}

