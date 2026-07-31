package com.openfaith.openfaith_app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.media.AudioManager
import android.content.Context
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        installSplashScreen()
        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#050816")))
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#050816")))
    }

    private val INSTALL_CHANNEL = "openfaith/install_settings"
    private val AUDIO_CHANNEL = "openfaith/audio_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
        
        // 安装设置通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openInstallSettings") {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    }
                } else {
                    result.notImplemented()
                }
            }
        
        // 音频模式管理通道 - 解决 WebView 与 Agora SDK 的音频焦点冲突
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                when (call.method) {
                    "setCallMode" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            val mode = args?.get("mode") as? String ?: "normal"
                            val speakerOn = args?.get("speakerOn") as? Boolean ?: true
                            
                            when (mode) {
                                "communication" -> {
                                    // 设置通话模式 - 这是关键！
                                    // MODE_IN_COMMUNICATION 优化了双向实时语音，
                                    // 禁用系统音频处理（回声消除、降噪等由 Agora SDK 处理）
                                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                                    
                                    // 请求音频焦点（通话级别）
                                    audioManager.requestAudioFocus(
                                        null,
                                        AudioManager.STREAM_VOICE_CALL,
                                        AudioManager.AUDIOFOCUS_GAIN
                                    )
                                    
                                    // 设置扬声器
                                    audioManager.isSpeakerphoneOn = speakerOn
                                    
                                    // 确保麦克风没有被静音
                                    audioManager.isMicrophoneMute = false
                                }
                                "normal" -> {
                                    // 恢复正常模式
                                    audioManager.mode = AudioManager.MODE_NORMAL
                                    
                                    // 释放音频焦点
                                    audioManager.abandonAudioFocus(null)
                                    
                                    // 关闭扬声器
                                    audioManager.isSpeakerphoneOn = false
                                }
                            }
                            
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("AUDIO_ERROR", e.message, null)
                        }
                    }
                    "setSpeakerphone" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            val on = args?.get("on") as? Boolean ?: true
                            audioManager.isSpeakerphoneOn = on
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("AUDIO_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
