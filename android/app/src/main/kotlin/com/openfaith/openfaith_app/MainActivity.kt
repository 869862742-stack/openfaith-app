package com.openfaith.openfaith_app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // 对齐 Flutter 视图与系统窗口
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 关键：在 Android 12+ 上禁用系统 SplashScreen 的淡出动画
        // 防止淡出过程中暴露灰色间隙
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                // 直接移除，不做淡出动画
                splashScreenView.remove()
            }
        }

        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
    }
}
