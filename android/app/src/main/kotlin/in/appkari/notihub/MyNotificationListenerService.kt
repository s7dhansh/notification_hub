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

class MyNotificationListenerService : NotificationListenerService() {
    companion object {
        var channel: MethodChannel? = null
        var instance: MyNotificationListenerService? = null
        fun removeNotificationByKey(key: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                instance?.cancelNotification(key)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
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
        Log.d("NotiHubService", "onNotificationPosted called for package: ${sbn.packageName}, id: ${sbn.id}, tag: ${sbn.tag}, key: ${sbn.key}")
        if (channel == null) {
            Log.d("NotiHubService", "MethodChannel is null, cannot send to Flutter")
        } else {
            Log.d("NotiHubService", "MethodChannel is set, sending to Flutter")
        }
        // Send notification data to Flutter
        channel?.invokeMethod("onNotificationPosted", mapOf(
            "packageName" to sbn.packageName,
            "id" to sbn.id,
            "tag" to sbn.tag,
            "key" to sbn.key,
            "extras" to sbn.notification.extras?.toString()
        ))
        // Remove the notification from the system tray
        // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        //     cancelNotification(sbn.key)
        // } else {
        //     cancelNotification(sbn.packageName, sbn.tag, sbn.id)
        // }
    }
} 