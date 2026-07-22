package com.openfaith.openfaith_app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // MUST be first: initialize Activity before any window operations
        super.onCreate(savedInstanceState)

        // 对齐 Flutter 视图与系统窗口
        try {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } catch (e: Exception) {
            // Silently handle - window may not be ready
        }

        // Android 12+: 禁用系统 SplashScreen 的淡出动画
        // 防止淡出过程中暴露灰色间隙
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val splashScreen = installSplashScreen()
                splashScreen.setOnExitAnimationListener { splashScreenView ->
                    try {
                        splashScreenView.remove()
                    } catch (e: Exception) {
                        // Silently handle on OEM devices where remove() may conflict
                    }
                }
            } catch (e: Exception) {
                // installSplashScreen may not be available on all devices
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
    }
}
