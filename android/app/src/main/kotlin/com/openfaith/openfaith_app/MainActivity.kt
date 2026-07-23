package com.openfaith.openfaith_app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
    }
}
