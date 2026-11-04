package com.fukatsongs.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private val DEVICE_CHANNEL = "com.fukatsongs.app/device"
    private val VOICE_CHANNEL = "com.fukatsongs.app/voice_service"

    companion object {
        private const val REQ_RECORD_AUDIO = 4401
    }

    // Holds the pending MethodChannel result while we ask for permission
    private var pendingVoiceResult: MethodChannel.Result? = null

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
                    // 1) RECORD_AUDIO must be granted FIRST, otherwise the FGS
                    //    start will throw SecurityException on Android 14+.
                    if (ContextCompat.checkSelfPermission(
                            this, Manifest.permission.RECORD_AUDIO
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingVoiceResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            REQ_RECORD_AUDIO
                        )
                        return@setMethodCallHandler
                    }

                    // 2) Ask for battery optimization exemption (non-blocking)
                    requestIgnoreBatteryOptimizations()

                    // 3) Now safe to start the mic FGS
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != REQ_RECORD_AUDIO) return

        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (granted) {
            requestIgnoreBatteryOptimizations()
            VoiceCommandForegroundService.start(this)
            pendingVoiceResult?.success(true)
        } else {
            pendingVoiceResult?.error(
                "RECORD_AUDIO_DENIED",
                "Microphone permission is required for hands-free voice commands",
                null
            )
        }
        pendingVoiceResult = null
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as android.os.PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val i = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                i.data = Uri.parse("package:$packageName")
                startActivity(i)
            }
        }
    }
}