package com.app.payables.util

import androidx.compose.ui.graphics.Color
import kotlin.math.pow

// Helper function to determine if a color is bright or dark
fun isColorBright(color: Color): Boolean {
    // Calculate relative luminance using the standard formula
    // Convert to linear RGB first
    fun linearize(component: Float): Float {
        return if (component <= 0.04045f) {
            component / 12.92f
        } else {
            (((component + 0.055f) / 1.055f).toDouble().pow(2.4)).toFloat()
        }
    }

    val r = linearize(color.red)
    val g = linearize(color.green)
    val b = linearize(color.blue)

    // Calculate luminance
    val luminance = 0.2126f * r + 0.7152f * g + 0.0722f * b

    // Return true if luminance is greater than 0.5 (bright), false otherwise (dark)
    return luminance > 0.5f
}
