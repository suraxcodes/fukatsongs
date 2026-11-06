package com.fukatsongs.audio_capture

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class AudioCapturePlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var audioRecord: AudioRecord? = null
    private var captureThread: Thread? = null
    private val isCapturing = AtomicBoolean(false)

    private var audioManager: AudioManager? = null
    private var scoActive = false

    companion object {
        private const val TAG = "AudioCapturePlugin"
        private const val METHOD_CHANNEL = "audio_capture_plugin/method"
        private const val EVENT_CHANNEL = "audio_capture_plugin/pcm"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopCaptureInternal()
        stopScoInternal()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startCapture" -> {
                val audioSourceName = call.argument<String>("audioSource") ?: "MIC"
                val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                startCaptureInternal(audioSourceName, sampleRate, result)
            }
            "stopCapture" -> {
                stopCaptureInternal()
                result.success(true)
            }
            "startSco" -> startScoInternal(result)
            "stopSco" -> {
                stopScoInternal()
                result.success(true)
            }
            "isScoAvailable" -> {
                val available = audioManager?.isBluetoothScoAvailableOffCall ?: false
                result.success(available)
            }
            else -> result.notImplemented()
        }
    }

    private fun startCaptureInternal(
        audioSourceName: String,
        sampleRate: Int,
        result: MethodChannel.Result
    ) {
        if (isCapturing.get()) {
            result.error("ALREADY_CAPTURING", "Capture is already running", null)
            return
        }

        if (ContextCompat.checkSelfPermission(
                context, Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "RECORD_AUDIO not granted", null)
            return
        }

        // NOTE: Android's MediaRecorder.AudioSource has no BLUETOOTH constant.
        // When Bluetooth SCO is active (via startSco()), the OS automatically
        // routes MIC source to the connected headset's mic. We map "BLUETOOTH"
        // to MIC here and rely on SCO state to deliver Bluetooth mic input.
        val audioSource = when (audioSourceName.uppercase()) {
            "MIC" -> MediaRecorder.AudioSource.MIC
            "VOICE_RECOGNITION" -> MediaRecorder.AudioSource.VOICE_RECOGNITION
            "VOICE_COMMUNICATION" -> MediaRecorder.AudioSource.VOICE_COMMUNICATION
            "BLUETOOTH" -> MediaRecorder.AudioSource.MIC
            "CAMCORDER" -> MediaRecorder.AudioSource.CAMCORDER
            else -> {
                result.error("INVALID_SOURCE", "Unknown audio source: $audioSourceName", null)
                return
            }
        }

        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        if (minBuffer <= 0) {
            result.error("BUFFER_ERROR", "Invalid buffer size: $minBuffer", null)
            return
        }
        val bufferSize = minBuffer * 2

        try {
            val record = AudioRecord(
                audioSource,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize
            )
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                result.error("INIT_FAILED", "AudioRecord failed to initialize", null)
                record.release()
                return
            }

            audioRecord = record
            isCapturing.set(true)
            record.startRecording()

            captureThread = Thread {
                val buffer = ByteArray(bufferSize)
                while (isCapturing.get()) {
                    val bytesRead = record.read(buffer, 0, buffer.size)
                    if (bytesRead > 0) {
                        val chunk = buffer.copyOf(bytesRead)
                        mainHandler.post { eventSink?.success(chunk) }
                    } else if (bytesRead < 0) {
                        Log.e(TAG, "AudioRecord.read error: $bytesRead")
                        break
                    }
                }
            }.also { it.start() }

            result.success(true)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: ${e.message}")
            result.error(
                "SECURITY_EXCEPTION",
                "Audio source rejected: ${e.message}. " +
                    "Some audio sources require an active SCO session.",
                null
            )
        } catch (e: Exception) {
            Log.e(TAG, "startCapture failed: ${e.message}")
            result.error("CAPTURE_FAILED", e.message, null)
        }
    }

    private fun stopCaptureInternal() {
        isCapturing.set(false)
        try {
            captureThread?.join(1000)
        } catch (_: InterruptedException) {}
        captureThread = null
        try {
            audioRecord?.stop()
        } catch (_: Exception) {}
        try {
            audioRecord?.release()
        } catch (_: Exception) {}
        audioRecord = null
    }

    private fun startScoInternal(result: MethodChannel.Result) {
        val am = audioManager ?: run {
            result.error("NO_AUDIO_MANAGER", "AudioManager unavailable", null)
            return
        }
        if (!am.isBluetoothScoAvailableOffCall) {
            result.error(
                "SCO_NOT_AVAILABLE",
                "Device does not support off-call Bluetooth SCO.",
                null
            )
            return
        }
        try {
            am.mode = AudioManager.MODE_IN_COMMUNICATION
            am.startBluetoothSco()
            am.isBluetoothScoOn = true
            scoActive = true
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "startSco failed: ${e.message}")
            result.error("SCO_FAILED", e.message, null)
        }
    }

    private fun stopScoInternal() {
        val am = audioManager ?: return
        try {
            am.isBluetoothScoOn = false
            am.stopBluetoothSco()
            am.mode = AudioManager.MODE_NORMAL
        } catch (_: Exception) {}
        scoActive = false
    }
}