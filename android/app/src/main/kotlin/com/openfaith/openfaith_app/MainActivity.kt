package com.openfaith.openfaith_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install compat splash screen — keeps dark background visible
        // from Android window until Flutter renders its first frame.
        // This eliminates the gray screen gap on ALL Android versions (7-16).
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
    }
}
