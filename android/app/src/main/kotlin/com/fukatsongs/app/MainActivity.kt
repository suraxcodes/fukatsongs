package com.fukatsongs.app

import android.os.Build
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private val DEVICE_CHANNEL = "com.fukatsongs.app/device"
    private val VOICE_CHANNEL = "com.fukatsongs.app/voice_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidId") {
                val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                result.success(androidId)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVoiceService" -> {
                    // Request battery optimization exemption (one-time, user-prompted)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val i = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            i.data = Uri.parse("package:$packageName")
                            startActivity(i)
                        }
                    }
                    VoiceCommandForegroundService.start(this)
                    result.success(true)
                }
                "stopVoiceService" -> {
                    VoiceCommandForegroundService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
