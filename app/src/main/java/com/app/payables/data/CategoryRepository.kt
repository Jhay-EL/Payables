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

    suspend fun getNonDefaultCategoriesList(): List<Category> {
        return categoryDao.getNonDefaultCategoriesList()
    }

    suspend fun getCategoryById(id: String): Category? {
        return categoryDao.getCategoryById(id)
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

    suspend fun updateCategory(category: Category) {
        categoryDao.updateCategory(category)
    }

    suspend fun deleteAllCustomCategories() {
        categoryDao.deleteAllNonDefaultCategories()
    }
    
    // Delete a category by ID
    suspend fun deleteCategory(id: String) {
        categoryDao.deleteCategoryById(id)
    }
    
    // Update category count
    suspend fun updateCategoryCount(id: String, count: String) {
        categoryDao.updateCategoryCount(id, count)
    }
    
}
