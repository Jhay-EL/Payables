package com.app.payables.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

@Entity(tableName = "categories")
data class Category(
    @PrimaryKey
    val id: String,
    val name: String,
    val colorValue: Long, // Store as Long to persist Color
    val iconName: String, // Store icon name as string
    val count: String = "0",
    val isDefault: Boolean = false
) {
    // Convert to UI CategoryData
    fun toCategoryData(): com.app.payables.ui.CategoryData {
        return com.app.payables.ui.CategoryData(
            id = id,
            name = name,
            count = count,
            color = Color(colorValue.toULong()),
            icon = getIconFromName(iconName)
        )
    }
    
    companion object {
        // Convert from UI CategoryData
        fun fromCategoryData(categoryData: com.app.payables.ui.CategoryData, isDefault: Boolean = false): Category {
            return Category(
                id = categoryData.id,
                name = categoryData.name,
                colorValue = categoryData.color.value.toLong(),
                iconName = getIconName(categoryData.icon),
                count = categoryData.count,
                isDefault = isDefault
            )
        }
        
        // Map icon to string name
        private fun getIconName(icon: ImageVector): String {
            return when (icon) {
                Icons.Filled.PlayArrow -> "PlayArrow"
                Icons.Filled.Cloud -> "Cloud"
                Icons.Filled.Home -> "Home"
                Icons.Filled.Phone -> "Phone"
                Icons.Filled.AccountBalance -> "AccountBalance"
                Icons.Filled.Category -> "Category"
                Icons.Filled.ShoppingCart -> "ShoppingCart"
                Icons.Filled.Security -> "Security"
                Icons.Filled.FitnessCenter -> "FitnessCenter"
                Icons.Filled.Fastfood -> "Fast food"
                Icons.Filled.DirectionsCar -> "DirectionsCar"
                Icons.Filled.Pets -> "Pets"
                Icons.Filled.School -> "School"
                Icons.Filled.SportsEsports -> "SportsEsports"
                Icons.Filled.Work -> "Work"
                Icons.Filled.Wifi -> "Wifi"
                Icons.Filled.MusicNote -> "MusicNote"
                Icons.Filled.Book -> "Book"
                Icons.Filled.Flight -> "Flight"
                Icons.Filled.Restaurant -> "Restaurant"
                else -> "Category" // Default fallback
            }
        }
        
        // Map string name to icon
        private fun getIconFromName(iconName: String): ImageVector {
            return when (iconName) {
                "PlayArrow" -> Icons.Filled.PlayArrow
                "Cloud" -> Icons.Filled.Cloud
                "Home" -> Icons.Filled.Home
                "Phone" -> Icons.Filled.Phone
                "AccountBalance" -> Icons.Filled.AccountBalance
                "Category" -> Icons.Filled.Category
                "ShoppingCart" -> Icons.Filled.ShoppingCart
                "Security" -> Icons.Filled.Security
                "FitnessCenter" -> Icons.Filled.FitnessCenter
                "Fast food" -> Icons.Filled.Fastfood
                "DirectionsCar" -> Icons.Filled.DirectionsCar
                "Pets" -> Icons.Filled.Pets
                "School" -> Icons.Filled.School
                "SportsEsports" -> Icons.Filled.SportsEsports
                "Work" -> Icons.Filled.Work
                "Wifi" -> Icons.Filled.Wifi
                "MusicNote" -> Icons.Filled.MusicNote
                "Book" -> Icons.Filled.Book
                "Flight" -> Icons.Filled.Flight
                "Restaurant" -> Icons.Filled.Restaurant
                else -> Icons.Filled.Category // Default fallback
            }
        }
    }
}
