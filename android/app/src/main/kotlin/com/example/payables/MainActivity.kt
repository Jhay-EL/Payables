package com.example.payables

import android.os.Build
import android.view.Display
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val display: Display? = display
            val modes: Array<Display.Mode> = display?.supportedModes ?: emptyArray()
            val bestMode: Display.Mode? = modes.maxByOrNull { it.refreshRate }
            if (bestMode != null) {
                window.attributes = window.attributes.apply {
                    preferredDisplayModeId = bestMode.modeId
                }
            }
        }
    }
}
