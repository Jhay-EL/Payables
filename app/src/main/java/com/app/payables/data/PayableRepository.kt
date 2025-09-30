package com.app.payables.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import com.app.payables.ui.PayableItemData
import androidx.compose.ui.graphics.Color
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class PayableRepository(private val payableDao: PayableDao) {
    
    // Get all payables as Flow of PayableItemData for UI
    fun getAllPayables(): Flow<List<PayableItemData>> {
        return payableDao.getAllPayables().map { payables ->
            payables.map { it.toPayableItemData() }
        }
    }
    
    // Get only active (non-paused, non-finished) payables
    fun getActivePayables(): Flow<List<PayableItemData>> {
        return payableDao.getAllPayables().map { payables ->
            payables.filter { !it.isPaused && !it.isFinished }.map { it.toPayableItemData() }
        }
    }
    
    // Get only paused payables
    fun getPausedPayables(): Flow<List<PayableItemData>> {
        return payableDao.getAllPayables().map { payables ->
            payables.filter { it.isPaused }.map { it.toPayableItemData() }
        }
    }

    fun getActivePayablesDueThisWeek(): Flow<List<PayableItemData>> {
        val today = LocalDate.now()
        val endOfWeek = today.plusDays(6)

        return getActivePayables().map { payables ->
            payables.filter {
                val billingDate = LocalDate.parse(it.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
                val nextDueDate = Payable.calculateNextDueDate(billingDate, it.billingCycle)
                !nextDueDate.isBefore(today) && !nextDueDate.isAfter(endOfWeek)
            }
        }
    }

    fun getActivePayablesDueThisMonth(): Flow<List<PayableItemData>> {
        val today = LocalDate.now()
        val endOfMonth = today.withDayOfMonth(today.lengthOfMonth())

        return getActivePayables().map { payables ->
            payables.filter {
                val billingDate = LocalDate.parse(it.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
                val nextDueDate = Payable.calculateNextDueDate(billingDate, it.billingCycle)
                !nextDueDate.isBefore(today) && !nextDueDate.isAfter(endOfMonth)
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
    
    // Update an existing payable
    suspend fun updatePayable(payable: Payable) {
        payableDao.updatePayable(payable.copy(updatedAt = System.currentTimeMillis()))
    }
    
    // Delete a payable by ID
    suspend fun deletePayable(id: String, categoryRepository: CategoryRepository? = null) {
        // Get the payable to find its category before deleting
        val payable = payableDao.getPayableById(id)
        payableDao.deletePayableById(id)
        
        // Update category count if repository provided
        payable?.let { p ->
            categoryRepository?.let { repo ->
                val newCount = getPayablesCountByCategory(p.category)
                repo.updateCategoryCount(p.category, newCount.toString())
            }
        }
    }
    
    // Pause a payable by ID
    suspend fun pausePayable(id: String) {
        val payable = payableDao.getPayableById(id)
        payable?.let { p ->
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

    // Finish payables whose end date is in the past
    suspend fun finishPastDuePayables() {
        val today = LocalDate.now().atStartOfDay(java.time.ZoneOffset.UTC).toInstant().toEpochMilli()
        val payablesToFinish = payableDao.getActivePayablesWithEndDate().filter {
            it.endDateMillis != null && it.endDateMillis < today
        }
        payablesToFinish.forEach { payable ->
            updatePayable(payable.copy(isFinished = true))
        }
    }
    
    // Get payables count by category (useful for updating category counts)
    suspend fun getPayablesCountByCategory(category: String): Int {
        return payableDao.getPayablesCountByCategory(category)
    }

    suspend fun getAllPaymentMethods(): List<String> {
        return payableDao.getAllPaymentMethods()
    }

    fun getNormalizedMonthlyCost(): Flow<Double> {
        return getActivePayables().map { payables ->
            payables.sumOf {
                val amount = it.price.toDoubleOrNull() ?: 0.0
                when (it.billingCycle) {
                    "Weekly" -> amount * 4.345
                    "Monthly" -> amount
                    "Quarterly" -> amount / 3
                    "Yearly" -> amount / 12
                    else -> 0.0
                }
            }
        }
    }

    fun getSpendingPerCategory(): Flow<Map<String, Double>> {
        return getActivePayables().map { payables ->
            payables.groupBy { it.category }
                .mapValues { (_, payables) ->
                    payables.sumOf {
                        val amount = it.price.toDoubleOrNull() ?: 0.0
                        when (it.billingCycle) {
                            "Weekly" -> amount * 4.345
                            "Monthly" -> amount
                            "Quarterly" -> amount / 3
                            "Yearly" -> amount / 12
                            else -> 0.0
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
