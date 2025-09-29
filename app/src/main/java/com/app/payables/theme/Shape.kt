package com.app.payables.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

// Shape.kt
// Defines rounded corner radii and builds the Material 3 `Shapes` set used by the app theme.
// Use these to keep corner treatments consistent across components.

val cornerExtraSmall = 4.dp
val cornerSmall = 8.dp
val cornerMedium = 12.dp
val cornerLarge = 16.dp
val cornerExtraLarge = 28.dp

// AppShapes object using the M3 scale
val AppShapes = Shapes(
  extraSmall = RoundedCornerShape(cornerExtraSmall),
  small = RoundedCornerShape(cornerSmall),
  medium = RoundedCornerShape(cornerMedium),
  large = RoundedCornerShape(cornerLarge),
  extraLarge = RoundedCornerShape(cornerExtraLarge)
)
