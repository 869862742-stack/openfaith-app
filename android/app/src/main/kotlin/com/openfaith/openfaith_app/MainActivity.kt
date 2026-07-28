package com.openfaith.openfaith_app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // 安装系统 splash screen — 让它持续到 Flutter 第一帧渲染完成
        installSplashScreen()
        
        // 强制设置窗口背景为深色
        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#050816")))
        
        super.onCreate(savedInstanceState)
        
        // super.onCreate 之后再设一次，防止被覆盖
        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#050816")))
    }

    private val INSTALL_CHANNEL = "openfaith/install_settings"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openInstallSettings") {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // 降级：打开应用设置页
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
