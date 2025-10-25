package com.app.payables.work

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.app.payables.PayablesApplication
import com.app.payables.data.Payable
import com.app.payables.util.AlarmScheduler
import com.app.payables.util.SettingsManager
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.util.Calendar

class PayableStatusWorker(
    appContext: Context,
    workerParams: WorkerParameters
): CoroutineWorker(appContext, workerParams) {

    companion object {
        private const val TAG = "PayableStatusWorker"
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "Starting payable status worker")
        
        return try {
            val application = applicationContext as PayablesApplication
            val repository = application.payableRepository
            val settingsManager = SettingsManager(applicationContext)
            val alarmScheduler = AlarmScheduler(applicationContext)

            val activePayables = repository.getActivePayableEntities().first()
            val enabledIds = settingsManager.getEnabledPayableIds()
            val reminderPrefDays = settingsManager.getReminderPreference()
            val (hour, minute) = settingsManager.getNotificationTime()

            Log.d(TAG, "Processing ${activePayables.size} active payables, ${enabledIds.size} have notifications enabled")

            var scheduledCount = 0
            activePayables.forEach { payable ->
                if (payable.id in enabledIds) {
                    try {
                        val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / (1000 * 60 * 60 * 24))
                        val nextDueDate = Payable.calculateNextDueDate(billingDate, payable.billingCycle)
                        val reminderDate = nextDueDate.minusDays(reminderPrefDays.toLong())

                        val calendar = Calendar.getInstance().apply {
                            set(Calendar.YEAR, reminderDate.year)
                            set(Calendar.MONTH, reminderDate.monthValue - 1)
                            set(Calendar.DAY_OF_MONTH, reminderDate.dayOfMonth)
                            set(Calendar.HOUR_OF_DAY, hour)
                            set(Calendar.MINUTE, minute)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }

                        if (alarmScheduler.scheduleAlarm(payable.id, calendar.timeInMillis)) {
                            scheduledCount++
                            Log.d(TAG, "Scheduled notification for '${payable.title}' on $reminderDate at $hour:$minute")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error scheduling alarm for payable ${payable.id}: ${e.message}", e)
                    }
                }
            }
            
            Log.d(TAG, "Successfully scheduled $scheduledCount notifications")
            Result.success()
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception in worker: ${e.message}", e)
            Result.failure()
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Illegal state exception in worker: ${e.message}", e)
            Result.failure()
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error in worker: ${e.message}", e)
            Result.failure()
        }
    }
}
