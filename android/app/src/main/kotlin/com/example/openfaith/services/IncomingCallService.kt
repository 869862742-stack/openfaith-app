package com.example.openfaith.services

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.openfaith.MainActivity

class IncomingCallService : Service() {
    
    companion object {
        const val CHANNEL_ID = "incoming_call_channel"
        const val NOTIFICATION_ID = 1001
        const val EXTRA_CALLER_NAME = "caller_name"
        const val EXTRA_CALL_TYPE = "call_type"
        const val EXTRA_CHANNEL_NAME = "channel_name"
        const val EXTRA_REMOTE_USER_ID = "remote_user_id"
        const val ACTION_ANSWER = "com.example.openfaith.ANSWER_CALL"
        const val ACTION_DECLINE = "com.example.openfaith.DECLINE_CALL"
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_ANSWER -> {
                // 用户点击接听 - 发送广播通知 Flutter 层
                sendBroadcast(Intent("com.example.openfaith.CALL_ANSWERED").apply {
                    putExtra(EXTRA_CHANNEL_NAME, intent.getStringExtra(EXTRA_CHANNEL_NAME))
                    putExtra(EXTRA_CALL_TYPE, intent.getStringExtra(EXTRA_CALL_TYPE))
                    putExtra(EXTRA_REMOTE_USER_ID, intent.getStringExtra(EXTRA_REMOTE_USER_ID))
                })
                stopSelf()
            }
            ACTION_DECLINE -> {
                // 用户点击拒绝 - 发送广播通知 Flutter 层
                sendBroadcast(Intent("com.example.openfaith.CALL_DECLINED").apply {
                    putExtra(EXTRA_REMOTE_USER_ID, intent.getStringExtra(EXTRA_REMOTE_USER_ID))
                })
                stopSelf()
            }
            else -> {
                // 显示来电通知
                showIncomingCallNotification(intent)
            }
        }
        return START_NOT_STICKY
    }
    
    private fun showIncomingCallNotification(intent: Intent?) {
        val callerName = intent?.getStringExtra(EXTRA_CALLER_NAME) ?: "未知来电"
        val callType = intent?.getStringExtra(EXTRA_CALL_TYPE) ?: "voice"
        
        val answerIntent = Intent(this, IncomingCallService::class.java).apply {
            action = ACTION_ANSWER
            putExtra(EXTRA_CHANNEL_NAME, intent?.getStringExtra(EXTRA_CHANNEL_NAME))
            putExtra(EXTRA_CALL_TYPE, callType)
            putExtra(EXTRA_REMOTE_USER_ID, intent?.getStringExtra(EXTRA_REMOTE_USER_ID))
        }
        val answerPendingIntent = PendingIntent.getService(
            this, 0, answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val declineIntent = Intent(this, IncomingCallService::class.java).apply {
            action = ACTION_DECLINE
            putExtra(EXTRA_REMOTE_USER_ID, intent?.getStringExtra(EXTRA_REMOTE_USER_ID))
        }
        val declinePendingIntent = PendingIntent.getService(
            this, 1, declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "incoming_call")
            putExtra(EXTRA_CALLER_NAME, callerName)
            putExtra(EXTRA_CALL_TYPE, callType)
            putExtra(EXTRA_CHANNEL_NAME, intent?.getStringExtra(EXTRA_CHANNEL_NAME))
            putExtra(EXTRA_REMOTE_USER_ID, intent?.getStringExtra(EXTRA_REMOTE_USER_ID))
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 2, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle(callerName)
            .setContentText(if (callType == "video") "视频通话来电" else "语音通话来电")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(android.R.drawable.ic_menu_call, "接听", answerPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "拒绝", declinePendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "来电通知",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "语音和视频通话来电通知"
                setSound(null, null) // 铃声由 Flutter 层控制
                enableVibration(true)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
}
