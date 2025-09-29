package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.foundation.interaction.MutableInteractionSource
import com.app.payables.theme.*
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.tween
import androidx.compose.ui.text.style.TextAlign
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import android.Manifest
import android.os.Build
import android.content.pm.PackageManager
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import android.net.Uri
import androidx.compose.ui.draw.clip
import androidx.compose.ui.viewinterop.AndroidView
import android.widget.ImageView
import androidx.core.net.toUri
import androidx.compose.ui.draw.blur
import androidx.compose.animation.core.animateFloatAsState

private enum class WidgetSize { FourByTwo, TwoByTwo, TwoByOne }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WidgetScreen(
    onBack: () -> Unit = {},
    onOpenCustomColor: () -> Unit = {},
    onOpenCustomTextColor: () -> Unit = {},
    backgroundColor: Color? = null,
    onBackgroundColorChange: ((Color) -> Unit)? = null,
    textColor: Color? = null,
    onTextColorChange: ((Color) -> Unit)? = null
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Local UI-only state
    val initialBackgroundColor = MaterialTheme.colorScheme.primaryContainer
    val initialTextColor = MaterialTheme.colorScheme.onSurface
    var backgroundColorLocal by remember { mutableStateOf(initialBackgroundColor) }
    var transparency by remember { mutableFloatStateOf(0.15f) }
    var textColorLocal by remember { mutableStateOf(initialTextColor) }
    var showTomorrow by remember { mutableStateOf(true) }
    var showUpcoming by remember { mutableStateOf(true) }
    var showPayablesCount by remember { mutableStateOf(true) }
    var customBackground by rememberSaveable { mutableStateOf<String?>(null) }
    var backgroundBlur by rememberSaveable { mutableFloatStateOf(0f) } // 0f..25f in dp

    // Widget size selector (affects preview aspect ratio and width)
    var widgetSize by remember { mutableStateOf(WidgetSize.FourByTwo) }
    val screenWidth = LocalConfiguration.current.screenWidthDp.dp
    val maxContentWidth = screenWidth - (dims.spacing.md * 2)
    // Use a shared height for 4x2 and 2x2 so they appear with equal height
    val sharedHeight = maxContentWidth / 2f

    // Controlled vs uncontrolled values
    val currentBackgroundColor = backgroundColor ?: backgroundColorLocal
    val currentTextColor = textColor ?: textColorLocal
    val setBackgroundColor: (Color) -> Unit = { c ->
        if (onBackgroundColorChange != null) onBackgroundColorChange(c) else backgroundColorLocal = c
    }
    val setTextColor: (Color) -> Unit = { c ->
        if (onTextColorChange != null) onTextColorChange(c) else textColorLocal = c
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(text = "Widget Settings", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarContainerColor,
                    scrolledContainerColor = topBarContainerColor
                )
            )
        }
    ) { paddingValues ->
        val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
        val contentPadding = PaddingValues(
            start = dims.spacing.md,
            end = dims.spacing.md,
            top = 0.dp,
            bottom = 0.dp
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(contentPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Position reporter
            Box(Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

            // Title
            Column(Modifier.fadeUpTransform(progress = fadeProgress)) {
                Text(
                    text = "Widget Settings",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                AnimatedContent(
                    targetState = widgetSize,
                    transitionSpec = {
                        (
                            (
                                scaleIn(initialScale = 0.92f, animationSpec = tween(durationMillis = 260)) +
                                    fadeIn(animationSpec = tween(durationMillis = 160))
                            ) togetherWith (
                                scaleOut(targetScale = 0.98f, animationSpec = tween(durationMillis = 260)) +
                                    fadeOut(animationSpec = tween(durationMillis = 160))
                            )
                        ).using(SizeTransform(clip = false))
                    }
                ) { size ->
                    val aspect = when (size) {
                        WidgetSize.FourByTwo -> 2f
                        WidgetSize.TwoByTwo -> 1f
                        WidgetSize.TwoByOne -> 2f
                    }
                    val width = when (size) {
                        WidgetSize.FourByTwo -> sharedHeight * 2f
                        WidgetSize.TwoByTwo -> sharedHeight * 1f
                        WidgetSize.TwoByOne -> maxContentWidth * 0.6f
                    }
                    WidgetLivePreview(
                        modifier = Modifier
                            .width(width)
                            .animateContentSize(),
                        aspectRatio = aspect,
                        widgetSize = size,
                        textColor = currentTextColor,
                        cardColor = currentBackgroundColor.copy(alpha = 1f - transparency),
                        backgroundImageUri = customBackground,
                        backgroundBlur = backgroundBlur,
                        pillColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.18f),
                        showTomorrow = showTomorrow,
                        showUpcoming = showUpcoming,
                        showPayablesCount = showPayablesCount
                    )
                }
            }

            Spacer(Modifier.height(dims.spacing.md))

            // Widget size segmented buttons
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = widgetSize == WidgetSize.FourByTwo,
                    onClick = { widgetSize = WidgetSize.FourByTwo },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 3)
                ) { Text("4×2") }
                SegmentedButton(
                    selected = widgetSize == WidgetSize.TwoByTwo,
                    onClick = { widgetSize = WidgetSize.TwoByTwo },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 3)
                ) { Text("2×2") }
                SegmentedButton(
                    selected = widgetSize == WidgetSize.TwoByOne,
                    onClick = { widgetSize = WidgetSize.TwoByOne },
                    shape = SegmentedButtonDefaults.itemShape(index = 2, count = 3)
                ) { Text("2×1") }
            }

            Spacer(Modifier.height(dims.spacing.section))

            // Customization
            SectionHeader(text = "Customization")
            Column {
                CustomizationCard(
                    title = "Custom background image",
                    isFirst = true,
                    isLast = false
                ) {
                    val context = LocalContext.current
                    val permission = if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_IMAGES else Manifest.permission.READ_EXTERNAL_STORAGE
                    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
                        customBackground = uri?.toString()
                    }
                    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
                        if (granted) imagePicker.launch("image/*")
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(onClick = {
                            val hasPermission = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
                            if (hasPermission) imagePicker.launch("image/*") else permissionLauncher.launch(permission)
                        }) { Text(if (customBackground != null) "Change image" else "Choose image") }
                        if (customBackground != null) {
                            var pop by remember { mutableStateOf(false) }
                            val scale by animateFloatAsState(targetValue = if (pop) 0.92f else 1f, animationSpec = tween(120), label = "pop")
                            Button(
                                onClick = {
                                    pop = true
                                    customBackground = null
                                    pop = false
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error,
                                    contentColor = MaterialTheme.colorScheme.onError
                                ),
                                modifier = Modifier.graphicsLayer(scaleX = scale, scaleY = scale)
                            ) { Text("Remove image") }
                        }
                    }
                }

                CustomizationCard(
                    title = "Background blur",
                    isFirst = false,
                    isLast = false
                ) {
                    Slider(value = backgroundBlur, onValueChange = { backgroundBlur = it }, valueRange = 0f..25f)
                }

                CustomizationCard(
                    title = "Transparency",
                    isFirst = false,
                    isLast = false
                ) {
                    Slider(value = transparency, onValueChange = { transparency = it })
                }

                CustomizationCard(
                    title = "Background color",
                    isFirst = false,
                    isLast = false
                ) {
                    ColorSwatchesRow(
                        options = listOf(
                            MaterialTheme.colorScheme.surfaceContainerHigh,
                            MaterialTheme.colorScheme.surfaceContainer,
                            MaterialTheme.colorScheme.primaryContainer,
                            MaterialTheme.colorScheme.secondaryContainer,
                            MaterialTheme.colorScheme.tertiaryContainer
                        ),
                        selected = currentBackgroundColor,
                        onSelect = { setBackgroundColor(it) },
                        onOpenCustom = onOpenCustomColor
                    )
                }

                CustomizationCard(
                    title = "Text color",
                    isFirst = false,
                    isLast = true
                ) {
                    ColorSwatchesRow(
                        options = listOf(
                            MaterialTheme.colorScheme.onSurface,
                            MaterialTheme.colorScheme.primary,
                            MaterialTheme.colorScheme.secondary,
                            MaterialTheme.colorScheme.tertiary,
                            MaterialTheme.colorScheme.inversePrimary
                        ),
                        selected = currentTextColor,
                        onSelect = { setTextColor(it) },
                        onOpenCustom = onOpenCustomTextColor
                    )
                }
            }

            Spacer(Modifier.height(dims.spacing.section))

            // Options
            SectionHeader(text = "Options")
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
            ) {
                Icon(
                    imageVector = Icons.Filled.Info,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "Changes in this section apply only to the 4×2 widget.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column {
                OptionToggleCard(
                    title = "Show Tomorrow",
                    subtitle = "Display the next due amount on the left",
                    checked = showTomorrow,
                    onCheckedChange = { showTomorrow = it },
                    isFirst = true,
                    isLast = false
                )
                OptionToggleCard(
                    title = "Show Upcoming",
                    subtitle = "Show the list of upcoming payables",
                    checked = showUpcoming,
                    onCheckedChange = { showUpcoming = it },
                    isFirst = false,
                    isLast = false
                )
                OptionToggleCard(
                    title = "Show Payables Count",
                    subtitle = "Show count pill at the bottom",
                    checked = showPayablesCount,
                    onCheckedChange = { showPayablesCount = it },
                    isFirst = false,
                    isLast = true
                )
            }

            // Final spacer so content doesn't sit under the navigation bar
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text = text,
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
    )
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CustomizationCard(
    title: String,
    isFirst: Boolean,
    isLast: Boolean,
    content: @Composable ColumnScope.() -> Unit
) {
    val interaction = remember { MutableInteractionSource() }
    val corners = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    Card(
        onClick = {},
        enabled = false,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp),
        shape = corners,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interaction
    ) {
        Column(modifier = Modifier.padding(LocalAppDimensions.current.spacing.card)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.height(8.dp))
            content()
        }
    }
}

