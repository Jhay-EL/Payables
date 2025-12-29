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
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Event
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
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.text.font.FontWeight
import coil.compose.AsyncImage
import android.net.Uri
import com.app.payables.util.isColorBright

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomColorScreen(
    onBack: () -> Unit = {},
    onPick: (Color) -> Unit = {},
    brandColors: List<Color> = emptyList(),
    initialColor: Color = Color(0xFF3B82F6),
    previewTitle: String = "New Payable",
    previewSubtitle: String = "No description",
    previewAmount: String = "$ 0.00",
    previewBadge: String = "Due Today",
    previewIcon: Uri? = null
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Initialize HSV state from initialColor
    val initialHsv = remember(initialColor) {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(initialColor.toArgb(), hsv)
        hsv
    }
    
    var hue by remember { mutableFloatStateOf(initialHsv[0]) } // 0..360
    var sat by remember { mutableFloatStateOf(initialHsv[1]) }  // 0..1
    var value by remember { mutableFloatStateOf(initialHsv[2]) } // 0..1
    var hex by remember { mutableStateOf(TextFieldValue(colorToHexNoAlpha(initialColor))) }

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

            Spacer(Modifier.height(24.dp))

            Text(
                text = "Payable Card Preview",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.height(16.dp))

            // Preview HeaderCard
            HeaderCard(
                title = previewTitle,
                amountLabel = previewAmount,
                subtitle = previewSubtitle,
                badge = previewBadge,
                customIcon = previewIcon,
                backgroundColor = color
            )
            
            Spacer(Modifier.height(48.dp))

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

            Spacer(Modifier.height(32.dp))
            Text("Brightness", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Slider(value = value, onValueChange = {
                value = it
                onPick(Color.hsv(hue, sat, it))
            })

            Spacer(Modifier.height(48.dp))

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

            Spacer(Modifier.height(48.dp))

            // Brand Colors section (if available) - at bottom
            if (brandColors.isNotEmpty()) {
                Text(
                    text = "Brand Colors",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(Modifier.height(8.dp))
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(brandColors) { brandColor ->
                        ColorSwatch(
                            color = brandColor,
                            isSelected = color == brandColor,
                            onClick = {
                                val hsv = FloatArray(3)
                                android.graphics.Color.colorToHSV(brandColor.toArgb(), hsv)
                                hue = hsv[0]
                                sat = hsv[1]
                                value = hsv[2]
                                onPick(brandColor)
                            }
                        )
                    }
                }
                Spacer(Modifier.height(dims.spacing.section))
            }

            // Preset Colors section - at bottom
            Text(
                text = "Preset Colors",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.height(8.dp))
            val presetColors = listOf(
                Color(0xFF2196F3), // Blue
                Color(0xFFF44336), // Red
                Color(0xFF4CAF50), // Green
                Color(0xFFFFEB3B), // Yellow
                Color(0xFF9C27B0), // Purple
                Color(0xFFFF9800), // Orange
                Color(0xFF00BCD4), // Cyan
                Color(0xFFE91E63), // Pink
                Color(0xFFFFFFFF), // White
                Color(0xFF000000)  // Black
            )
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(presetColors) { presetColor ->
                    ColorSwatch(
                        color = presetColor,
                        isSelected = color == presetColor,
                        onClick = {
                            val hsv = FloatArray(3)
                            android.graphics.Color.colorToHSV(presetColor.toArgb(), hsv)
                            hue = hsv[0]
                            sat = hsv[1]
                            value = hsv[2]
                            onPick(presetColor)
                        }
                    )
                }
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

@Composable
private fun ColorSwatch(
    color: Color,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val borderColor = if (isSelected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
    }
    
    Surface(
        modifier = Modifier
            .size(40.dp)
            .clickable(onClick = onClick),
        shape = CircleShape,
        color = color,
        border = BorderStroke(width = if (isSelected) 3.dp else 1.dp, color = borderColor)
    ) {
        // Empty content - just the colored surface
    }
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

@Preview(showBackground = true, heightDp = 1150)
@Composable
private fun CustomColorPreview() {
    AppTheme {
        CustomColorScreen()
    }
}

@Composable
private fun HeaderCard(
    title: String,
    amountLabel: String,
    subtitle: String,
    badge: String,
    customIcon: Uri? = null,
    backgroundColor: Color = MaterialTheme.colorScheme.surfaceColorAtElevation(6.dp)
) {
    // Calculate if the background is bright or dark to determine text color
    val isBackgroundBright = isColorBright(backgroundColor)
    val textColor = if (isBackgroundBright) Color.Black else Color.White
    val secondaryTextColor = if (isBackgroundBright) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f)
    val iconTint = if (isBackgroundBright) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f)
    val dims = LocalAppDimensions.current
    Card(
        modifier = Modifier
            .fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = backgroundColor
        )
    ) {
        Column(modifier = Modifier.padding(dims.spacing.card)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Icon aligned to center of content
                if (customIcon != null) {
                    var imageModel by remember(customIcon) { mutableStateOf<Any?>(customIcon) }
                    // Custom icon - maintains natural aspect ratio, no square constraint
                    AsyncImage(
                        model = imageModel,
                        contentDescription = "Brand Logo",
                        contentScale = androidx.compose.ui.layout.ContentScale.Fit,
                        onError = {
                            val currentModel = imageModel.toString()
                            if (currentModel.contains("/symbol")) {
                                imageModel = currentModel.replace("/symbol", "/icon")
                            } else if (currentModel.contains("/icon")) {
                                imageModel = currentModel.replace("/icon", "/logo")
                            }
                        },
                        modifier = Modifier
                            .height(60.dp)
                            .widthIn(min = 40.dp, max = 120.dp)
                            .wrapContentWidth()
                    )
                } else {
                    // Default icon with background container
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .background(MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f), RoundedCornerShape(16.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.Dashboard, contentDescription = null)
                    }
                }

                // Main content column with title, subtitle, and badge
                Column(modifier = Modifier.weight(1f).padding(start = 16.dp)) {
                    // Title and subtitle in a column
                    Text(title, style = MaterialTheme.typography.titleLarge,fontWeight = FontWeight.Bold, color = textColor)

                    Spacer(Modifier.height(4.dp))

                    Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = secondaryTextColor)

                    Spacer(Modifier.height(12.dp))

                    // Badge row
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Event, contentDescription = null, tint = iconTint)
                        Spacer(Modifier.width(8.dp))
                        Text(badge, style = MaterialTheme.typography.bodyMedium, color = secondaryTextColor)
                    }
                }

                // Amount label on the right
                Box(
                    modifier = Modifier
                        .background(textColor.copy(alpha = 0.16f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 14.dp)
                ) { Text(amountLabel, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = textColor) }
            }
        }
    }
}


