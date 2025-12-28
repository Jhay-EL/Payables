@file:Suppress("AssignedValueIsNeverRead", "unused")

package com.app.payables.ui.settings

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
import androidx.compose.runtime.ComposableTarget
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.platform.LocalContext
import android.net.Uri
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.blur
import coil.compose.AsyncImage
import androidx.compose.ui.layout.ContentScale
import androidx.compose.animation.core.animateFloatAsState
import com.app.payables.PayablesApplication
import android.content.Intent
import java.util.Locale

@Suppress("unused")
private enum class WidgetSize { FourByTwo, TwoByTwo, TwoByOne }

@OptIn(ExperimentalMaterial3Api::class)
@Suppress("unused")
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
    val context = LocalContext.current
    val app = context.applicationContext as PayablesApplication
    val settingsManager = app.settingsManager
    val repository = app.payableRepository
    val currencyExchangeRepository = app.currencyExchangeRepository
    
    // Fetch real data for preview
    val payables by repository.getActivePayablesList().collectAsState(initial = emptyList())
    val mainCurrency = remember { settingsManager.getDefaultCurrency() }
    
    // Ensure exchange rates are loaded
    LaunchedEffect(mainCurrency) {
        currencyExchangeRepository.ensureRatesUpdated(mainCurrency)
    }
    
    // Fetch exchange rates
    val exchangeRates by currencyExchangeRepository.getAllRates().collectAsState(initial = emptyList())
    val exchangeRatesMap: Map<String, Double> by remember(exchangeRates) { 
        derivedStateOf { exchangeRates.associate { it.currencyCode to it.rate } } 
    }
    
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Load initial values from SettingsManager
    val initialBackgroundColor = remember { Color(settingsManager.getWidgetBackgroundColor().toULong()) }
    val initialTextColor = remember { Color(settingsManager.getWidgetTextColor().toULong()) }
    val initialTransparency = remember { settingsManager.getWidgetTransparency() }
    val initialBackgroundBlur = remember { settingsManager.getWidgetBackgroundBlur() }
    val initialBackgroundImageUri = remember { settingsManager.getWidgetBackgroundImageUri() }
    val initialShowTomorrow = remember { settingsManager.getWidgetShowTomorrow() }
    val initialShowUpcoming = remember { settingsManager.getWidgetShowUpcoming() }
    val initialShowCount = remember { settingsManager.getWidgetShowCount() }

    // Local UI-only state (seeded from settings)
    var backgroundColorLocal by remember { mutableStateOf(initialBackgroundColor) }
    var transparency by remember { mutableFloatStateOf(initialTransparency) }
    var textColorLocal by remember { mutableStateOf(initialTextColor) }
    var showTomorrow by remember { mutableStateOf(initialShowTomorrow) }
    var showUpcoming by remember { mutableStateOf(initialShowUpcoming) }
    var showPayablesCount by remember { mutableStateOf(initialShowCount) }
    var customBackground by rememberSaveable { mutableStateOf(initialBackgroundImageUri) }
    var backgroundBlur by rememberSaveable { mutableFloatStateOf(initialBackgroundBlur) } // 0f..25f in dp

    // Helper to request widget update
    fun updateWidget() {
        val intent = Intent("com.app.payables.ACTION_WIDGET_UPDATE")
        intent.setPackage(context.packageName)
        context.sendBroadcast(intent)
    }

    // Persist changes
    LaunchedEffect(backgroundColorLocal) {
        settingsManager.setWidgetBackgroundColor(backgroundColorLocal.value.toLong())
        updateWidget()
    }
    LaunchedEffect(textColorLocal) {
        settingsManager.setWidgetTextColor(textColorLocal.value.toLong())
        updateWidget()
    }
    LaunchedEffect(transparency) {
        settingsManager.setWidgetTransparency(transparency)
        updateWidget()
    }
    LaunchedEffect(backgroundBlur) {
        settingsManager.setWidgetBackgroundBlur(backgroundBlur)
        updateWidget()
    }
    LaunchedEffect(customBackground) {
        settingsManager.setWidgetBackgroundImageUri(customBackground)
        updateWidget()
    }
    LaunchedEffect(showTomorrow) {
        settingsManager.setWidgetShowTomorrow(showTomorrow)
        updateWidget()
    }
    LaunchedEffect(showUpcoming) {
        settingsManager.setWidgetShowUpcoming(showUpcoming)
        updateWidget()
    }
    LaunchedEffect(showPayablesCount) {
        settingsManager.setWidgetShowCount(showPayablesCount)
        updateWidget()
    }
    
    // Also handle external color changes (from picker)
    LaunchedEffect(backgroundColor) {
        if (backgroundColor != null) {
            settingsManager.setWidgetBackgroundColor(backgroundColor.value.toLong())
            updateWidget()
        }
    }
    LaunchedEffect(textColor) {
        if (textColor != null) {
            settingsManager.setWidgetTextColor(textColor.value.toLong())
            updateWidget()
        }
    }


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
                        showPayablesCount = showPayablesCount,
                        payables = payables,
                        mainCurrency = mainCurrency,
                        exchangeRatesMap = exchangeRatesMap
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
                    val imageContext = LocalContext.current
                    val contentResolver = imageContext.contentResolver
                    
                    // Use OpenDocument to get persistent access to the file
                    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
                        if (uri != null) {
                            try {
                                // Take persistent read permission for the URI
                                contentResolver.takePersistableUriPermission(
                                    uri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                                )
                                customBackground = uri.toString()
                            } catch (e: SecurityException) {
                                // Fallback if persistent permission fails
                                customBackground = uri.toString()
                            }
                        }
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(onClick = {
                            // OpenDocument doesn't require read permission - the system handles it
                            imagePicker.launch(arrayOf("image/*"))
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
@ComposableTarget(applier = "androidx.compose.ui.UiComposable")
private fun WidgetLivePreview(
    modifier: Modifier = Modifier,
    aspectRatio: Float = 2.2f,
    widgetSize: WidgetSize = WidgetSize.FourByTwo,
    textColor: Color,
    cardColor: Color,
    backgroundImageUri: String? = null,
    backgroundBlur: Float = 0f,
    @Suppress("UNUSED_PARAMETER") pillColor: Color,
    @Suppress("UNUSED_PARAMETER") showTomorrow: Boolean,
    @Suppress("UNUSED_PARAMETER") showUpcoming: Boolean,
    @Suppress("UNUSED_PARAMETER") showPayablesCount: Boolean,
    payables: List<com.app.payables.data.Payable> = emptyList(),
    mainCurrency: String = "EUR",
    exchangeRatesMap: Map<String, Double> = emptyMap()
) {
    val innerShape = RoundedCornerShape(22.dp)
    val today = java.time.LocalDate.now()
    val tomorrow = today.plusDays(1)

    Box(
        modifier = modifier
        .aspectRatio(aspectRatio)
        .clip(innerShape)
        .background(cardColor)
    ) {
        // Full-bleed background image if provided
        if (backgroundImageUri != null) {
            AsyncImage(
                model = backgroundImageUri,
                contentDescription = "Widget background",
                contentScale = ContentScale.Crop,
                modifier = Modifier.matchParentSize().blur(backgroundBlur.dp)
            )
            // Dim overlay using cardColor alpha
            Box(modifier = Modifier.matchParentSize().background(cardColor))
        }

        // Content - matches the simplified widget layout
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            when (widgetSize) {
                WidgetSize.FourByTwo -> {
                    // 4x2 Widget: "Tomorrow" label + total amount due tomorrow
                    val tomorrowPayables = payables.filter {
                        val dueDate = com.app.payables.data.Payable.calculateNextDueDate(
                            java.time.LocalDate.ofEpochDay(it.billingDateMillis / com.app.payables.data.Payable.MILLIS_PER_DAY),
                            it.billingCycle
                        )
                        dueDate.isEqual(tomorrow)
                    }
                    
                    val totalTomorrow = tomorrowPayables.sumOf { payable ->
                        val originalAmount = payable.amount.toDoubleOrNull() ?: 0.0
                        if (payable.currency != mainCurrency && exchangeRatesMap.isNotEmpty()) {
                            val fromRate = exchangeRatesMap[payable.currency] ?: 1.0
                            val toRate = exchangeRatesMap[mainCurrency] ?: 1.0
                            originalAmount * (toRate / fromRate)
                        } else {
                            originalAmount
                        }
                    }
                    
                    val currencySymbol = getCurrencySymbol(mainCurrency)

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = "Tomorrow",
                            color = textColor,
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.titleLarge
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = "$currencySymbol ${String.format(Locale.getDefault(), "%.2f", totalTomorrow)}",
                            color = textColor,
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                
                WidgetSize.TwoByTwo -> {
                    // 2x2 Widget: Amount + Title + Due date for next payable
                    val nextDue = payables.minByOrNull { 
                        com.app.payables.data.Payable.calculateNextDueDate(
                            java.time.LocalDate.ofEpochDay(it.billingDateMillis / com.app.payables.data.Payable.MILLIS_PER_DAY),
                            it.billingCycle
                        ).toEpochDay()
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        if (nextDue != null) {
                            val dueDate = com.app.payables.data.Payable.calculateNextDueDate(
                                java.time.LocalDate.ofEpochDay(nextDue.billingDateMillis / com.app.payables.data.Payable.MILLIS_PER_DAY),
                                nextDue.billingCycle
                            )
                            val daysUntil = java.time.temporal.ChronoUnit.DAYS.between(today, dueDate)
                            
                            // Convert to main currency
                            val originalAmount = nextDue.amount.toDoubleOrNull() ?: 0.0
                            val convertedAmount = if (nextDue.currency != mainCurrency && exchangeRatesMap.isNotEmpty()) {
                                val fromRate = exchangeRatesMap[nextDue.currency] ?: 1.0
                                val toRate = exchangeRatesMap[mainCurrency] ?: 1.0
                                originalAmount * (toRate / fromRate)
                            } else {
                                originalAmount
                            }
                            val symbol = getCurrencySymbol(mainCurrency)
                            
                            val dueText = when (daysUntil) {
                                0L -> "Due today"
                                1L -> "Due tomorrow"
                                else -> "Due in $daysUntil days"
                            }

                            Text(
                                text = "$symbol ${String.format(Locale.getDefault(), "%.2f", convertedAmount)}",
                                color = textColor,
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = nextDue.title,
                                color = textColor,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            Spacer(Modifier.height(2.dp))
                            Text(
                                text = dueText,
                                color = textColor.copy(alpha = 0.7f),
                                style = MaterialTheme.typography.bodySmall
                            )
                        } else {
                            val symbol = getCurrencySymbol(mainCurrency)
                            Text(
                                text = "$symbol 0.00",
                                color = textColor,
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = "No Payables",
                                color = textColor,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
                
                WidgetSize.TwoByOne -> {
                    // 2x1 Widget: Next due payable with due label
                    val nextDue = payables.minByOrNull { 
                        com.app.payables.data.Payable.calculateNextDueDate(
                            java.time.LocalDate.ofEpochDay(it.billingDateMillis / com.app.payables.data.Payable.MILLIS_PER_DAY),
                            it.billingCycle
                        ).toEpochDay()
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        if (nextDue != null) {
                            val dueDate = com.app.payables.data.Payable.calculateNextDueDate(
                                java.time.LocalDate.ofEpochDay(nextDue.billingDateMillis / com.app.payables.data.Payable.MILLIS_PER_DAY),
                                nextDue.billingCycle
                            )
                            val daysUntil = java.time.temporal.ChronoUnit.DAYS.between(today, dueDate)
                            
                            val dueLabel = when (daysUntil) {
                                0L -> "Due today"
                                1L -> "Due tomorrow"
                                else -> "Due in $daysUntil days"
                            }
                            
                            // Convert to main currency
                            val originalAmount = nextDue.amount.toDoubleOrNull() ?: 0.0
                            val convertedAmount = if (nextDue.currency != mainCurrency && exchangeRatesMap.isNotEmpty()) {
                                val fromRate = exchangeRatesMap[nextDue.currency] ?: 1.0
                                val toRate = exchangeRatesMap[mainCurrency] ?: 1.0
                                originalAmount * (toRate / fromRate)
                            } else {
                                originalAmount
                            }
                            val symbol = getCurrencySymbol(mainCurrency)
                            
                            Text(
                                text = dueLabel,
                                color = textColor,
                                fontWeight = FontWeight.SemiBold,
                                style = MaterialTheme.typography.labelMedium
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = "$symbol ${String.format(Locale.getDefault(), "%.2f", convertedAmount)}",
                                color = textColor,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                        } else {
                            val symbol = getCurrencySymbol(mainCurrency)
                            Text(
                                text = "No Payables",
                                color = textColor,
                                fontWeight = FontWeight.SemiBold,
                                style = MaterialTheme.typography.labelMedium
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = "$symbol 0.00",
                                color = textColor,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                        }
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

@Suppress("SwallowedException")
private fun getCurrencySymbol(currencyCode: String): String {
     return try {
        java.util.Currency.getInstance(currencyCode).symbol
    } catch (_: Exception) {
        currencyCode
    }
}

@Preview(showBackground = true)
@Composable
private fun WidgetScreenPreview() {
    // Use MaterialTheme directly instead of AppTheme to avoid preview-incompatible dependencies
    MaterialTheme(
        colorScheme = darkColorScheme()
    ) {
        // Preview with mock data - can't use real PayablesApplication in preview
        val mockPayables = listOf(
            com.app.payables.data.Payable.create(
                id = "preview-1",
                title = "Netflix",
                amount = "15.99",
                billingDate = java.time.LocalDate.now().plusDays(1),
                currency = "EUR",
                billingCycle = "Monthly"
            ),
            com.app.payables.data.Payable.create(
                id = "preview-2",
                title = "Spotify",
                amount = "9.99",
                billingDate = java.time.LocalDate.now().plusDays(3),
                currency = "EUR",
                billingCycle = "Monthly"
            )
        )
        WidgetLivePreviewStandalone(
            payables = mockPayables,
            widgetSize = WidgetSize.FourByTwo,
            textColor = Color.White,
            cardColor = Color(0xFF2D2D2D),
            pillColor = Color.White.copy(alpha = 0.18f),
            showTomorrow = true,
            showUpcoming = true,
            showPayablesCount = true,
            mainCurrency = "EUR"
        )
    }
}

@Composable
private fun WidgetLivePreviewStandalone(
    payables: List<com.app.payables.data.Payable>,
    widgetSize: WidgetSize,
    textColor: Color,
    cardColor: Color,
    pillColor: Color,
    showTomorrow: Boolean,
    showUpcoming: Boolean,
    showPayablesCount: Boolean,
    mainCurrency: String = "EUR"
) {
    WidgetLivePreview(
        modifier = Modifier.width(300.dp),
        aspectRatio = when (widgetSize) {
            WidgetSize.FourByTwo -> 2f
            WidgetSize.TwoByTwo -> 1f
            WidgetSize.TwoByOne -> 2f
        },
        widgetSize = widgetSize,
        textColor = textColor,
        cardColor = cardColor,
        pillColor = pillColor,
        showTomorrow = showTomorrow,
        showUpcoming = showUpcoming,
        showPayablesCount = showPayablesCount,
        payables = payables,
        mainCurrency = mainCurrency
    )
}
