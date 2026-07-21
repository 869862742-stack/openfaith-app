package com.openfaith.openfaith_app.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CallBroadcastReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallBroadcastReceiver"
        private const val CHANNEL_NAME = "com.openfaith.openfaith_app/calls"

        // Static reference to Flutter MethodChannel for cross-component communication
        var methodChannel: MethodChannel? = null

        /**
         * Call this from MainActivity.configureFlutterEngine() to register the channel.
         * Example:
         *   CallBroadcastReceiver.registerChannel(flutterEngine)
         */
        fun registerChannel(flutterEngine: FlutterEngine) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            Log.d(TAG, "MethodChannel registered: $CHANNEL_NAME")
        }

        fun unregisterChannel() {
            methodChannel = null
            Log.d(TAG, "MethodChannel unregistered")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast: $action")

        val channel = methodChannel ?: run {
            Log.w(TAG, "MethodChannel is null, cannot notify Flutter")
            return
        }

        when (action) {
            CallConnectionService.ACTION_CALL_ANSWERED -> {
                val phoneNumber = intent.getStringExtra(CallConnectionService.EXTRA_CALL_NUMBER) ?: ""
                Log.d(TAG, "Call answered, number: $phoneNumber")
                channel.invokeMethod("onCallAnswered", mapOf(
                    "phoneNumber" to phoneNumber
                ))
            }
            CallConnectionService.ACTION_CALL_DECLINED -> {
                val phoneNumber = intent.getStringExtra(CallConnectionService.EXTRA_CALL_NUMBER) ?: ""
                Log.d(TAG, "Call declined, number: $phoneNumber")
                channel.invokeMethod("onCallDeclined", mapOf(
                    "phoneNumber" to phoneNumber
                ))
            }
            else -> {
                Log.w(TAG, "Unknown broadcast action: $action")
            }
        }
    }
}
