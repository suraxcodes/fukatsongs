package com.fukatsongs.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Wrapper around VoiceCommandForegroundService so the microphone FGS is
 * guaranteed to die with the task.
 *
 * - Base class returns START_NOT_STICKY (see D8), so the OS will not
 *   resurrect it after a swipe.
 * - onTaskRemoved fires when the user swipes the app out of Recents.
 * - The manifest entry adds android:stopWithTask="true" as belt-and-braces.
 *
 * Safe because this service is STARTED (startForegroundService), not bound.
 */
class VoiceFgsWrapper : VoiceCommandForegroundService() {

    private val tag = "VoiceFgsWrapper"

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(tag, "onTaskRemoved — tearing down microphone FGS")
        teardown()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        teardown()
        super.onDestroy()
    }

    private fun teardown() {
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (_: Throwable) {
        }
        try {
            (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                ?.cancel(NOTIFICATION_ID)
        } catch (_: Throwable) {
        }
        stopSelf()
    }
}

