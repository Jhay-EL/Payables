package com.app.payables.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.compose.ui.graphics.Color
@Entity(tableName = "custom_payment_methods")
data class CustomPaymentMethod(
    @PrimaryKey
    val id: String,
    val name: String, // Custom name like "My Chase Card"
    val lastFourDigits: String, // Last 4 digits like "1234"
    val iconName: String, // Store icon name as string
    val customIconUri: String? = null, // Store custom icon URI as string (nullable)
    val colorValue: Long = Color(0xFF2196F3).value.toLong(), // Store color as Long
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    companion object {
        // Create a new custom payment method
        fun create(
            id: String = java.util.UUID.randomUUID().toString(),
            name: String,
            lastFourDigits: String,
            iconName: String,
            customIconUri: String? = null,
            colorValue: Long = Color(0xFF2196F3).value.toLong()
        ): CustomPaymentMethod {
            return CustomPaymentMethod(
                id = id,
                name = name,
                lastFourDigits = lastFourDigits,
                iconName = iconName,
                customIconUri = customIconUri,
                colorValue = colorValue,
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )
        }
    }
}
