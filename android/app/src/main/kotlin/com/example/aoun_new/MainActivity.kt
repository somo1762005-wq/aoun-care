package com.example.aoun_new

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import android.view.WindowManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SMS_CHANNEL = "com.aoun.app/sms"
        private const val ALARM_CHANNEL = "com.aoun.app/alarm"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSMS" -> sendSms(call.argument("phone"), call.argument("message"), result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAlarm" -> startAlarmForegroundService(
                        call.argument("title"),
                        call.argument("body"),
                        call.argument("tone"),
                        call.argument("vibration"),
                        result
                    )
                    "stopAlarm" -> stopAlarmForegroundService(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun sendSms(phone: String?, message: String?, result: MethodChannel.Result) {
        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Phone and message are required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "SEND_SMS permission not granted", null)
            return
        }

        try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            smsManager.sendTextMessage(phone.trim(), null, message, null, null)
            result.success("SMS sent successfully")
        } catch (e: Exception) {
            result.error("SMS_FAILED", e.message ?: "Failed to send SMS", null)
        }
    }

    private fun startAlarmForegroundService(
        title: String?,
        body: String?,
        tone: String?,
        vibration: Boolean?,
        result: MethodChannel.Result
    ) {
        try {
            AlarmForegroundService.startService(
                this,
                title ?: "Medicine Alarm",
                body ?: "Time to take your medicine",
                tone ?: "default",
                vibration ?: true
            )
            result.success("Alarm service started")
        } catch (e: Exception) {
            result.error("ALARM_FAILED", e.message ?: "Failed to start alarm service", null)
        }
    }

    private fun stopAlarmForegroundService(result: MethodChannel.Result) {
        try {
            AlarmForegroundService.stopService(this)
            result.success("Alarm service stopped")
        } catch (e: Exception) {
            result.error("ALARM_STOP_FAILED", e.message ?: "Failed to stop alarm service", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }
}
