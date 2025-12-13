package com.app.payables

import android.app.Application
import com.app.payables.data.AppDatabase
import com.app.payables.data.CategoryRepository
import com.app.payables.data.CustomPaymentMethodRepository
import com.app.payables.data.PayableRepository
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.decode.SvgDecoder
import androidx.work.*
import com.app.payables.work.PayableStatusWorker
import java.util.concurrent.TimeUnit

class PayablesApplication : Application(), ImageLoaderFactory {
    
    // Database instance
    val database by lazy { AppDatabase.getDatabase(this) }
    
    // Repository instances
    val categoryRepository by lazy { CategoryRepository(database.categoryDao()) }
    val payableRepository by lazy { PayableRepository(database.payableDao(), this) }
    val customPaymentMethodRepository by lazy { CustomPaymentMethodRepository(database.customPaymentMethodDao()) }

    override fun onCreate() {
        super.onCreate()
        setupRecurringWork()
    }

    private fun setupRecurringWork() {
        // Removed network constraint - notifications don't require network
        val workRequest = PeriodicWorkRequestBuilder<PayableStatusWorker>(1, TimeUnit.DAYS)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "payable-status-worker",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }

    override fun newImageLoader(): ImageLoader {
        return ImageLoader.Builder(this)
            .components {
                add(SvgDecoder.Factory())
            }
            .build()
    }
}
