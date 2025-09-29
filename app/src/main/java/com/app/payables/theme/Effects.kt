package com.app.payables.theme

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun Modifier.pressableCard(
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() }
): Modifier {
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(targetValue = if (isPressed) 0.98f else 1f, label = "cardScale")

    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
}

/**
 * Report the current window Y position of the composablDropdownMenuBoxCustomSegmentedButton on every global positioning pass.
 * Useful for driving scroll-position-aware animations.
 */
fun Modifier.windowYReporter(onPositionChanged: (Int) -> Unit): Modifier =
    this.onGloballyPositioned { coordinates ->
        onPositionChanged(coordinates.positionInWindow().y.toInt())
    }

/**
 * Compute a 0..1 fade progress for a content title that fades as it approaches the top app bar.
 * - progress = 0f at the initial Y
 * - progress = 1f at the app bar threshold (e.g., small top bar height)
 */
@Composable
fun rememberFadeToTopBarProgress(
    initialWindowY: Int?,
    currentWindowY: Int,
    appBarThresholdDp: Dp = 72.dp
): Float {
    val density = LocalDensity.current
    if (initialWindowY == null) return 0f
    val fadeStartPx = initialWindowY.toFloat()
    val appBarThresholdPx = with(density) { appBarThresholdDp.toPx() }
    val fadeRangePx = (fadeStartPx - appBarThresholdPx).coerceAtLeast(1f)
    val clamped = ((fadeStartPx - currentWindowY.toFloat()) / fadeRangePx)
    return clamped.coerceIn(0f, 1f)
}

/**
 * Map the content fade progress to the top app bar title alpha so that the bar title appears
 * only after a given fraction of the content title has faded.
 */
fun computeTopBarAlphaFromContentFade(
    contentFadeProgress: Float,
    appearAfterFraction: Float = 0.9f
): Float {
    val start = appearAfterFraction.coerceIn(0f, 0.9999f)
    val t = (contentFadeProgress - start) / (1f - start)
    return t.coerceIn(0f, 1f)
}

/**
 * Apply a subtle "fade up" transform: small upward translation and slight scale from 0.98 -> 1.0
 * driven by a 0..1 progress value. This does not change alpha; pair with text color alpha if needed.
 */
@Composable
fun Modifier.fadeUpTransform(
    progress: Float,
    maxTranslationY: Dp = 12.dp,
    maxScaleReduction: Float = 0.02f
): Modifier {
    val density = LocalDensity.current
    val translationYPx = with(density) { maxTranslationY.toPx() } * progress.coerceIn(0f, 1f)
    val scale = 1f - (maxScaleReduction * progress.coerceIn(0f, 1f))
    return this.graphicsLayer(
        translationY = translationYPx,
        scaleX = scale,
        scaleY = scale
    )
}








/**
 * NOTE: This function is no longer used since drag functionality has been deactivated.
 * The categories list is now static and does not support reordering.
 *
 * Original: Reorderable list item with drag handle gesture detection.
 * Handles drag gestures only when the drag handle is touched.
 */