@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.unit.dp
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import com.app.payables.theme.*
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.min

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomColorScreen(
    onBack: () -> Unit = {},
    onPick: (Color) -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    var hue by remember { mutableFloatStateOf(210f) } // 0..360
    var sat by remember { mutableFloatStateOf(0.7f) }  // 0..1
    var value by remember { mutableFloatStateOf(0.9f) } // 0..1
    var hex by remember { mutableStateOf(TextFieldValue("#3B82F6")) }

    val color = remember(hue, sat, value) { Color.hsv(hue, sat, value) }

    // Keep hex field in sync when HSV changes via wheel/slider
    LaunchedEffect(hue, sat, value) {
        val text = colorToHexNoAlpha(Color.hsv(hue, sat, value))
        if (hex.text != text) {
            hex = TextFieldValue(text, selection = TextRange(text.length))
        }
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text("Custom Color", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                },
                actions = {
                    TextButton(onClick = onBack) {
                        Text("Save")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarColor,
                    scrolledContainerColor = topBarColor
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = dims.spacing.md)
                .verticalScroll(rememberScrollState())
        ) {
            // Y reporter
            Box(Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

            // Title
            Column(Modifier.fadeUpTransform(fade)) {
                Text(
                    text = "Custom Color",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            // Color wheel (Hue/Saturation) + brightness
            HSVWheel(
                modifier = Modifier
                    .fillMaxWidth(0.82f)
                    .aspectRatio(1f)
                    .align(Alignment.CenterHorizontally),
                hue = hue,
                saturation = sat,
                onChange = { h, s ->
                    hue = h
                    sat = s
                    onPick(Color.hsv(h, s, value))
                }
            )

            Spacer(Modifier.height(dims.spacing.md))
            Text("Brightness", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Slider(value = value, onValueChange = {
                value = it
                onPick(Color.hsv(hue, sat, it))
            })

            Spacer(Modifier.height(dims.spacing.section))

            // Hex input with live color swatch
            Text("Hex code", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(color, RoundedCornerShape(8.dp))
                        .border(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.5f), RoundedCornerShape(8.dp))
                )
                OutlinedTextField(
                    value = hex,
                    onValueChange = { new ->
                        hex = new
                        parseHex(new.text)?.let { c ->
                            val hsv = FloatArray(3)
                            android.graphics.Color.colorToHSV(c.toArgb(), hsv)
                            hue = hsv[0]
                            sat = hsv[1]
                            value = hsv[2]
                            onPick(c)
                        }
                    },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("#RRGGBB or #AARRGGBB") }
                )
            }

            Spacer(Modifier.height(dims.spacing.section))

            // Ensure content is spaced from the system navigation bar
            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }
}

@Composable
private fun HSVWheel(
    modifier: Modifier,
    hue: Float,
    saturation: Float,
    onChange: (Float, Float) -> Unit
) {
    Canvas(
        modifier = modifier
            .pointerInput(Unit) {
                detectTapGestures { p ->
                    val center = Offset(size.width / 2f, size.height / 2f)
                    val radius = min(size.width, size.height) / 2f
                    val (h, s) = pointToHS(p, center, radius)
                    onChange(h, s)
                }
            }
            .pointerInput(Unit) {
                detectDragGestures { change, _ ->
                    val center = Offset(size.width / 2f, size.height / 2f)
                    val radius = min(size.width, size.height) / 2f
                    val (h, s) = pointToHS(change.position, center, radius)
                    onChange(h, s)
                }
            }
    ) {
        val radius = min(size.width, size.height) / 2f
        val center = Offset(size.width / 2f, size.height / 2f)

        // Hue sweep
        drawCircle(
            brush = Brush.sweepGradient(
                0f to Color.hsv(0f, 1f, 1f),
                1f / 6f to Color.hsv(60f, 1f, 1f),
                2f / 6f to Color.hsv(120f, 1f, 1f),
                3f / 6f to Color.hsv(180f, 1f, 1f),
                4f / 6f to Color.hsv(240f, 1f, 1f),
                5f / 6f to Color.hsv(300f, 1f, 1f),
                1f to Color.hsv(360f, 1f, 1f)
            ),
            radius = radius,
            center = center
        )
        // Desaturate towards center (white overlay)
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(Color.White, Color.Transparent),
                center = center,
                radius = radius
            ),
            radius = radius,
            center = center,
            blendMode = BlendMode.SrcOver
        )
        // Thumb
        val thumb = hsToPoint(hue, saturation, center, radius)
        drawCircle(color = Color.White, radius = 25f, center = thumb)
        drawCircle(color = Color.Black, radius = 25f, center = thumb, style = Stroke(width = 2f))
    }
}

private fun pointToHS(p: Offset, center: Offset, radius: Float): Pair<Float, Float> {
    val dx = p.x - center.x
    val dy = p.y - center.y
    val dist = min(hypot(dx, dy), radius)
    val sat = (dist / radius).coerceIn(0f, 1f)
    var angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
    if (angle < 0) angle += 360f
    return angle to sat
}

private fun hsToPoint(h: Float, s: Float, center: Offset, radius: Float): Offset {
    val rad = Math.toRadians(h.toDouble()).toFloat()
    val r = s * radius
    return Offset(
        x = center.x + r * kotlin.math.cos(rad),
        y = center.y + r * kotlin.math.sin(rad)
    )
}

private fun colorToHexNoAlpha(color: Color): String {
    val r = (color.red * 255f).toInt().coerceIn(0, 255)
    val g = (color.green * 255f).toInt().coerceIn(0, 255)
    val b = (color.blue * 255f).toInt().coerceIn(0, 255)
    return "#%02X%02X%02X".format(r, g, b)
}

private fun parseHex(text: String): Color? {
    val t = text.trim().removePrefix("#")
    return try {
        val v = when (t.length) {
            6 -> 0xFF000000 or t.toLong(16)
            8 -> t.toLong(16)
            else -> return null
        }
        Color(v.toInt())
    } catch (_: Throwable) {
        null
    }
}

@Preview(showBackground = true)
@Composable
private fun CustomColorPreview() {
    AppTheme {
        CustomColorScreen()
    }
}


