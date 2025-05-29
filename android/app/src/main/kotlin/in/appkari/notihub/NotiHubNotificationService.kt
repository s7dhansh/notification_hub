package `in`.appkari.notihub

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import android.util.Log
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas

class NotiHubNotificationService : NotificationListenerService() {
    companion object {
        var channel: MethodChannel? = null
        var instance: NotiHubNotificationService? = null
        var shouldRemoveSystemTrayNotification: Boolean = false // Default to false (keep)
        var isListening: Boolean = false // Controls forwarding to Flutter
        val programmaticallyRemovedKeys = mutableSetOf<String>()

        fun removeNotificationByKey(key: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                programmaticallyRemovedKeys.add(key)
                instance?.cancelNotification(key)
            }
        }

        // Only clears notifications from the system tray, not the app's notification list
        fun clearAllNotifications() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Add all keys to programmaticallyRemovedKeys before removal
                instance?.activeNotifications?.forEach { programmaticallyRemovedKeys.add(it.key) }
                instance?.cancelAllNotifications()
            } else {
                instance?.activeNotifications?.forEach { programmaticallyRemovedKeys.add(it.key) }
                instance?.activeNotifications?.forEach { instance?.cancelNotification(it.key) }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("NotiHubService", "Service created")
        instance = this
    }

    override fun onDestroy() {
        Log.d("NotiHubService", "Service destroyed")
        super.onDestroy()
        if (instance == this) {
            instance = null
        }
        // Send a notification to inform the user
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "notihub_service_channel"
        val channelName = "NotiHub Service Channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            Notification.Builder(this)
        }
        builder.setContentTitle("NotiHub Service Stopped")
            .setContentText("Notification listener was killed by the system.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // Use a generic system icon for now
            .setAutoCancel(true)
        notificationManager.notify(1001, builder.build())
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.d("NotiHubService", "=== NOTIFICATION RECEIVED ===")
        Log.d("NotiHubService", "Package: ${sbn.packageName}")
        Log.d("NotiHubService", "ID: ${sbn.id}, Tag: ${sbn.tag}, Key: ${sbn.key}")
        Log.d("NotiHubService", "Time: ${System.currentTimeMillis()}")
        if (channel == null) {
            Log.d("NotiHubService", "MethodChannel is null, cannot send to Flutter")
        } else {
            Log.d("NotiHubService", "MethodChannel is set, sending to Flutter")
        }
        if (!isListening) {
            Log.d("NotiHubService", "isListening is false, not forwarding notification to Flutter")
            return
        }
        // Get app name
        val packageManager = applicationContext.packageManager
        val appName = try {
            val applicationInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            sbn.packageName
        }
        
        // Get notification extras
        val extras = sbn.notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        
        // Get icon as bitmap and convert to base64
        var iconData: String? = null
        try {
            val icon = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val drawable = sbn.notification.smallIcon?.loadDrawable(applicationContext)
                if (drawable != null) {
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth,
                        drawable.intrinsicHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                } else {
                    null
                }
            } else {
                try {
                    val appInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
                    val drawable = appInfo.loadIcon(packageManager)
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth,
                        drawable.intrinsicHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                } catch (e: Exception) {
                    Log.e("NotiHubService", "Error getting app icon: ${e.message}")
                    null
                }
            }
            
            if (icon != null) {
                val stream = java.io.ByteArrayOutputStream()
                icon.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray = stream.toByteArray()
                iconData = android.util.Base64.encodeToString(byteArray, android.util.Base64.NO_WRAP)
            }
        } catch (e: Exception) {
            Log.e("NotiHubService", "Error getting app icon: ${e.message}")
        }
        
        // Send notification data to Flutter
        val notificationData = mutableMapOf<String, Any?>(
            "packageName" to sbn.packageName,
            "appName" to appName,
            "title" to title,
            "body" to text,
            "id" to sbn.id,
            "tag" to sbn.tag,
            "key" to sbn.key,
            "iconData" to iconData
        )
        
        // Add extras as a string representation if available
        extras?.keySet()?.forEach { key ->
            extras.get(key)?.let { value ->
                notificationData["extra_$key"] = value.toString()
            }
        }
        
        channel?.invokeMethod("onNotificationReceived", notificationData)
        
        Log.d("NotiHubService", "shouldRemoveSystemTrayNotification: $shouldRemoveSystemTrayNotification")
        // Remove the notification from the system tray if needed and the setting is enabled
        if (shouldRemoveSystemTrayNotification && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val key = sbn.key
            programmaticallyRemovedKeys.add(key)
            cancelNotification(key)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Note: onNotificationRemoved is called for both user and programmatic removals.
        // Dart side now ignores programmatic removals using a key tracking set.
        Log.d("NotiHubService", "Notification removed: \\${sbn.key}")
        val packageManager = applicationContext.packageManager
        val appName = try {
            val applicationInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            sbn.packageName
        }
        val extras = sbn.notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        var iconData: String? = null
        try {
            val icon = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val drawable = sbn.notification.smallIcon?.loadDrawable(applicationContext)
                if (drawable != null) {
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth,
                        drawable.intrinsicHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                } else {
                    null
                }
            } else {
                try {
                    val appInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
                    val drawable = appInfo.loadIcon(packageManager)
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth,
                        drawable.intrinsicHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                } catch (e: Exception) {
                    Log.e("NotiHubService", "Error getting app icon: ${e.message}")
                    null
                }
            }
            if (icon != null) {
                val stream = java.io.ByteArrayOutputStream()
                icon.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray = stream.toByteArray()
                iconData = android.util.Base64.encodeToString(byteArray, android.util.Base64.NO_WRAP)
            }
        } catch (e: Exception) {
            Log.e("NotiHubService", "Error getting app icon: ${e.message}")
        }
        val notificationData = mutableMapOf<String, Any?>(
            "packageName" to sbn.packageName,
            "appName" to appName,
            "title" to title,
            "body" to text,
            "id" to sbn.id,
            "tag" to sbn.tag,
            "key" to sbn.key,
            "iconData" to iconData
        )
        extras?.keySet()?.forEach { key ->
            extras.get(key)?.let { value ->
                notificationData["extra_$key"] = value.toString()
            }
        }
        val key = sbn.key
        if (programmaticallyRemovedKeys.remove(key)) {
            notificationData["programmatic"] = true
        }
        channel?.invokeMethod("onNotificationRemoved", notificationData)
    }
} 