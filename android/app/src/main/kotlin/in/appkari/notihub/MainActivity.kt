package `in`.appkari.notihub

import `in`.appkari.notihub.NotiHubNotificationService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.content.Intent
import android.net.Uri
import android.app.Notification
import android.app.NotificationChannel
import android.content.pm.PackageManager
import android.util.Log
import java.util.Random

class MainActivity : FlutterActivity() {
    private val CHANNEL = "notification_capture"
    private val NOTIFICATION_LISTENER_SETTINGS = "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        NotiHubNotificationService.channel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "removeNotification" -> {
                    val key = call.argument<String>("key")
                    if (key != null) {
                        NotiHubNotificationService.removeNotificationByKey(key)
                        result.success(null)
                    } else {
                        result.error("INVALID_KEY", "Key is null", null)
                    }
                }
                "updateRemoveSystemTraySetting" -> {
                    // Allows Flutter to control whether notifications are removed from the system tray
                    val remove = call.argument<Boolean>("remove")
                    if (remove != null) {
                        NotiHubNotificationService.shouldRemoveSystemTrayNotification = remove
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Argument 'remove' is null", null)
                    }
                }
                "requestPermission" -> {
                    // Open notification listener settings if not enabled
                    if (!isNotificationServiceEnabled()) {
                        val intent = Intent(NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        // Can't know if granted immediately, return false for now
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                "isPermissionGranted" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "startListening" -> {
                    NotiHubNotificationService.isListening = true
                    result.success(true)
                }
                "stopListening" -> {
                    NotiHubNotificationService.isListening = false
                    result.success(true)
                }
                "sendTestNotification" -> {
                    val title = call.argument<String>("title") ?: "Test Notification"
                    val body = call.argument<String>("body") ?: "This is a test notification"
                    sendTestNotification(title, body)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = android.provider.Settings.Secure.getString(contentResolver,
            "enabled_notification_listeners")
        return flat?.contains(packageName) ?: false
    }

    private fun requestNotificationListenerPermission() {
        if (!isNotificationServiceEnabled()) {
            val intent = Intent(NOTIFICATION_LISTENER_SETTINGS)
            startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Request notification listener permission
        requestNotificationListenerPermission()
        // Request POST_NOTIFICATIONS permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
            }
        }
        // Prompt user to exclude from battery optimizations"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:" + packageName)
                startActivity(intent)
            }
        }
    }

    private fun sendTestNotification(title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            Log.d("MainActivity", "POST_NOTIFICATIONS granted: $granted")
        }
        Log.d("MainActivity", "Attempting to send test notification")
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "test_channel"
        val channelName = "Test Channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            Notification.Builder(this)
        }
        builder.setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
        val notificationId = Random().nextInt(100000) // Use a random ID
        notificationManager.notify(notificationId, builder.build())
        Log.d("MainActivity", "Notification sent with ID: $notificationId")
    }
}
