package com.example.credit

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ussd_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUSSD") {
                val ussdCode = call.argument<String>("ussdCode")
                if (ussdCode != null) {
                    val success = launchUSSD(ussdCode)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "USSD code is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchUSSD(ussdCode: String): Boolean {
        return try {
            // Méthode 1: Intent ACTION_CALL direct (nécessite CALL_PHONE permission)
            val callIntent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$ussdCode")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(callIntent)
            true
        } catch (e: Exception) {
            try {
                // Méthode 2: Intent ACTION_DIAL avec le code pré-rempli
                val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                    data = Uri.parse("tel:$ussdCode")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(dialIntent)
                true
            } catch (e2: Exception) {
                try {
                    // Méthode 3: Intent avec ACTION_VIEW
                    val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                        data = Uri.parse("tel:$ussdCode")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(viewIntent)
                    true
                } catch (e3: Exception) {
                    false
                }
            }
        }
    }
}
