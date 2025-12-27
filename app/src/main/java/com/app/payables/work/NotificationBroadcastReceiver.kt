package com.app.payables.work

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.app.payables.PayablesApplication
import com.app.payables.util.AlarmScheduler
import com.app.payables.util.AppNotificationManager
import com.app.payables.util.NotificationErrorHandler
import com.app.payables.util.SettingsManager
import kotlinx.coroutines.launch

class NotificationBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "NotificationReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val payableId = intent.getStringExtra("payable_id") ?: run {
            Log.w(TAG, "Received intent without payable_id")
            return
        }

        Log.d(TAG, "Received notification trigger for payable: $payableId")

        val app = context.applicationContext as PayablesApplication
        val repository = app.payableRepository
        val notificationManager = AppNotificationManager(context)
        val alarmScheduler = AlarmScheduler(context)
        val settingsManager = SettingsManager(context)

        // Use goAsync for long-running operations
        val pendingResult = goAsync()

        // Use application-scoped coroutine instead of creating new scope
        // This prevents memory leaks and ensures proper lifecycle management
        app.applicationScope.launch {
            try {
                repository.getPayableById(payableId)?.let { payable ->
                    Log.d(TAG, "Sending notification for: ${payable.title}")
                    
                    // Read lockscreen preference
                    val showOnLockscreen = settingsManager.getShowOnLockscreen()
                    
                    // Send the notification with lockscreen setting
                    try {
                        notificationManager.sendDuePayableNotification(payable, showOnLockscreen)
                        Log.d(TAG, "Successfully sent notification for: ${payable.title}")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to send notification for: ${payable.title}", e)
                        NotificationErrorHandler.handleNotificationSendError(payable.title, e)
                    }
                    
                    // Reschedule the next notification for recurring payables
                    if (payable.isRecurring && !payable.isPaused && !payable.isFinished) {
                        try {
                            val rescheduled = alarmScheduler.rescheduleNextAlarm(payable, settingsManager)
                            if (rescheduled) {
                                Log.d(TAG, "Rescheduled next notification for: ${payable.title}")
                            } else {
                                Log.w(TAG, "Failed to reschedule notification for: ${payable.title}")
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error rescheduling notification for: ${payable.title}", e)
                        }
                    } else {
                        Log.d(TAG, "Not rescheduling for ${payable.title} - isRecurring: ${payable.isRecurring}, isPaused: ${payable.isPaused}, isFinished: ${payable.isFinished}")
                    }
                } ?: run {
                    Log.w(TAG, "Payable not found: $payableId")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing notification for payable: $payableId", e)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
