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
import android.app.AppOpsManager
import android.provider.Settings
import android.os.Process

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
                "getBatteryMetrics" -> {
                    val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val health = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
                    val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
                    
                    val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    var stateOfHealth = -1
                    if (android.os.Build.VERSION.SDK_INT >= 34) {
                        try {
                            stateOfHealth = batteryManager.getIntProperty(10) // BATTERY_PROPERTY_STATE_OF_HEALTH
                        } catch (e: Exception) {}
                    }

                    var cycleCount = -1
                    if (android.os.Build.VERSION.SDK_INT >= 34) {
                        cycleCount = intent?.getIntExtra("android.os.extra.CYCLE_COUNT", -1) ?: -1
                    }

                    var healthPercent = 100.0
                    
                    if (stateOfHealth > 0) {
                        healthPercent = stateOfHealth.toDouble()
                    } else if (cycleCount > 0) {
                        // Assume 1000 cycles drops health to 80% (modern smartphone standard)
                        healthPercent = 100.0 - (20.0 * (cycleCount / 1000.0))
                    } else {
                        when (health) {
                            BatteryManager.BATTERY_HEALTH_GOOD -> healthPercent = 95.0
                            BatteryManager.BATTERY_HEALTH_OVERHEAT -> healthPercent = 60.0
                            BatteryManager.BATTERY_HEALTH_DEAD -> healthPercent = 0.0
                            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> healthPercent = 70.0
                            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> healthPercent = 50.0
                            BatteryManager.BATTERY_HEALTH_COLD -> healthPercent = 85.0
                            else -> healthPercent = 100.0
                        }
                    }
                    
                    if (temp > 400 && stateOfHealth <= 0) {
                        healthPercent -= 5.0
                    }
                    
                    if (healthPercent < 0.0) healthPercent = 0.0
                    if (healthPercent > 100.0) healthPercent = 100.0
                    
                    // RUL calculation: 100% -> 36m, 80% -> 0m (since 80% is replacement threshold)
                    var estimatedMonths = 36.0 * ((healthPercent - 80.0) / 20.0)
                    if (estimatedMonths < 0.0) estimatedMonths = 0.0
                    if (estimatedMonths > 36.0) estimatedMonths = 36.0
                    
                    val resultData = mapOf(
                        "healthPercent" to healthPercent,
                        "remainingMonths" to estimatedMonths
                    )
                    result.success(resultData)
                }
                "checkUsageStatsPermission" -> {
                    try {
                        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = appOps.noteOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            context.packageName
                        )
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestUsageStatsPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
