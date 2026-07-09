package com.example.device_guardian_app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.device_guardian_app/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryTemperature" -> {
                    val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
                    if (temp != -1) {
                        // temp is in tenths of a degree Centigrade
                        result.success(temp / 10.0)
                    } else {
                        result.error("UNAVAILABLE", "Battery temperature not available.", null)
                    }
                }
                "getStorageUsage" -> {
                    try {
                        val stat = StatFs(Environment.getDataDirectory().path)
                        val bytesAvailable = stat.blockSizeLong * stat.availableBlocksLong
                        val bytesTotal = stat.blockSizeLong * stat.blockCountLong
                        val bytesUsed = bytesTotal - bytesAvailable
                        val usagePercentage = (bytesUsed.toDouble() / bytesTotal.toDouble()) * 100.0
                        result.success(usagePercentage)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                }
                "getRamUsage" -> {
                    try {
                        val actManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
                        val memInfo = android.app.ActivityManager.MemoryInfo()
                        actManager.getMemoryInfo(memInfo)
                        val totalMemory = memInfo.totalMem
                        val availableMemory = memInfo.availMem
                        val usedMemory = totalMemory - availableMemory
                        val usagePercentage = (usedMemory.toDouble() / totalMemory.toDouble()) * 100.0
                        result.success(usagePercentage)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
