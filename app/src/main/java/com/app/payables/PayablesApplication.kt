package com.app.payables

import android.app.Application
import com.app.payables.data.AppDatabase
import com.app.payables.data.CategoryRepository
import com.app.payables.data.PayableRepository
import com.app.payables.data.CustomPaymentMethodRepository
import androidx.work.*
import com.app.payables.work.PayableStatusWorker
import java.util.concurrent.TimeUnit

class PayablesApplication : Application() {
    
    // Database instance
    val database by lazy { AppDatabase.getDatabase(this) }
    
    // Repository instances
    val categoryRepository by lazy { CategoryRepository(database.categoryDao()) }
    val payableRepository by lazy { PayableRepository(database.payableDao()) }
    val customPaymentMethodRepository by lazy { CustomPaymentMethodRepository(database.customPaymentMethodDao()) }

    override fun onCreate() {
        super.onCreate()
        setupRecurringWork()
    }

    private fun setupRecurringWork() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<PayableStatusWorker>(1, TimeUnit.DAYS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "payable-status-worker",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }
}
