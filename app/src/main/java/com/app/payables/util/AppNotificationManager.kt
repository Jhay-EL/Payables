package com.app.payables.util

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.app.payables.MainActivity
import com.app.payables.R
import com.app.payables.data.Payable

@SuppressLint("MissingPermission")
class AppNotificationManager(private val context: Context) {

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        private const val TAG = "AppNotificationManager"
        private const val CHANNEL_ID = "payable_reminders"
        private const val CHANNEL_NAME = "Payable Reminders"
    }

    fun createNotificationChannel() {
        try {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for upcoming payable due dates"
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                setShowBadge(true)
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create notification channel", e)
            throw e
        }
    }

    fun requestNotificationPermission(permissionLauncher: ActivityResultLauncher<String>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Requesting notification permission")
                permissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    fun hasNotificationPermission(): Boolean {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        Log.d(TAG, "Notification permission status: $hasPermission")
        return hasPermission
    }

    fun sendDuePayableNotification(payable: Payable, showOnLockscreen: Boolean = true) {
        try {
            // Check permission before sending
            if (!hasNotificationPermission()) {
                Log.w(TAG, "Cannot send notification - permission not granted")
                NotificationErrorHandler.showPermissionErrorDialog(context)
                return
            }
            
            val visibility = if (showOnLockscreen) {
                NotificationCompat.VISIBILITY_PUBLIC
            } else {
                NotificationCompat.VISIBILITY_SECRET
            }
            
            // Create intent to open app and navigate to specific payable
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("PAYABLE_ID", payable.id)
                putExtra("OPEN_PAYABLE", true)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                payable.id.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle("Payable Due: ${payable.title}")
                .setContentText("Your payable for ${payable.title} is due today.")
                .setSmallIcon(R.drawable.ic_notification)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(visibility)
                .setAutoCancel(true)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setContentIntent(pendingIntent)
                .build()

            notificationManager.notify(payable.id.hashCode(), notification)
            Log.d(TAG, "Notification sent successfully for: ${payable.title}")
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception sending notification for ${payable.title}", e)
            NotificationErrorHandler.handleNotificationSendError(payable.title, e)
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send notification for ${payable.title}", e)
            NotificationErrorHandler.handleNotificationSendError(payable.title, e)
            throw e
        }
    }
}
