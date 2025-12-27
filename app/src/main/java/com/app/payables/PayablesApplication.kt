package com.app.payables

import android.app.Application
import com.app.payables.data.AppDatabase
import com.app.payables.data.CategoryRepository
import com.app.payables.data.CustomPaymentMethodRepository
import com.app.payables.data.PayableRepository
import com.app.payables.data.CurrencyApiService
import com.app.payables.data.CurrencyExchangeRepository
import com.app.payables.util.GoogleDriveManager
import com.app.payables.util.SettingsManager
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.decode.SvgDecoder
import androidx.work.*
import com.app.payables.work.PayableStatusWorker
import com.app.payables.work.ExchangeRateSyncWorker
import com.app.payables.work.CloudBackupSyncWorker
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.Dispatchers

class PayablesApplication : Application(), ImageLoaderFactory {
    
    // Database instance
    val database by lazy { AppDatabase.getDatabase(this) }
    
    // API Services
    val currencyApiService by lazy { CurrencyApiService() }
    
    // Repository instances
    val categoryRepository by lazy { CategoryRepository(database.categoryDao()) }
    val payableRepository by lazy { PayableRepository(database.payableDao(), this) }
    val customPaymentMethodRepository by lazy { CustomPaymentMethodRepository(database.customPaymentMethodDao()) }
    val currencyExchangeRepository by lazy { 
        CurrencyExchangeRepository(database.exchangeRateDao(), currencyApiService) 
    }
    
    // Utility managers
    val settingsManager by lazy { SettingsManager(this) }
    val googleDriveManager by lazy { GoogleDriveManager(this) }
    
    // Application-scoped coroutine scope for long-running operations
    // Uses SupervisorJob so one failed coroutine doesn't cancel all others
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onCreate() {
        super.onCreate()
        setupRecurringWork()
    }

    private fun setupRecurringWork() {
        // Payable status worker - runs daily, no network required
        val payableStatusRequest = PeriodicWorkRequestBuilder<PayableStatusWorker>(1, TimeUnit.DAYS)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "payable-status-worker",
            ExistingPeriodicWorkPolicy.KEEP,
            payableStatusRequest
        )
        
        // Exchange rate sync worker - runs every 24 hours, requires network
        val exchangeRateConstraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
            
        val exchangeRateSyncRequest = PeriodicWorkRequestBuilder<ExchangeRateSyncWorker>(
            24, TimeUnit.HOURS
        )
            .setConstraints(exchangeRateConstraints)
            .setInitialDelay(1, TimeUnit.MINUTES) // Small delay on first run
            .build()
            
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            ExchangeRateSyncWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            exchangeRateSyncRequest
        )
        
        // Cloud backup sync worker - runs daily by default, requires network
        // Actual frequency is checked inside the worker based on user settings
        val cloudBackupConstraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
            
        val cloudBackupRequest = PeriodicWorkRequestBuilder<CloudBackupSyncWorker>(
            24, TimeUnit.HOURS
        )
            .setConstraints(cloudBackupConstraints)
            .setInitialDelay(5, TimeUnit.MINUTES)
            .build()
            
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            CloudBackupSyncWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            cloudBackupRequest
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
