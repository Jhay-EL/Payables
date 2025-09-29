package com.app.payables.theme

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith

/**
 * Centralized animated page transitions following Material 3 motion guidance.
 * These helpers can be reused across routes/screens to ensure consistent motion.
 */
object AppTransitions {

    /**
     * Material-style Shared Axis (X) horizontal transition.
     * - Forward: incoming slides from the right with fade-in; outgoing slides to the left with fade-out
     * - Back: reverse directions
     * Durations and easings aim to feel native to Android Material motion.
     */
    fun <S> materialSharedAxisHorizontal(
        isForward: (initial: S, target: S) -> Boolean,
        durationMillis: Int = 220,
        fadeDurationMillis: Int = 110,
        distanceFraction: Float = 0.30f,
        clip: Boolean = false,
    ): AnimatedContentTransitionScope<S>.() -> ContentTransform = {
        val forward = isForward(initialState, targetState)
        if (forward) {
            // Forward push: new enters from right, old exits to left
            (slideInHorizontally(
                animationSpec = tween(durationMillis, easing = LinearOutSlowInEasing)
            ) { (it * distanceFraction).toInt() } +
                fadeIn(animationSpec = tween(fadeDurationMillis))) togetherWith
                    (slideOutHorizontally(
                        animationSpec = tween(durationMillis, easing = FastOutLinearInEasing)  // Full duration for forward slide
                    ) { -(it * distanceFraction).toInt() } +
                        fadeOut(animationSpec = tween(fadeDurationMillis)))  // Full fade duration for forward
        } else {
            // Back pop: new enters from left, old exits to right
            (slideInHorizontally(
                animationSpec = tween(durationMillis, easing = LinearOutSlowInEasing)
            ) { -(it * distanceFraction).toInt() } +
                fadeIn(animationSpec = tween(fadeDurationMillis))) togetherWith
                    (slideOutHorizontally(
                        animationSpec = tween(durationMillis, easing = FastOutLinearInEasing)  // Full duration for back slide
                    ) { (it * distanceFraction).toInt() } +
                        fadeOut(animationSpec = tween(fadeDurationMillis)))  // Full fade duration for back
        }
            .using(SizeTransform(clip = clip))
    }
}
