package com.openfaith.openfaith_app.services

import android.net.Uri
import android.os.Bundle
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log

class CallConnectionService : ConnectionService() {

    companion object {
        private const val TAG = "CallConnectionService"
        const val ACTION_CALL_ANSWERED = "com.openfaith.openfaith_app.CALL_ANSWERED"
        const val ACTION_CALL_DECLINED = "com.openfaith.openfaith_app.CALL_DECLINED"
        const val EXTRA_CALL_NUMBER = "extra_call_number"
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        Log.d(TAG, "onCreateIncomingConnection called")

        val connection = object : Connection() {
            init {
                // Try to get caller info from request extras
                try {
                    val extras = request?.extras
                    val handle = if (extras != null) {
                        @Suppress("DEPRECATION")
                        extras.getParcelable<Uri>(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS)
                    } else null

                    if (handle != null) {
                        setAddress(handle, TelecomManager.PRESENTATION_ALLOWED)
                        Log.d(TAG, "Set caller address: $handle")
                    } else {
                        Log.w(TAG, "No incoming call address found in extras")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set address from extras: ${e.message}")
                }

                // Set connection properties
                connectionProperties = PROPERTY_SELF_MANAGED
                connectionCapabilities = CAPABILITY_HOLD or CAPABILITY_SUPPORT_HOLD
                setAudioModeIsVoip(true)
            }

            override fun onAnswer() {
                Log.d(TAG, "Incoming call answered")
                // Send broadcast to notify other components
                val intent = android.content.Intent(ACTION_CALL_ANSWERED).apply {
                    setPackage(packageName)
                }
                sendBroadcast(intent)
                setActive()
            }

            override fun onReject() {
                Log.d(TAG, "Incoming call rejected")
                val intent = android.content.Intent(ACTION_CALL_DECLINED).apply {
                    setPackage(packageName)
                }
                sendBroadcast(intent)
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.REJECTED))
                destroy()
            }

            override fun onDisconnect() {
                Log.d(TAG, "Call disconnected")
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.LOCAL))
                destroy()
            }

            override fun onAbort() {
                Log.d(TAG, "Call aborted")
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.CANCELED))
                destroy()
            }

            override fun onHold() {
                Log.d(TAG, "Call put on hold")
                setOnHold()
            }
        }

        return connection
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        Log.d(TAG, "onCreateOutgoingConnection called")

        val connection = object : Connection() {
            init {
                // Set the address from the outgoing request handle
                val handle = request?.address
                if (handle != null) {
                    setAddress(handle, TelecomManager.PRESENTATION_ALLOWED)
                    Log.d(TAG, "Set outgoing call address: $handle")
                }

                connectionProperties = PROPERTY_SELF_MANAGED
                connectionCapabilities = CAPABILITY_HOLD or CAPABILITY_SUPPORT_HOLD
                setAudioModeIsVoip(true)
            }

            override fun onDisconnect() {
                Log.d(TAG, "Outgoing call disconnected")
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.LOCAL))
                destroy()
            }

            override fun onAbort() {
                Log.d(TAG, "Outgoing call aborted")
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.CANCELED))
                destroy()
            }

            override fun onHold() {
                Log.d(TAG, "Outgoing call put on hold")
                setOnHold()
            }
        }

        connection.setActive()
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
