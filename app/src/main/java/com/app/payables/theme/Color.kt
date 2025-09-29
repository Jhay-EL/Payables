// Color.kt
// Defines brand colors and Material 3 color schemes used throughout the app.
// LightColors and DarkColors are the fallback (non-dynamic) schemes when dynamic colors
// are not available or disabled.
package com.app.payables.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

/** Primary brand color used across key components (buttons, highlights). */
val brandPrimary = Color(0xFF3B82F6)
/** Secondary brand color used to complement the primary brand color. */
val brandSecondary = Color(0xFF10B981)

/** Default light color scheme for the app (when dynamic color is off or unsupported). */
val LightColors = lightColorScheme(
  primary = brandPrimary,
  secondary = brandSecondary,
  surface = Color(0xFFFCFCFC),
  onSurface = Color(0xFF1B1B1B),
)

/** Default dark color scheme for the app (when dynamic color is off or unsupported). */
val DarkColors = darkColorScheme(
  primary = brandPrimary,
  secondary = brandSecondary
)
