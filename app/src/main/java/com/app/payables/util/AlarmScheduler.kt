package com.app.payables.util

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.app.payables.data.Payable
import com.app.payables.work.NotificationBroadcastReceiver
import java.time.LocalDate
import java.util.Calendar

class AlarmScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    
    companion object {
        private const val TAG = "AlarmScheduler"
    }
    
    /**
     * Schedule an alarm for a specific payable at the given time
     * @return true if scheduled successfully, false otherwise
     */
    fun scheduleAlarm(payableId: String, timeInMillis: Long): Boolean {
        return try {
            if (timeInMillis <= System.currentTimeMillis()) {
                Log.w(TAG, "Cannot schedule alarm in the past for payable: $payableId")
                return false
            }
            
            val intent = Intent(context, NotificationBroadcastReceiver::class.java).apply {
                putExtra("payable_id", payableId)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                payableId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Check if we can schedule exact alarms on Android 12+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) {
                    Log.e(TAG, "Cannot schedule exact alarms - permission not granted")
                    return false
                }
            }
            
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                timeInMillis,
                pendingIntent
            )
            
            Log.d(TAG, "Scheduled alarm for payable $payableId at $timeInMillis")
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception scheduling alarm for $payableId", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm for $payableId", e)
            false
        }
    }
    
    /**
     * Cancel an existing alarm for a payable
     */
    fun cancelAlarm(payableId: String) {
        try {
            val intent = Intent(context, NotificationBroadcastReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                payableId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            
            Log.d(TAG, "Cancelled alarm for payable: $payableId")
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling alarm for $payableId", e)
        }
    }
    
    /**
     * Reschedule the next alarm for a recurring payable
     */
    fun rescheduleNextAlarm(payable: Payable, settingsManager: SettingsManager): Boolean {
        return try {
            // Check if notifications are enabled for this payable
            val enabledIds = settingsManager.getEnabledPayableIds()
            if (payable.id !in enabledIds) {
                Log.d(TAG, "Notifications not enabled for payable: ${payable.id}")
                return false
            }
            
            // Calculate next due date
            val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / (1000 * 60 * 60 * 24))
            val nextDueDate = Payable.calculateNextDueDate(billingDate, payable.billingCycle)
            
            // Get reminder preference and notification time
            val reminderPrefDays = settingsManager.getReminderPreference()
            val reminderDate = nextDueDate.minusDays(reminderPrefDays.toLong())
            val (hour, minute) = settingsManager.getNotificationTime()
            
            // Build calendar for alarm time
            val calendar = Calendar.getInstance().apply {
                set(Calendar.YEAR, reminderDate.year)
                set(Calendar.MONTH, reminderDate.monthValue - 1)
                set(Calendar.DAY_OF_MONTH, reminderDate.dayOfMonth)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            
            // Schedule the alarm
            val scheduled = scheduleAlarm(payable.id, calendar.timeInMillis)
            
            if (scheduled) {
                Log.d(TAG, "Rescheduled next alarm for ${payable.title} on $reminderDate at $hour:$minute")
            }
            
            scheduled
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling alarm for ${payable.id}", e)
            false
        }
    }
}

