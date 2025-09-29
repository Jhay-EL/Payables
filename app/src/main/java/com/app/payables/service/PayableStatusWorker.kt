package com.app.payables.service

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.app.payables.PayablesApplication
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PayableStatusWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val payableRepository = (applicationContext as PayablesApplication).payableRepository

        return withContext(Dispatchers.IO) {
            try {
                payableRepository.finishPastDuePayables()
                Result.success()
            } catch (e: Exception) {
                Result.failure()
            }
        }
    }
}
