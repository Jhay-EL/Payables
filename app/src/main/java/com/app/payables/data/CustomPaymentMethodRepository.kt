package com.app.payables.data

import kotlinx.coroutines.flow.Flow
class CustomPaymentMethodRepository(private val customPaymentMethodDao: CustomPaymentMethodDao) {

    // Get all custom payment methods as Flow for UI
    fun getAllCustomPaymentMethods(): Flow<List<CustomPaymentMethod>> {
        return customPaymentMethodDao.getAllCustomPaymentMethods()
    }

    suspend fun getAllCustomPaymentMethodsList(): List<CustomPaymentMethod> {
        return customPaymentMethodDao.getAllCustomPaymentMethodsList()
    }

    suspend fun getCustomPaymentMethodById(id: String): CustomPaymentMethod? {
        return customPaymentMethodDao.getCustomPaymentMethodById(id)
    }

    // Insert a new custom payment method
    suspend fun insertCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod) {
        customPaymentMethodDao.insertCustomPaymentMethod(customPaymentMethod)
    }

    // Update an existing custom payment method
    suspend fun updateCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod) {
        customPaymentMethodDao.updateCustomPaymentMethod(customPaymentMethod)
    }

    // Delete a custom payment method
    suspend fun deleteCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod) {
        customPaymentMethodDao.deleteCustomPaymentMethod(customPaymentMethod)
    }
}
