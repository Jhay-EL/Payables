package com.app.payables.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import com.app.payables.ui.CategoryData

class CategoryRepository(private val categoryDao: CategoryDao) {
    
    // Get all categories as Flow of CategoryData for UI
    fun getAllCategories(): Flow<List<CategoryData>> {
        return categoryDao.getAllCategories().map { categories ->
            categories.map { it.toCategoryData() }
        }
    }
    
    // Insert a new category
    suspend fun insertCategory(categoryData: CategoryData, isDefault: Boolean = false) {
        val category = Category.fromCategoryData(categoryData, isDefault)
        categoryDao.insertCategory(category)
    }
    
    // Update an existing category
    suspend fun updateCategory(categoryData: CategoryData) {
        val category = Category.fromCategoryData(categoryData, false)
        categoryDao.updateCategory(category)
    }
    
    // Delete a category by ID
    suspend fun deleteCategory(id: String) {
        categoryDao.deleteCategoryById(id)
    }
    
    // Update category count
    suspend fun updateCategoryCount(id: String, count: String) {
        categoryDao.updateCategoryCount(id, count)
    }
    
    // Check if default categories exist and restore them if missing
    suspend fun ensureDefaultCategories() {
        val defaultCategoriesCount = categoryDao.getDefaultCategoriesCount()
        if (defaultCategoriesCount < 5) {
            // Restore default categories if any are missing
            restoreDefaultCategories()
        }
    }
    
    // Restore default categories (useful for app updates/installs)
    private suspend fun restoreDefaultCategories() {
        val defaultCategories = listOf(
            Category(
                id = "default_entertainment",
                name = "Entertainment",
                colorValue = androidx.compose.ui.graphics.Color(0xFFFF6B6B).value.toLong(),
                iconName = "PlayArrow",
                count = "0",
                isDefault = true
            ),
            Category(
                id = "default_cloud_software",
                name = "Cloud & Software",
                colorValue = androidx.compose.ui.graphics.Color(0xFF4ECDC4).value.toLong(),
                iconName = "Cloud",
                count = "0",
                isDefault = true
            ),
            Category(
                id = "default_utilities_household",
                name = "Utilities & Household",
                colorValue = androidx.compose.ui.graphics.Color(0xFF45B7D1).value.toLong(),
                iconName = "Home",
                count = "0",
                isDefault = true
            ),
            Category(
                id = "default_mobile_connectivity",
                name = "Mobile & Connectivity",
                colorValue = androidx.compose.ui.graphics.Color(0xFF96CEB4).value.toLong(),
                iconName = "Phone",
                count = "0",
                isDefault = true
            ),
            Category(
                id = "default_insurance_finance",
                name = "Insurance & Finance",
                colorValue = androidx.compose.ui.graphics.Color(0xFFFFEAA7).value.toLong(),
                iconName = "AccountBalance",
                count = "0",
                isDefault = true
            )
        )
        
        categoryDao.insertCategories(defaultCategories)
    }
}
