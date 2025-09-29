package com.app.payables.theme

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// Dimensions.kt
// Centralized sizing system for spacing, radii, icons, cards, and reusable title metrics.
// Use these to maintain visual consistency and to simplify global tuning of the UI scale.

data class Spacing(
    val default: Dp = 0.dp,
    val xs: Dp = 4.dp,
    val sm: Dp = 8.dp,
    val md: Dp = 16.dp,
    val lg: Dp = 32.dp,
    val xl: Dp = 64.dp,
    val card: Dp = 20.dp,
    val cardToHeader: Dp = 20.dp,
    val section: Dp = 24.dp,
    // Extra margin applied in addition to navigation bar inset, so content sits
    // close to the system bar but remains comfortably spaced
    val navBarContentBottomMargin: Dp = 4.dp,
)

data class Radii(
    val sm: Dp = 4.dp,
    val md: Dp = 8.dp,
    val lg: Dp = 16.dp
)

data class IconSizes(
    val sm: Dp = 16.dp,
    val md: Dp = 24.dp,
    val lg: Dp = 32.dp
)

data class CardDimensions(
    val elevation: Dp = 2.dp
)

// Title-related standard measurements for re-use across screens
data class TitleDimensions(
    // Vertical space from the container's top to the title's top edge
    val payablesTitleTopPadding: Dp = 16.dp, // matches spacing.md
    // Horizontal padding commonly applied to the title container
    val payablesTitleHorizontalPadding: Dp = 16.dp, // matches spacing.md
    // Space between the title (e.g., "Payables") and the section below (e.g., Overview)
    val payablesTitleToOverviewSpacing: Dp = 64.dp // matches spacing.xl
)

// Standard measurements for app menus (e.g., overflow/dropdown menus)
data class MenuDimensions(
    // Preferred width for the menu popup
    val width: Dp = 150.dp,
    // Offset from the anchor; negative X shifts the menu left
    val offsetX: Dp = (-16).dp,
    val offsetY: Dp = 0.dp,
    // Padding inside each menu item
    val itemHorizontalPadding: Dp = 16.dp,
    val itemVerticalPadding: Dp = 8.dp,
)

data class AppDimensions(
    val spacing: Spacing = Spacing(),
    val radii: Radii = Radii(),
    val iconSizes: IconSizes = IconSizes(),
    val cardDimensions: CardDimensions = CardDimensions(),
    val titleDimensions: TitleDimensions = TitleDimensions(),
    val menuDimensions: MenuDimensions = MenuDimensions(),
)

// CompositionLocal to provide AppDimensions values to Composables tree-wide.
val LocalAppDimensions = compositionLocalOf { AppDimensions() }