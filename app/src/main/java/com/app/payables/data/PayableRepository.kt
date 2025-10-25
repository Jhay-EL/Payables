package com.app.payables.data

import android.content.Context
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import com.app.payables.ui.PayableItemData
import com.app.payables.util.AlarmScheduler
import androidx.compose.ui.graphics.Color
import java.time.LocalDate
import java.time.format.DateTimeFormatter

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
        
        // Update category count if repository provided
        categoryRepository?.let { repo ->
            val currentCount = getPayablesCountByCategory(category)
            repo.updateCategoryCount(category, currentCount.toString())
        }
    }

    // Insert a new payable
    suspend fun insertPayable(payable: Payable) {
        payableDao.insertPayable(payable)
    }
    
    // Update an existing payable
    suspend fun updatePayable(payable: Payable) {
        payableDao.updatePayable(payable.copy(updatedAt = System.currentTimeMillis()))
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
