package com.app.payables.data

import android.content.Context
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import com.app.payables.ui.PayableItemData
import com.app.payables.util.AlarmScheduler
import com.app.payables.util.SettingsManager
import androidx.compose.ui.graphics.Color
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Calendar

enum class SpendingTimeframe {
    Daily,
    Weekly,
    Monthly,
    Yearly
}

class PayableRepository(
    private val payableDao: PayableDao,
    private val context: Context? = null
) {
    private val alarmScheduler: AlarmScheduler? by lazy {
        context?.let { AlarmScheduler(it) }
    }
    
    // Get all payables as Flow of Payable entities
    fun getAllPayables(): Flow<List<Payable>> {
        return payableDao.getAllPayables()
    }

    suspend fun getAllPayablesList(): List<Payable> {
        return payableDao.getAllPayablesList()
    }

    suspend fun getPayableById(id: String): Payable? {
        return payableDao.getPayableById(id)
    }
    
    /**
     * Schedule notification alarm for a payable
     * Only schedules if notifications are enabled and the alarm time is in the future
     */
    fun scheduleNotificationForPayable(payable: Payable) {
        context?.let { ctx ->
            val settingsManager = SettingsManager(ctx)
            
            android.util.Log.d("PayableRepository", "Attempting to schedule notification for: ${payable.title}")
            android.util.Log.d("PayableRepository", "Notifications enabled: ${settingsManager.isPushNotificationsEnabled()}")
            
            // Only schedule if push notifications are enabled
            if (!settingsManager.isPushNotificationsEnabled()) {
                android.util.Log.w("PayableRepository", "Notifications disabled - skipping ${payable.title}")
                return
            }
            
            alarmScheduler?.let { scheduler ->
                try {
                    val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / Payable.MILLIS_PER_DAY)
                    val nextDueDate = Payable.calculateNextDueDate(billingDate, payable.billingCycle)
                    val reminderPrefDays = settingsManager.getReminderPreference()
                    val reminderDate = nextDueDate.minusDays(reminderPrefDays.toLong())
                    val (hour, minute) = settingsManager.getNotificationTime()
                    
                    val calendar = Calendar.getInstance().apply {
                        set(Calendar.YEAR, reminderDate.year)
                        set(Calendar.MONTH, reminderDate.monthValue - 1)
                        set(Calendar.DAY_OF_MONTH, reminderDate.dayOfMonth)
                        set(Calendar.HOUR_OF_DAY, hour)
                        set(Calendar.MINUTE, minute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    
                    android.util.Log.d("PayableRepository", "Next due date: $nextDueDate, Reminder date: $reminderDate, Time: $hour:$minute")
                    android.util.Log.d("PayableRepository", "Scheduled time: ${calendar.timeInMillis}, Current time: ${System.currentTimeMillis()}")
                    
                    // Only schedule if the time is in the future
                    if (calendar.timeInMillis > System.currentTimeMillis()) {
                        scheduler.scheduleAlarm(payable.id, calendar.timeInMillis)
                        android.util.Log.i("PayableRepository", "✓ Alarm scheduled for ${payable.title} at ${calendar.time}")
                    } else {
                        android.util.Log.w("PayableRepository", "✗ Alarm time is in the past for ${payable.title} - not scheduling")
                    }
                } catch (e: Exception) {
                    // Log error but don't crash
                    android.util.Log.e("PayableRepository", "Error scheduling notification for ${payable.id}", e)
                }
            }
        }
    }
    
    /**
     * Reschedule alarms for all active payables
     * Call this when notification settings change
     */
    suspend fun rescheduleAllAlarms() {
        try {
            val activePayables = getAllPayablesList().filter { !it.isPaused && !it.isFinished }
            android.util.Log.d("PayableRepository", "Rescheduling alarms for ${activePayables.size} active payables")
            
            activePayables.forEach { payable ->
                // Cancel existing alarm
                alarmScheduler?.cancelAlarm(payable.id)
                // Schedule new alarm with updated settings
                scheduleNotificationForPayable(payable)
            }
            
            android.util.Log.d("PayableRepository", "Successfully rescheduled all alarms")
        } catch (e: Exception) {
            android.util.Log.e("PayableRepository", "Error rescheduling all alarms", e)
        }
    }
    
    // Get only active (non-paused, non-finished) payables
    fun getActivePayables(): Flow<List<PayableItemData>> {
        return getAllPayables().map { payables ->
            payables.filter { !it.isPaused && !it.isFinished }.map { it.toPayableItemData() }
        }
    }

    // Get only active (non-paused, non-finished) payables as entities
    fun getActivePayableEntities(): Flow<List<Payable>> {
        return getAllPayables().map { payables ->
            payables.filter { !it.isPaused && !it.isFinished }
        }
    }
    
    // Get only paused payables
    fun getPausedPayables(): Flow<List<PayableItemData>> {
        return getAllPayables().map { payables ->
            payables.filter { it.isPaused }.map { it.toPayableItemData() }
        }
    }

    fun getActivePayablesDueThisWeek(): Flow<List<PayableItemData>> {
        return getActivePayables().map { payables ->
            payables.filter {
                val billingDate = LocalDate.parse(it.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
                val nextDueDate = Payable.calculateNextDueDate(billingDate, it.billingCycle)
                !nextDueDate.isBefore(LocalDate.now()) && !nextDueDate.isAfter(LocalDate.now().plusDays(6))
            }
        }
    }

    fun getActivePayablesDueThisMonth(): Flow<List<PayableItemData>> {
        return getActivePayables().map { payables ->
            payables.filter {
                val billingDate = LocalDate.parse(it.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
                val nextDueDate = Payable.calculateNextDueDate(billingDate, it.billingCycle)
                !nextDueDate.isBefore(LocalDate.now()) && !nextDueDate.isAfter(LocalDate.now().withDayOfMonth(LocalDate.now().lengthOfMonth()))
            }
        }
    }

    
    // Insert a new payable
    suspend fun insertPayable(
        id: String = java.util.UUID.randomUUID().toString(),
        title: String,
        amount: String,
        description: String = "",
        isRecurring: Boolean = true,
        billingDate: LocalDate,
        endDate: LocalDate? = null,
        billingCycle: String = "Monthly",
        currency: String = "EUR",
        category: String = "Not set",
        paymentMethod: String = "Not set",
        website: String = "",
        notes: String = "",
        iconName: String = "Payment",
        customIconUri: String? = null,
        color: Color = Color(0xFF2196F3),
        iconColor: Color = Color(0xFF1976D2),
        categoryRepository: CategoryRepository? = null
    ) {
        val payable = Payable.create(
            id = id,
            title = title,
            amount = amount,
            description = description,
            isRecurring = isRecurring,
            billingDate = billingDate,
            endDate = endDate,
            billingCycle = billingCycle,
            currency = currency,
            category = category,
            paymentMethod = paymentMethod,
            website = website,
            notes = notes,
            iconName = iconName,
            customIconUri = customIconUri,
            color = color,
            iconColor = iconColor
        )
        payableDao.insertPayable(payable)
        
        // Schedule notification for new payable
        scheduleNotificationForPayable(payable)
        
        // Update category count if repository provided
        categoryRepository?.let { repo ->
            val currentCount = getPayablesCountByCategory(category)
            repo.updateCategoryCount(category, currentCount.toString())
        }
    }

    // Insert a new payable
    suspend fun insertPayable(payable: Payable) {
        payableDao.insertPayable(payable)
        
        // Schedule notification if payable is active
        if (!payable.isPaused && !payable.isFinished) {
            scheduleNotificationForPayable(payable)
        }
    }
    
    // Update an existing payable
    suspend fun updatePayable(payable: Payable) {
        payableDao.updatePayable(payable.copy(updatedAt = System.currentTimeMillis()))
        
        // Cancel old alarm
        alarmScheduler?.cancelAlarm(payable.id)
        
        // Reschedule if payable is active
        if (!payable.isPaused && !payable.isFinished) {
            scheduleNotificationForPayable(payable)
        }
    }
    
    // Delete a payable by ID
    suspend fun deletePayable(id: String, categoryRepository: CategoryRepository? = null) {
        // Get the payable to find its category before deleting
        val payable = payableDao.getPayableById(id)
        
        // Cancel any scheduled alarms for this payable
        alarmScheduler?.cancelAlarm(id)
        
        payableDao.deletePayableById(id)
        
        // Update category count if repository provided
        payable?.let { p ->
            categoryRepository?.let { repo ->
                val newCount = getPayablesCountByCategory(p.category)
                repo.updateCategoryCount(p.category, newCount.toString())
            }
        }
    }

    suspend fun deleteActivePayables() = payableDao.deleteActivePayables()
    suspend fun deleteFinishedPayables() = payableDao.deleteFinishedPayables()
    suspend fun deletePausedPayables() = payableDao.deletePausedPayables()
    suspend fun resetAllPaymentMethods() = payableDao.resetAllPaymentMethods()
    suspend fun deleteAllPayables() = payableDao.deleteAllPayables()
    
    // Pause a payable by ID
    suspend fun pausePayable(id: String) {
        val payable = payableDao.getPayableById(id)
        payable?.let { p ->
            // Cancel any scheduled alarms when pausing
            alarmScheduler?.cancelAlarm(id)
            
            val pausedPayable = p.copy(
                isPaused = true,
                updatedAt = System.currentTimeMillis()
            )
            payableDao.updatePayable(pausedPayable)
        }
    }

    // Unpause a payable by ID
    suspend fun unpausePayable(id: String) {
        val payable = payableDao.getPayableById(id)
        payable?.let { p ->
            val unpausedPayable = p.copy(
                isPaused = false,
                updatedAt = System.currentTimeMillis()
            )
            payableDao.updatePayable(unpausedPayable)
            
            // Schedule notification when unpausing
            scheduleNotificationForPayable(unpausedPayable)
        }
    }

    // Finish a payable by ID
    suspend fun finishPayable(id: String) {
        val payable = payableDao.getPayableById(id)
        payable?.let { p ->
            // Cancel any scheduled alarms when finishing
            alarmScheduler?.cancelAlarm(id)
            
            val finishedPayable = p.copy(
                isFinished = true,
                updatedAt = System.currentTimeMillis()
            )
            payableDao.updatePayable(finishedPayable)
        }
    }

    // Unfinish a payable by ID
    suspend fun unfinishPayable(id: String) {
        val payable = payableDao.getPayableById(id)
        payable?.let { p ->
            val unfinishedPayable = p.copy(
                isFinished = false,
                updatedAt = System.currentTimeMillis()
            )
            payableDao.updatePayable(unfinishedPayable)
            
            // Schedule notification when unfinishing
            scheduleNotificationForPayable(unfinishedPayable)
        }
    }

    // Get payables count by category (useful for updating category counts)
    suspend fun getPayablesCountByCategory(category: String): Int {
        return payableDao.getPayablesCountByCategory(category)
    }

    fun getAverageCost(timeframe: SpendingTimeframe): Flow<Double> {
        return getActivePayables().map { payables ->
            payables.sumOf {
                val amount = it.price.toDoubleOrNull() ?: 0.0
                val dailyAmount = when (it.billingCycle) {
                    "Weekly" -> amount / 7
                    "Monthly" -> amount / 30.4375
                    "Quarterly" -> amount / 91.3125
                    "Yearly" -> amount / 365.25
                    else -> amount
                }
                when (timeframe) {
                    SpendingTimeframe.Daily -> dailyAmount
                    SpendingTimeframe.Weekly -> dailyAmount * 7
                    SpendingTimeframe.Monthly -> dailyAmount * 30.4375
                    SpendingTimeframe.Yearly -> dailyAmount * 365.25
                }
            }
        }
    }

    fun getSpendingPerCategory(timeframe: SpendingTimeframe): Flow<Map<String, Double>> {
        return getActivePayables().map { payables ->
            payables.groupBy { it.category }
                .mapValues { (_, payables) ->
                    payables.sumOf {
                        val amount = it.price.toDoubleOrNull() ?: 0.0
                        val dailyAmount = when (it.billingCycle) {
                            "Weekly" -> amount / 7
                            "Monthly" -> amount / 30.4375
                            "Quarterly" -> amount / 91.3125
                            "Yearly" -> amount / 365.25
                            else -> amount
                        }
                        when (timeframe) {
                            SpendingTimeframe.Daily -> dailyAmount
                            SpendingTimeframe.Weekly -> dailyAmount * 7
                            SpendingTimeframe.Monthly -> dailyAmount * 30.4375
                            SpendingTimeframe.Yearly -> dailyAmount * 365.25
                        }
                    }
                }
        }
    }

    fun getUpcomingPayments(limit: Int = 5): Flow<List<PayableItemData>> {
        return getActivePayables().map { payables ->
            payables.sortedBy { it.nextDueDateMillis }
                .take(limit)
        }
    }

    fun getTopFiveMostExpensive(): Flow<List<PayableItemData>> {
        return getActivePayables().map { payables ->
            payables.sortedByDescending {
                val amount = it.price.toDoubleOrNull() ?: 0.0
                when (it.billingCycle) {
                    "Weekly" -> amount * 4.345
                    "Monthly" -> amount
                    "Quarterly" -> amount / 3
                    "Yearly" -> amount / 12
                    else -> 0.0
                }
            }.take(5)
        }
    }
}
