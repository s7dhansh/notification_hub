package `in`.appkari.notihub

import android.service.notification.NotificationListenerService
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

class MainActivity : FlutterActivity() {
    private val CHANNEL = "notification_capture"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        MyNotificationListenerService.channel = channel

        channel.setMethodCallHandler { call, result ->
            if (call.method == "removeNotification") {
                val key = call.argument<String>("key")
                if (key != null) {
                    MyNotificationListenerService.removeNotificationByKey(key)
                    result.success(null)
                } else {
                    result.error("INVALID_KEY", "Key is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Prompt user to exclude from battery optimizations
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
}
