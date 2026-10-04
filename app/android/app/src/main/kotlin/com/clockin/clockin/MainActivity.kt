package com.clockin.clockin

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.clockin.clockin/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSeekerDevice" -> {
                    val model = Build.MODEL ?: ""
                    val brand = Build.BRAND ?: ""
                    val manufacturer = Build.MANUFACTURER ?: ""

                    val isModelSeeker = model.contains("Seeker", ignoreCase = true)
                    val isBrandSolana = brand.contains("Solana", ignoreCase = true) || manufacturer.contains("Solana", ignoreCase = true)

                    var hasSeedVault = false
                    try {
                        hasSeedVault = packageManager.hasSystemFeature("com.solanamobile.seedvault")
                    } catch (e: Exception) {
                        // ignore
                    }

                    val isSeeker = isModelSeeker || isBrandSolana || hasSeedVault
                    result.success(isSeeker)
                }
                "getDeviceInfo" -> {
                    val model = Build.MODEL ?: ""
                    val brand = Build.BRAND ?: ""
                    val manufacturer = Build.MANUFACTURER ?: ""
                    var hasSeedVault = false
                    try {
                        hasSeedVault = packageManager.hasSystemFeature("com.solanamobile.seedvault")
                    } catch (e: Exception) {
                        // ignore
                    }
                    val isSeeker = model.contains("Seeker", ignoreCase = true) ||
                                   brand.contains("Solana", ignoreCase = true) ||
                                   manufacturer.contains("Solana", ignoreCase = true) ||
                                   hasSeedVault
                    val info = mapOf(
                        "model" to model,
                        "brand" to brand,
                        "manufacturer" to manufacturer,
                        "hasSeedVault" to hasSeedVault,
                        "isSeeker" to isSeeker
                    )
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }
    }
}
