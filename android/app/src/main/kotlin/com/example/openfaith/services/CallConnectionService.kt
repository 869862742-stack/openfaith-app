package com.example.openfaith.services

import android.net.Uri
import android.os.Build
import android.telecom.*
import android.util.Log

class CallConnectionService : ConnectionService() {
    companion object {
        const val TAG = "CallConnectionService"
    }
    
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        Log.d(TAG, "onCreateIncomingConnection")
        
        val connection = object : Connection() {
            override fun onAnswer() {
                Log.d(TAG, "onAnswer")
                connectionActive()
                // 通知 Flutter 层接听
                sendBroadcast(android.content.Intent("com.example.openfaith.CALL_ANSWERED"))
            }
            
            override fun onReject() {
                Log.d(TAG, "onReject")
                cleanupConnection()
                sendBroadcast(android.content.Intent("com.example.openfaith.CALL_DECLINED"))
            }
            
            override fun onDisconnect() {
                Log.d(TAG, "onDisconnect")
                cleanupConnection()
            }
            
            private fun connectionActive() {
                connectionProperties = Connection.PROPERTY_ACTIVE
                setConnectionCapabilities(Connection.CAPABILITY_HOLD)
            }
            
            private fun cleanupConnection() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            }
        }
        
        request?.handle?.let { connection.setAddress(it, TelecomManager.PRESENTATION_ALLOWED) }
        connection.setConnectionCapabilities(
            Connection.CAPABILITY_HOLD or Connection.CAPABILITY_SUPPORT_HOLD
        )
        connection.setAudioModeIsVoip(true)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            connection.setConnectionProperties(Connection.PROPERTY_SELF_MANAGED)
        }
        
        return connection
    }
    
    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        Log.d(TAG, "onCreateOutgoingConnection")
        
        val connection = object : Connection() {
            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            }
        }
        
        request?.handle?.let { connection.setAddress(it, TelecomManager.PRESENTATION_ALLOWED) }
        connection.setAudioModeIsVoip(true)
        
        return connection
    }
    
    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ) {
        Log.e(TAG, "onCreateIncomingConnectionFailed")
    }
    
    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ) {
        Log.e(TAG, "onCreateOutgoingConnectionFailed")
    }
}
