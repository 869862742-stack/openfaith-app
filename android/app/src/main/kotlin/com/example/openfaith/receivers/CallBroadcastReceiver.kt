package com.example.openfaith.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class CallBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "CallReceiver"
        const val ACTION_CALL_ANSWERED = "com.example.openfaith.CALL_ANSWERED"
        const val ACTION_CALL_DECLINED = "com.example.openfaith.CALL_DECLINED"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            ACTION_CALL_ANSWERED -> {
                Log.d(TAG, "Call answered")
                // 通过 MethodChannel 通知 Flutter 层
                // 需要 MainActivity 持有 MethodChannel 引用
            }
            ACTION_CALL_DECLINED -> {
                Log.d(TAG, "Call declined")
            }
        }
    }
}
