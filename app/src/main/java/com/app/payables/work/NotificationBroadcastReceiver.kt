package com.app.payables.work

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.app.payables.PayablesApplication
import com.app.payables.util.AppNotificationManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class NotificationBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val payableId = intent.getStringExtra("payable_id") ?: return

        val app = context.applicationContext as PayablesApplication
        val repository = app.payableRepository
        val notificationManager = AppNotificationManager(context)

        CoroutineScope(Dispatchers.IO).launch {
            repository.getPayableById(payableId)?.let { payable ->
                notificationManager.sendDuePayableNotification(payable)
            }
        }
    }
}
