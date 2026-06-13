package com.example.aoun_new

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.aoun.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                try {
                    val smsManager = SmsManager.getDefault()
                    smsManager.sendTextMessage(phone, null, message, null, null)
                    result.success("SMS Sent Successfully")
                } catch (e: Exception) {
                    result.error("SMS_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
