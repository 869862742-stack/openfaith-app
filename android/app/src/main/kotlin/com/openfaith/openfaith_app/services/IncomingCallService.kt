package com.openfaith.openfaith_app.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class IncomingCallService : Service() {

    companion object {
        private const val TAG = "IncomingCallService"
        const val ACTION_SHOW_INCOMING_CALL = "com.openfaith.openfaith_app.ACTION_SHOW_INCOMING_CALL"
        const val ACTION_DISMISS_INCOMING_CALL = "com.openfaith.openfaith_app.ACTION_DISMISS_INCOMING_CALL"
        const val EXTRA_CALLER_NUMBER = "caller_number"
        const val EXTRA_CALLER_NAME = "caller_name"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "incoming_call_channel"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "IncomingCallService created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand: action=$action")

        when (action) {
            ACTION_SHOW_INCOMING_CALL -> {
                val callerNumber = intent.getStringExtra(EXTRA_CALLER_NUMBER) ?: "Unknown"
                val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: callerNumber
                showIncomingCallNotification(callerNumber, callerName)
            }
            ACTION_DISMISS_INCOMING_CALL -> {
                dismissNotification()
                stopSelf()
            }
            else -> {
                Log.w(TAG, "Unknown action: $action")
            }
        }

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for incoming calls"
                enableVibration(true)
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showIncomingCallNotification(callerNumber: String, callerName: String) {
        // Build Answer action intent - sends broadcast with unified action
        val answerIntent = Intent(CallConnectionService.ACTION_CALL_ANSWERED).apply {
            setPackage(packageName)
            putExtra(CallConnectionService.EXTRA_CALL_NUMBER, callerNumber)
        }

        // Build Decline action intent - sends broadcast with unified action
        val declineIntent = Intent(CallConnectionService.ACTION_CALL_DECLINED).apply {
            setPackage(packageName)
            putExtra(CallConnectionService.EXTRA_CALL_NUMBER, callerNumber)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("Incoming Call")
            .setContentText("$callerName ($callerNumber)")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(null, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "Incoming call notification shown for: $callerName")
    }

    private fun dismissNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
        Log.d(TAG, "Incoming call notification dismissed")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "IncomingCallService destroyed")
    }
}
