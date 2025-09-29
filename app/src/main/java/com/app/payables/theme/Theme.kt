package com.app.payables.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.google.accompanist.systemuicontroller.rememberSystemUiController

// Theme.kt
// Provides the app's Material 3 theme, including dynamic color support on Android 12+
// and system bar color management via Accompanist System UI Controller. Also supplies
// `LocalAppDimensions` so child composables can access centralized dimension tokens.

// Dashboard-specific theme tokens so dashboard-like pages can share consistent UI rules
data class DashboardTheme(
  val titleTextStyle: TextStyle,
  val sectionHeaderTextStyle: TextStyle,
  val titleToSectionSpacing: Dp,
  val sectionHorizontalPadding: Dp,
  val sectionTopPadding: Dp,
  val groupTopCornerRadius: Dp,
  val groupBottomCornerRadius: Dp,
  val groupInnerCornerRadius: Dp,
  val cardContainerColor: Color,
  val bottomNavContentMargin: Dp,
  // Menu tokens for consistent overflow/dropdown menus on dashboard-like pages
  val menuWidth: Dp,
  val menuOffsetX: Dp,
  val menuOffsetY: Dp,
  val menuItemHorizontalPadding: Dp,
  val menuItemVerticalPadding: Dp,
  val menuItemTextStyle: TextStyle,
)

val LocalDashboardTheme = compositionLocalOf {
  // Reasonable defaults; real values provided in AppTheme below
  DashboardTheme(
    titleTextStyle = AppTypography.displayMedium,
    sectionHeaderTextStyle = AppTypography.headlineSmall,
    titleToSectionSpacing = 64.dp,
    sectionHorizontalPadding = 16.dp,
    sectionTopPadding = 16.dp,
    groupTopCornerRadius = 24.dp,
    groupBottomCornerRadius = 24.dp,
    groupInnerCornerRadius = 5.dp,
    cardContainerColor = Color.Unspecified,
    bottomNavContentMargin = 16.dp,
    menuWidth = 150.dp,
    menuOffsetX = (-16).dp,
    menuOffsetY = 0.dp,
    menuItemHorizontalPadding = 16.dp,
    menuItemVerticalPadding = 8.dp,
    menuItemTextStyle = AppTypography.menuItemText,
  )
}

@Composable
private fun rememberDashboardThemeDefaults(): DashboardTheme {
  val dims = LocalAppDimensions.current
  val cardColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
  return remember(dims, cardColor) {
    DashboardTheme(
      titleTextStyle = AppTypography.displayMedium,
      sectionHeaderTextStyle = AppTypography.headlineSmall,
      titleToSectionSpacing = dims.titleDimensions.payablesTitleToOverviewSpacing,
      sectionHorizontalPadding = dims.spacing.md,
      sectionTopPadding = dims.spacing.md,
      groupTopCornerRadius = 24.dp,
      groupBottomCornerRadius = 24.dp,
      groupInnerCornerRadius = 5.dp,
      cardContainerColor = cardColor,
      bottomNavContentMargin = dims.spacing.navBarContentBottomMargin,
      menuWidth = dims.menuDimensions.width,
      menuOffsetX = dims.menuDimensions.offsetX,
      menuOffsetY = dims.menuDimensions.offsetY,
      menuItemHorizontalPadding = dims.menuDimensions.itemHorizontalPadding,
      menuItemVerticalPadding = dims.menuDimensions.itemVerticalPadding,
      menuItemTextStyle = AppTypography.menuItemText,
    )
  }
}

@Composable
fun AppTheme(
  darkTheme: Boolean = isSystemInDarkTheme(),
  useDynamicColor: Boolean = true,
  content: @Composable () -> Unit
) {
  val context = LocalContext.current
  val colors = when {
    useDynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
      if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
    else -> if (darkTheme) DarkColors else LightColors
  }

  // System UI Controller
  val systemUiController = rememberSystemUiController()
  SideEffect {
    systemUiController.setStatusBarColor(
        color = Color.Transparent,
        darkIcons = !darkTheme
    )
    systemUiController.setNavigationBarColor(
        color = Color.Transparent,
        darkIcons = !darkTheme
    )
  }

  CompositionLocalProvider(LocalAppDimensions provides AppDimensions()) {
    CompositionLocalProvider(LocalDashboardTheme provides rememberDashboardThemeDefaults()) {
      MaterialTheme(
        colorScheme = colors,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
      )
    }
  }
}
