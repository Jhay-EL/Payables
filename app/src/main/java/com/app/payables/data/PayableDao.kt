package com.app.payables.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface PayableDao {
    
    @Query("SELECT * FROM payables ORDER BY billingDateMillis ASC")
    fun getAllPayables(): Flow<List<Payable>>
    
    @Query("SELECT * FROM payables WHERE id = :id")
    suspend fun getPayableById(id: String): Payable?
    
    @Query("SELECT * FROM payables WHERE category = :category ORDER BY billingDateMillis ASC")
    fun getPayablesByCategory(category: String): Flow<List<Payable>>
    
    @Query("SELECT * FROM payables WHERE isRecurring = :isRecurring ORDER BY billingDateMillis ASC")
    fun getPayablesByRecurringStatus(isRecurring: Boolean): Flow<List<Payable>>
    
    @Query("SELECT * FROM payables WHERE billingCycle = :cycle ORDER BY billingDateMillis ASC")
    fun getPayablesByCycle(cycle: String): Flow<List<Payable>>
    
    @Query("SELECT * FROM payables WHERE currency = :currency ORDER BY billingDateMillis ASC")
    fun getPayablesByCurrency(currency: String): Flow<List<Payable>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPayable(payable: Payable)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPayables(payables: List<Payable>)
    
    @Update
    suspend fun updatePayable(payable: Payable)
    
    @Delete
    suspend fun deletePayable(payable: Payable)
    
    @Query("DELETE FROM payables WHERE id = :id")
    suspend fun deletePayableById(id: String)
    
    @Query("DELETE FROM payables")
    suspend fun deleteAllPayables()
    
    @Query("SELECT COUNT(*) FROM payables")
    suspend fun getPayablesCount(): Int
    
    @Query("SELECT COUNT(*) FROM payables WHERE isRecurring = 1")
    suspend fun getRecurringPayablesCount(): Int
    
    @Query("SELECT COUNT(*) FROM payables WHERE category = :category")
    suspend fun getPayablesCountByCategory(category: String): Int
    
    @Query("""
        SELECT SUM(CAST(amount AS REAL)) 
        FROM payables 
        WHERE currency = :currency AND isRecurring = 1 AND billingCycle = :cycle
    """)
    suspend fun getTotalAmountByCurrencyAndCycle(currency: String, cycle: String): Double?
    
    @Query("""
        SELECT SUM(CAST(amount AS REAL)) 
        FROM payables 
        WHERE currency = :currency
    """)
    suspend fun getTotalAmountByCurrency(currency: String): Double?
    
    @Query("SELECT DISTINCT currency FROM payables ORDER BY currency ASC")
    suspend fun getAllUsedCurrencies(): List<String>
    
    @Query("SELECT DISTINCT category FROM payables WHERE category != 'Not set' ORDER BY category ASC")
    suspend fun getAllUsedCategories(): List<String>
    
    @Query("""
        SELECT * FROM payables 
        WHERE (title LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%') 
        ORDER BY billingDateMillis ASC
    """)
    fun searchPayables(query: String): Flow<List<Payable>>

    @Query("SELECT * FROM payables WHERE isFinished = 0 AND endDateMillis IS NOT NULL")
    suspend fun getActivePayablesWithEndDate(): List<Payable>
}

