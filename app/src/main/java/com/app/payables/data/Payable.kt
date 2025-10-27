package com.app.payables.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.app.payables.ui.PayableItemData
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Entity(tableName = "payables")
data class Payable(
    @PrimaryKey
    val id: String,
    val title: String,
    val amount: String,
    val description: String = "",
    val isRecurring: Boolean = true,
    val billingDateMillis: Long, // Store as millis for Room compatibility
    val endDateMillis: Long? = null, // Nullable for one-time payments
    val billingCycle: String = "Monthly", // Monthly, Weekly, Quarterly, Yearly
    val currency: String = "EUR",
    val category: String = "Not set",
    val paymentMethod: String = "Not set",
    val website: String = "",
    val notes: String = "",
    val iconName: String = "Payment", // Store icon name as string
    val customIconUri: String? = null, // Store custom icon URI as string (nullable)
    val colorValue: Long = Color(0xFF2196F3).value.toLong(), // Store color as Long
    val iconColorValue: Long = Color(0xFF1976D2).value.toLong(), // Icon background color
    val isPaused: Boolean = false, // Whether the payable is paused (hidden from main view)
    val isFinished: Boolean = false, // Whether the payable is finished (completed or expired)
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    // Convert to UI PayableItemData
    fun toPayableItemData(): PayableItemData {
        val billingDate = LocalDate.ofEpochDay(billingDateMillis / (24 * 60 * 60 * 1000))
        val dueDate = calculateNextDueDate(billingDate, billingCycle)
        val endDateFormatted = endDateMillis?.let {
            LocalDate.ofEpochDay(it / (24 * 60 * 60 * 1000)).format(dateFormatter)
        }
        
        return PayableItemData(
            id = id, // Include the payable ID
            name = title,
            planType = description.ifBlank { billingCycle },
            price = amount,
            currency = currency,
            dueDate = formatDueDate(dueDate),
            icon = getIconFromName(iconName),
            backgroundColor = Color(colorValue.toULong()),
            category = category,
            customIconUri = customIconUri,
            notes = notes,
            website = website,
            paymentMethod = paymentMethod,
            isPaused = isPaused,
            isFinished = isFinished,
            billingStartDate = billingDate.format(dateFormatter),
            billingCycle = billingCycle,
            endDate = endDateFormatted,
            createdAt = createdAt,
            billingDateMillis = billingDateMillis,
            nextDueDateMillis = dueDate.toEpochDay() * (24 * 60 * 60 * 1000)
        )
    }
    
    companion object {
        private val dateFormatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
        
        // Create from AddPayableScreen form data
        fun create(
            id: String,
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
            isPaused: Boolean = false,
            isFinished: Boolean = false
        ): Payable {
            return Payable(
                id = id,
                title = title,
                amount = amount,
                description = description,
                isRecurring = isRecurring,
                billingDateMillis = billingDate.toEpochDay() * (24 * 60 * 60 * 1000),
                endDateMillis = endDate?.toEpochDay()?.times(24 * 60 * 60 * 1000),
                billingCycle = billingCycle,
                currency = currency,
                category = category,
                paymentMethod = paymentMethod,
                website = website,
                notes = notes,
                iconName = iconName,
                customIconUri = customIconUri,
                colorValue = color.value.toLong(),
                iconColorValue = iconColor.value.toLong(),
                isPaused = isPaused,
                isFinished = isFinished
            )
        }
        
        // Calculate next due date based on billing cycle
        internal fun calculateNextDueDate(billingDate: LocalDate, cycle: String): LocalDate {
            val today = LocalDate.now()
            var nextDue = billingDate
            
            // Move to future dates based on cycle (only advance if BEFORE today, not ON today)
            while (nextDue.isBefore(today)) {
                nextDue = when (cycle) {
                    "Weekly" -> nextDue.plusWeeks(1)
                    "Monthly" -> nextDue.plusMonths(1)
                    "Quarterly" -> nextDue.plusMonths(3)
                    "Yearly" -> nextDue.plusYears(1)
                    else -> nextDue.plusMonths(1) // Default to monthly
                }
            }
            
            return nextDue
        }
        
        // Format due date for display
        private fun formatDueDate(dueDate: LocalDate): String {
            val today = LocalDate.now()
            val tomorrow = today.plusDays(1)
            val daysDifference = java.time.temporal.ChronoUnit.DAYS.between(today, dueDate)
            val weeksDifference = java.time.temporal.ChronoUnit.WEEKS.between(today, dueDate)
            val monthsDifference = java.time.temporal.ChronoUnit.MONTHS.between(today, dueDate)
            val yearsDifference = java.time.temporal.ChronoUnit.YEARS.between(today, dueDate)
            
            return when {
                dueDate.isEqual(today) -> "Today"
                dueDate.isEqual(tomorrow) -> "Tomorrow"
                daysDifference <= 6 -> "In $daysDifference days"
                weeksDifference == 1L -> "In 1 week"
                weeksDifference in 2..3 -> "In $weeksDifference weeks"
                monthsDifference == 1L -> "In 1 month"
                monthsDifference in 2..11 -> "In $monthsDifference months"
                yearsDifference == 1L -> "In 1 year"
                yearsDifference > 1 -> "In $yearsDifference years"
                else -> "In $daysDifference days" // Fallback for edge cases
            }
        }
        
        // Map string name to icon - extended from Category pattern
        private fun getIconFromName(iconName: String): ImageVector {
            return when (iconName) {
                "Payment" -> Icons.Filled.Payment
                "PlayArrow" -> Icons.Filled.PlayArrow
                "MusicNote" -> Icons.Filled.MusicNote
                "Movie" -> Icons.Filled.Movie
                "LocalShipping" -> Icons.Filled.LocalShipping
                "Cloud" -> Icons.Filled.Cloud
                "Home" -> Icons.Filled.Home
                "Phone" -> Icons.Filled.Phone
                "AccountBalance" -> Icons.Filled.AccountBalance
                "Category" -> Icons.Filled.Category
                "ShoppingCart" -> Icons.Filled.ShoppingCart
                "Security" -> Icons.Filled.Security
                "FitnessCenter" -> Icons.Filled.FitnessCenter
                "Fastfood" -> Icons.Filled.Fastfood
                "DirectionsCar" -> Icons.Filled.DirectionsCar
                "Pets" -> Icons.Filled.Pets
                "School" -> Icons.Filled.School
                "SportsEsports" -> Icons.Filled.SportsEsports
                "Work" -> Icons.Filled.Work
                "Wifi" -> Icons.Filled.Wifi
                "Book" -> Icons.Filled.Book
                "Flight" -> Icons.Filled.Flight
                "Restaurant" -> Icons.Filled.Restaurant
                "CreditCard" -> Icons.Filled.CreditCard
                "Subscriptions" -> Icons.Filled.Subscriptions
                "MonetizationOn" -> Icons.Filled.MonetizationOn
                else -> Icons.Filled.Payment // Default fallback
            }
        }
    }
}