@Composable
private fun ColorSwatchesRow(
    options: List<Color>,
    selected: Color,
    onSelect: (Color) -> Unit,
    onOpenCustom: (() -> Unit)? = null
) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        options.forEach { option ->
            val border = if (option == selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(option, RoundedCornerShape(18.dp))
                    .border(width = 2.dp, color = border, shape = RoundedCornerShape(18.dp))
                    .clickable { onSelect(option) },
            )
        }
        if (onOpenCustom != null) {
            // Custom color button
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), RoundedCornerShape(18.dp))
                    .border(
                        width = 2.dp,
                        color = MaterialTheme.colorScheme.primary,
                        shape = RoundedCornerShape(18.dp)
                    )
                    .clickable { onOpenCustom() },
                contentAlignment = Alignment.Center
            ) {
                Text("+", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OptionToggleCard(
    title: String,
    subtitle: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    isFirst: Boolean,
    isLast: Boolean
) {
    val interaction = remember { MutableInteractionSource() }
    val corners = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    Card(
        onClick = { onCheckedChange(!checked) },
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interaction),
        shape = corners,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interaction
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (subtitle != null) {
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Switch(checked = checked, onCheckedChange = onCheckedChange)
        }
    }
}

@Composable
private fun WidgetLivePreview(
    modifier: Modifier = Modifier,
    aspectRatio: Float = 2.2f,
    widgetSize: WidgetSize = WidgetSize.FourByTwo,
    textColor: Color,
    cardColor: Color,
    backgroundImageUri: String? = null,
    backgroundBlur: Float = 0f,
    pillColor: Color,
    showTomorrow: Boolean,
    showUpcoming: Boolean,
    showPayablesCount: Boolean
) {
    val innerShape = RoundedCornerShape(22.dp)

    Box(
        modifier = modifier
            .aspectRatio(aspectRatio)
            .clip(innerShape)
            .background(cardColor)
    ) {
        // Full-bleed background image if provided
        if (backgroundImageUri != null) {
            AndroidView(
                factory = { ctx ->
                    ImageView(ctx).apply { scaleType = ImageView.ScaleType.CENTER_CROP }
                },
                update = { it.setImageURI(backgroundImageUri.toUri()) },
                modifier = Modifier.matchParentSize().blur(backgroundBlur.dp)
            )
            // Dim overlay using cardColor alpha handled outside when composing cardColor
            Box(modifier = Modifier.matchParentSize().background(cardColor))
        }

        // Foreground content with inner padding
        Box(modifier = Modifier
            .fillMaxSize()
            .padding(18.dp)) {
            when (widgetSize) {
                WidgetSize.FourByTwo -> {
                    Row(modifier = Modifier.fillMaxSize()) {
                        // Left
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            if (showTomorrow) {
                                Column {
                                    Text("Tomorrow", color = textColor, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleSmall)
                                    Spacer(Modifier.height(8.dp))
                                    Text(
                                        text = "€ 42.96",
                                        color = textColor,
                                        style = MaterialTheme.typography.headlineLarge,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                            if (showPayablesCount) {
                                Box(
                                    modifier = Modifier
                                        .padding(bottom = 4.dp)
                                        .background(pillColor, RoundedCornerShape(12.dp))
                                        .padding(horizontal = 12.dp, vertical = 8.dp)
                                ) {
                                    Text("4 This Week", color = textColor, style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }

                        // Right
                        if (showUpcoming) {
                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxHeight(),
                                verticalArrangement = Arrangement.Top
                            ) {
                                Text(
                                    "Upcoming",
                                    color = textColor,
                                    fontWeight = FontWeight.SemiBold,
                                    style = MaterialTheme.typography.titleSmall,
                                    modifier = Modifier.align(Alignment.End)
                                )
                                Spacer(Modifier.height(8.dp))
                                Column(
                                    modifier = Modifier.align(Alignment.End),
                                    horizontalAlignment = Alignment.Start
                                ) {
                                    WidgetRow("Spotify", "€ 11.99", textColor)
                                    WidgetRow("Amazon", "€ 4,99", textColor)
                                    WidgetRow("Youtube", "€ 15.99", textColor)
                                    WidgetRow("Crunchyroll", "€ 9.99", textColor)
                                }
                                Spacer(Modifier.height(8.dp))
                            }
                        }
                    }
                }
                WidgetSize.TwoByTwo -> {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("€ 11.99", color = textColor, style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.SemiBold)
                        Spacer(Modifier.height(6.dp))
                        Text("Spotify", color = textColor, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                        Spacer(Modifier.height(2.dp))
                        Text("Due in 3 days", color = textColor, style = MaterialTheme.typography.bodyMedium)
                    }
                }
                WidgetSize.TwoByOne -> {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text("Tomorrow", color = textColor, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleSmall)
                        Spacer(Modifier.height(6.dp))
                        Text("€ 3.03", color = textColor, style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

@Composable
private fun WidgetRow(label: String, amount: String, color: Color) {
    val parts = remember(amount) { amount.split(' ', limit = 2) }
    val currency = parts.getOrNull(0) ?: ""
    val number = parts.getOrNull(1) ?: ""
    val amountColumnWidth = 84.dp
    val symbolBoxWidth = 35.dp

    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(
            label,
            color = color,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        Row(modifier = Modifier.width(amountColumnWidth)) {
            Text(
                currency,
                color = color,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.End,
                modifier = Modifier.width(symbolBoxWidth)
            )
            // No spacer to keep symbol close to the amount
            Text(
                number,
                color = color,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.End,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun WidgetScreenPreview() {
    AppTheme {
        WidgetScreen()
    }
}


