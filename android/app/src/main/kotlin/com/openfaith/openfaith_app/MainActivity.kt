package com.openfaith.openfaith_app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // 在最开始就强制设置窗口背景为深色
        // 绕过所有 theme 解析问题，确保第一帧就是 #050816
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
