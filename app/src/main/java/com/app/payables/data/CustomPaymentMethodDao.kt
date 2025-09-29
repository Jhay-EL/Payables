package com.app.payables.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface CustomPaymentMethodDao {

    @Query("SELECT * FROM custom_payment_methods ORDER BY name ASC")
    fun getAllCustomPaymentMethods(): Flow<List<CustomPaymentMethod>>

    @Query("SELECT * FROM custom_payment_methods WHERE id = :id")
    suspend fun getCustomPaymentMethodById(id: String): CustomPaymentMethod?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCustomPaymentMethods(customPaymentMethods: List<CustomPaymentMethod>)

    @Update
    suspend fun updateCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod)

    @Delete
    suspend fun deleteCustomPaymentMethod(customPaymentMethod: CustomPaymentMethod)

    @Query("DELETE FROM custom_payment_methods WHERE id = :id")
    suspend fun deleteCustomPaymentMethodById(id: String)

    @Query("DELETE FROM custom_payment_methods")
    suspend fun deleteAllCustomPaymentMethods()

    @Query("SELECT COUNT(*) FROM custom_payment_methods")
    suspend fun getCustomPaymentMethodsCount(): Int
}
