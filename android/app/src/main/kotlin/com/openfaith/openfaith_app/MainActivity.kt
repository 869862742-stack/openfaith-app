package com.openfaith.openfaith_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.openfaith.openfaith_app.services.CallBroadcastReceiver

class MainActivity : FlutterActivity() {
    // Splash screen removed to fix compile error (installSplashScreen unresolved)
    // FlutterActivity handles splash via LaunchTheme in AndroidManifest.xml

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CallBroadcastReceiver.registerChannel(flutterEngine)
    }
}
