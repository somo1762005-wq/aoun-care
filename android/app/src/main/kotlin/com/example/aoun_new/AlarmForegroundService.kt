package com.example.aoun_new

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class AlarmForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null

    companion object {
        private const val CHANNEL_ID = "alarm_foreground_channel"
        private const val NOTIFICATION_ID = 1001
        private const val ACTION_START_ALARM = "START_ALARM"
        private const val ACTION_STOP_ALARM = "STOP_ALARM"
        private const val ACTION_UPDATE_ALARM = "UPDATE_ALARM"
        
        fun startService(context: Context, title: String, body: String, tone: String, vibration: Boolean) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_START_ALARM
                putExtra("title", title)
                putExtra("body", body)
                putExtra("tone", tone)
                putExtra("vibration", vibration)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_STOP_ALARM
            }
            context.startService(intent)
        }
        
        fun updateAlarm(context: Context, title: String, body: String) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_UPDATE_ALARM
                putExtra("title", title)
                putExtra("body", body)
            }
            context.startService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        initializeFlutterEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_ALARM -> {
                val title = intent.getStringExtra("title") ?: "Medicine Alarm"
                val body = intent.getStringExtra("body") ?: "Time to take your medicine"
                val tone = intent.getStringExtra("tone") ?: "default"
                val vibration = intent.getBooleanExtra("vibration", true)
                
                startForegroundAlarm(title, body, tone, vibration)
            }
            ACTION_STOP_ALARM -> {
                stopAlarm()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_UPDATE_ALARM -> {
                val title = intent.getStringExtra("title") ?: "Medicine Alarm"
                val body = intent.getStringExtra("body") ?: "Time to take your medicine"
                updateNotification(title, body)
            }
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        flutterEngine?.destroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Foreground Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Keeps the alarm running even when app is closed"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initializeFlutterEngine() {
        flutterEngine = FlutterEngine(this)
        flutterEngine?.dartExecutor?.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        
        methodChannel = MethodChannel(flutterEngine!!.dartExecutor!!.binaryMessenger, "com.aoun.app/alarm_service")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "stopAlarm" -> {
                    stopAlarm()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startForegroundAlarm(title: String, body: String, tone: String, vibration: Boolean) {
        val notification = createNotification(title, body)
        startForeground(NOTIFICATION_ID, notification)
        
        // Start playing alarm sound
        playAlarmSound(tone)
    }

    private fun createNotification(title: String, body: String): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)

        return builder.build()
    }

    private fun updateNotification(title: String, body: String) {
        val notification = createNotification(title, body)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun playAlarmSound(tone: String) {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer()
            
            // Use system alarm sounds instead of custom raw resources
            val alarmUri = when (tone) {
                "repeated" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                "sharp" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            }
            
            mediaPlayer?.setDataSource(applicationContext, alarmUri)
            mediaPlayer?.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            
            mediaPlayer?.isLooping = true
            mediaPlayer?.prepare()
            mediaPlayer?.start()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarm() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
