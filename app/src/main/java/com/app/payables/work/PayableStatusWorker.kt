package com.app.payables.work

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.app.payables.PayablesApplication
import com.app.payables.data.Payable
import com.app.payables.util.SettingsManager
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.util.Calendar
import android.os.Build

class PayableStatusWorker(
    appContext: Context,
    workerParams: WorkerParameters
): CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val application = applicationContext as PayablesApplication
        val repository = application.payableRepository
        val settingsManager = SettingsManager(applicationContext)
        val alarmManager = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        return try {
            val activePayables = repository.getActivePayableEntities().first()
            val enabledIds = settingsManager.getEnabledPayableIds()
            val reminderPrefDays = settingsManager.getReminderPreference()
            val (hour, minute) = settingsManager.getNotificationTime()

            activePayables.forEach { payable ->
                if (payable.id in enabledIds) {
                    val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / (1000 * 60 * 60 * 24))
                    val nextDueDate = Payable.calculateNextDueDate(billingDate, payable.billingCycle)
                    val reminderDate = nextDueDate.minusDays(reminderPrefDays.toLong())

                    if (reminderDate.isEqual(LocalDate.now())) {
                        val intent = Intent(applicationContext, NotificationBroadcastReceiver::class.java).apply {
                            putExtra("payable_id", payable.id)
                        }

                        val pendingIntent = PendingIntent.getBroadcast(
                            applicationContext,
                            payable.id.hashCode(),
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        val calendar = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, hour)
                            set(Calendar.MINUTE, minute)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        
                        // Schedule the alarm
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (alarmManager.canScheduleExactAlarms()) {
                                alarmManager.setExact(
                                    AlarmManager.RTC_WAKEUP,
                                    calendar.timeInMillis,
                                    pendingIntent
                                )
                            }
                        } else {
                            alarmManager.setExact(
                                AlarmManager.RTC_WAKEUP,
                                calendar.timeInMillis,
                                pendingIntent
                            )
                        }
                    }
                }
            }
            Result.success()
        } catch (_: Exception) {
            Result.failure()
        }
    }
}
