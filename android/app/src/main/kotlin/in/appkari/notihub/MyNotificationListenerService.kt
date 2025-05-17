package `in`.appkari.notihub

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MyNotificationListenerService : NotificationListenerService() {
    companion object {
        var channel: MethodChannel? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Send notification data to Flutter
        channel?.invokeMethod("onNotificationPosted", mapOf(
            "packageName" to sbn.packageName,
            "id" to sbn.id,
            "tag" to sbn.tag,
            "key" to sbn.key,
            "extras" to sbn.notification.extras?.toString()
        ))
        // Remove the notification from the system tray
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cancelNotification(sbn.key)
        } else {
            cancelNotification(sbn.packageName, sbn.tag, sbn.id)
        }
    }
} 