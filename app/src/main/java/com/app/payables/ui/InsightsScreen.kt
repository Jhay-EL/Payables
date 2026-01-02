@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.TrendingFlat
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.derivedStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import java.util.Locale
import java.time.LocalDate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.app.payables.PayablesApplication
import com.app.payables.theme.*
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import com.app.payables.theme.AppTheme
import kotlinx.coroutines.launch
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Brush
import androidx.compose.ui.graphics.Brush
import kotlinx.coroutines.delay
import androidx.compose.animation.core.*
import androidx.compose.ui.text.TextStyle
import com.app.payables.data.SpendingTimeframe
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.ui.window.PopupProperties
import androidx.activity.compose.BackHandler
import com.app.payables.util.SettingsManager

// Helper function to get currency symbol
private fun getCurrencySymbol(currency: String): String {
    return when (currency) {
        "EUR" -> "€"
        "USD" -> "$"
        "GBP" -> "£"
        "JPY" -> "¥"
        "PHP" -> "₱"
        "CHF" -> "CHF "
        "CAD" -> "C$"
        "AUD" -> "A$"
        "NZD" -> "NZ$"
        "CNY" -> "¥"
        "INR" -> "₹"
        "KRW" -> "₩"
        "BRL" -> "R$"
        "MXN" -> "MX$"
        "SGD" -> "S$"
        "HKD" -> "HK$"
        "SEK" -> "kr "
        "NOK" -> "kr "
        "DKK" -> "kr "
        "PLN" -> "zł "
        "THB" -> "฿"
        "MYR" -> "RM "
        "IDR" -> "Rp "
        "VND" -> "₫"
        "RUB" -> "₽"
        "TRY" -> "₺"
        "ZAR" -> "R "
        "AED" -> "د.إ "
        "SAR" -> "﷼ "
        else -> "$currency "
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    onBack: () -> Unit = {},
) {

    val context = LocalContext.current
    val payableRepository = (context.applicationContext as PayablesApplication).payableRepository
    val categoryRepository = (context.applicationContext as PayablesApplication).categoryRepository
    val currencyExchangeRepository = (context.applicationContext as PayablesApplication).currencyExchangeRepository
    val settingsManager = remember { SettingsManager(context) }
    val mainCurrency = settingsManager.getDefaultCurrency()

    var spendingTimeframe by remember { mutableStateOf(SpendingTimeframe.Monthly) }
    var avgCostTimeframe by remember { mutableStateOf(SpendingTimeframe.Monthly) }

    // Ensure exchange rates are loaded when screen opens
    LaunchedEffect(mainCurrency) {
        currencyExchangeRepository.ensureRatesUpdated(mainCurrency)
    }

    // Fetch exchange rates
    val exchangeRates by currencyExchangeRepository.getAllRates().collectAsState(initial = emptyList())
    val exchangeRatesMap: Map<String, Double> by remember(exchangeRates) { 
        derivedStateOf { exchangeRates.associate { it.currencyCode to it.rate } } 
    }

    val avgCost by remember(avgCostTimeframe, exchangeRatesMap) {
        payableRepository.getAverageCostConverted(avgCostTimeframe, mainCurrency, exchangeRatesMap)
    }.collectAsState(initial = 0.0)
    
    val spendingPerCategory by remember(spendingTimeframe, exchangeRatesMap) {
        payableRepository.getSpendingPerCategoryConverted(spendingTimeframe, mainCurrency, exchangeRatesMap)
    }.collectAsState(initial = null)
    val categories by categoryRepository.getAllCategories().collectAsState(initial = emptyList())
    
    // Get raw payables and enrich with converted amounts
    val rawActivePayables by payableRepository.getActivePayables().collectAsState(initial = emptyList())

    val activePayables: List<PayableItemData> by remember(rawActivePayables, exchangeRatesMap) {
        derivedStateOf {
            rawActivePayables.map { payable ->
                if (payable.currency != mainCurrency && exchangeRatesMap.isNotEmpty()) {
                    val fromRate = exchangeRatesMap[payable.currency] ?: 1.0
                    val toRate = exchangeRatesMap[mainCurrency] ?: 1.0
                    val originalAmount = payable.price.toDoubleOrNull() ?: 0.0
                    val convertedAmount = originalAmount * (toRate / fromRate)
                    payable.copy(convertedPrice = convertedAmount, mainCurrency = mainCurrency)
                } else {
                    payable
                }
            }
        }
    }

    val topFiveMostExpensive: List<PayableItemData> by remember(activePayables) { 
        derivedStateOf {
            activePayables.sortedByDescending { payable ->
                val amount = payable.convertedPrice ?: (payable.price.toDoubleOrNull() ?: 0.0)
                
                if (payable.endDateMillis != null) {
                    val endMillis = payable.endDateMillis
                    // If end date is in the past, cost is 0 (should be finished, but active check)
                    if (endMillis < System.currentTimeMillis()) {
                        0.0
                    } else {
                        // Calculate total remaining cost based on actual future occurrences
                        val endDate = LocalDate.ofEpochDay(endMillis / 86400000L)
                        // Ensure we start counting from the next due date
                        var currentDue = LocalDate.ofEpochDay(payable.nextDueDateMillis / 86400000L)
                        
                        var count = 0
                        // Safety cap to prevent infinite loops logic errors, though unlikely
                        val maxIterations = 1000 
                        
                        while (!currentDue.isAfter(endDate) && count < maxIterations) {
                            count++
                            currentDue = when(payable.billingCycle) {
                                "Weekly" -> currentDue.plusWeeks(1)
                                "Monthly" -> currentDue.plusMonths(1)
                                "Quarterly" -> currentDue.plusMonths(3)
                                "Yearly" -> currentDue.plusYears(1)
                                else -> currentDue.plusMonths(1)
                            }
                        }
                        amount * count
                    }
                } else {
                    // Standard annualized calculation for indefinite payables
                    when (payable.billingCycle) {
                        "Weekly" -> amount * 52.14285714 // 365.0 / 7.0
                        "Monthly" -> amount * 12.0
                        "Quarterly" -> amount * 4.0
                        "Yearly" -> amount
                        else -> amount
                    }
                }
            }.take(5)
        }
    }

    InsightsScreenContent(
        onBack = onBack,
        summaryTitle = "Average ${avgCostTimeframe.name} Cost",
        avgCost = avgCost,
        avgCostTimeframe = avgCostTimeframe,
        spendingPerCategory = spendingPerCategory,
        categories = categories,
        topFiveMostExpensive = topFiveMostExpensive,
        activePayables = activePayables,
        onTimeframeSelected = { spendingTimeframe = it },
        onAvgCostTimeframeSelected = { avgCostTimeframe = it },
        spendingTimeframe = spendingTimeframe,
        mainCurrency = mainCurrency
    )
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun InsightsScreenContent(
    onBack: () -> Unit,
    summaryTitle: String,
    avgCost: Double,
    avgCostTimeframe: SpendingTimeframe,
    spendingPerCategory: Map<String, Double>?,
    categories: List<CategoryData>,
    topFiveMostExpensive: List<PayableItemData>?,
    activePayables: List<PayableItemData> = emptyList(),
    onTimeframeSelected: (SpendingTimeframe) -> Unit,
    onAvgCostTimeframeSelected: (SpendingTimeframe) -> Unit,
    spendingTimeframe: SpendingTimeframe,
    mainCurrency: String = "EUR"
) {
    val dims = LocalAppDimensions.current

    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text("Insights", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarColor,
                    scrolledContainerColor = topBarColor
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = dims.spacing.md)
        ) {
            item {
                Box(Modifier.windowYReporter { y ->
                    if (titleInitialY == null) titleInitialY = y; titleWindowY = y
                })

                Column(Modifier.fadeUpTransform(fade)) {
                    Text(
                        text = "Insights",
                        style = LocalDashboardTheme.current.titleTextStyle,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                        modifier = Modifier.padding(
                            top = dims.titleDimensions.payablesTitleTopPadding,
                            bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                        )
                    )
                }
            }

            item {
                SummaryCard(
                    title = summaryTitle,
                    amount = avgCost,
                    mainCurrency = mainCurrency
                )
            }

            item {
                FlowRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = dims.spacing.md),
                    horizontalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                ) {
                    SpendingTimeframe.entries.forEach { timeframe ->
                        FilterChip(
                            selected = avgCostTimeframe == timeframe,
                            onClick = { onAvgCostTimeframeSelected(timeframe) },
                            label = { Text(timeframe.name) }
                        )
                    }
                }
            }

            item {
                SpendingBreakdownCard(
                    spendingPerCategory = spendingPerCategory,
                    categories = categories,
                    onTimeframeSelected = onTimeframeSelected,
                    spendingTimeframe = spendingTimeframe,
                    mainCurrency = mainCurrency
                )
            }

            item {
                SpendingForecastCard(
                    payables = activePayables,
                    mainCurrency = mainCurrency
                )
            }

            item {
                TopFiveCard(
                    topFivePayables = topFiveMostExpensive,
                    mainCurrency = mainCurrency
                )
            }

            item {
                val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
            }
        }
    }
}

@Preview(showBackground = true, heightDp = 1500)
@Composable
private fun InsightsScreenPreview() {
    AppTheme {
        InsightsScreenContent(
            onBack = {},
            summaryTitle = "Average Monthly Cost",
            avgCost = 123.45,
            avgCostTimeframe = SpendingTimeframe.Monthly,
            spendingPerCategory = mapOf(
                "Entertainment" to 50.0,
                "Utilities" to 73.45
            ),
            categories = listOf(
                CategoryData("Entertainment", "2", Color(0xFFE91E63), Icons.Default.Movie),
                CategoryData("Utilities", "1", Color(0xFF4CAF50), Icons.Default.Lightbulb)
            ),
            topFiveMostExpensive = listOf(
                PayableItemData(
                    id = "1",
                    name = "Adobe Creative Cloud",
                    planType = "All Apps",
                    price = "52.99",
                    currency = "USD",
                    dueDate = "in 10 days",
                    icon = Icons.Default.Brush,
                    backgroundColor = Color(0xFFFF0000),
                    billingCycle = "Monthly"
                ),
                PayableItemData(
                    id = "2",
                    name = "Netflix",
                    planType = "Premium",
                    price = "19.99",
                    currency = "USD",
                    dueDate = "in 3 days",
                    icon = Icons.Default.Movie,
                    backgroundColor = Color(0xFFE50914),
                    billingCycle = "Monthly"
                )
            ),
            activePayables = listOf(
                PayableItemData(
                    id = "1",
                    name = "Netflix",
                    planType = "Premium",
                    price = "19.99",
                    currency = "USD",
                    dueDate = "in 3 days",
                    icon = Icons.Default.Movie,
                    backgroundColor = Color(0xFFE50914),
                    billingCycle = "Monthly"
                ),
                PayableItemData(
                    id = "2",
                    name = "Spotify",
                    planType = "Family",
                    price = "14.99",
                    currency = "USD",
                    dueDate = "in 5 days",
                    icon = Icons.Default.MusicNote,
                    backgroundColor = Color(0xFF1DB954),
                    billingCycle = "Monthly"
                )
            ),
            onTimeframeSelected = {},
            onAvgCostTimeframeSelected = {},
            spendingTimeframe = SpendingTimeframe.Monthly
        )
    }
}

@Composable
private fun TopFiveCard(
    topFivePayables: List<PayableItemData>?,
    mainCurrency: String = "EUR"
) {
    val dims = LocalAppDimensions.current
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = dims.spacing.section)
    ) {
        Text(
            text = "Top 5 Most Expensive",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(bottom = dims.spacing.md)
        )

        when {
            topFivePayables == null -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(250.dp)
                        .padding(dims.spacing.card),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            topFivePayables.isEmpty() -> {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(dims.spacing.md),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                    )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(100.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No data available.",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
            else -> {
                Column(
                    verticalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                ) {
                    topFivePayables.forEachIndexed { index, payable ->
                        key(payable.id) {
                            EnhancedTopFiveItem(
                                payable = payable,
                                rank = index + 1,
                                delayMillis = index * 100,
                                mainCurrency = mainCurrency
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EnhancedTopFiveItem(
    payable: PayableItemData,
    rank: Int,
    delayMillis: Int,
    mainCurrency: String
) {
    val dims = LocalAppDimensions.current
    
    // Animation
    val alpha = remember { Animatable(0f) }
    val slideY = remember { Animatable(20f) }
    
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        launch { alpha.animateTo(1f, tween(300, easing = LinearOutSlowInEasing)) }
        launch { slideY.animateTo(0f, tween(400, easing = LinearOutSlowInEasing)) }
    }
    
    // Rank Color Logic
    val rankColor = when(rank) {
        1 -> Color(0xFFFFD700) // Gold
        2 -> Color(0xFFC0C0C0) // Silver
        3 -> Color(0xFFCD7F32) // Bronze
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                this.alpha = alpha.value
                this.translationY = slideY.value
            },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(dims.spacing.md)
    ) {
        Row(
            modifier = Modifier
                .padding(dims.spacing.md)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Rank Badge
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(rankColor.copy(alpha = 0.1f), CircleShape)
                    .border(1.dp, rankColor.copy(alpha = 0.5f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "#$rank",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = rankColor
                )
            }
            
            Spacer(modifier = Modifier.width(dims.spacing.md))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = payable.name,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = payable.planType,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            val displayAmount = payable.convertedPrice ?: (payable.price.toDoubleOrNull() ?: 0.0)
            val currencySymbol = getCurrencySymbol(mainCurrency)
            Text(
                text = String.format(Locale.US, "%s%.2f", currencySymbol, displayAmount),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun SpendingBreakdownCard(
    spendingPerCategory: Map<String, Double>?,
    categories: List<CategoryData>,
    onTimeframeSelected: (SpendingTimeframe) -> Unit,
    spendingTimeframe: SpendingTimeframe,
    mainCurrency: String = "EUR"
) {
    val dims = LocalAppDimensions.current
    var showMenu by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = dims.spacing.section)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Spending Breakdown",
                style = MaterialTheme.typography.headlineSmall,
            )
            Box {
                IconButton(onClick = { showMenu = true }) {
                    Icon(Icons.Default.MoreVert, contentDescription = "More options")
                }
                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { 
                        android.util.Log.d("InsightsDropdown", "onDismissRequest called")
                        showMenu = false 
                    },
                    properties = PopupProperties(
                        focusable = true,
                        dismissOnBackPress = true,
                        dismissOnClickOutside = true
                    )
                ) {
                    SpendingTimeframe.entries.forEach { timeframeOption ->
                        DropdownMenuItem(
                            text = { Text(timeframeOption.name) },
                            onClick = {
                                onTimeframeSelected(timeframeOption)
                                showMenu = false
                            }
                        )
                    }
                }
            }
        }
        Spacer(modifier = Modifier.height(dims.spacing.md))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(dims.spacing.md),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            )
        ) {
            when {
                spendingPerCategory == null -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(250.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                spendingPerCategory.isEmpty() -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(250.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No spending data available.",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
                else -> {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(dims.spacing.card)
                    ) {
                        ColumnChart(
                            spendingPerCategory = spendingPerCategory,
                            categories = categories,
                            spendingTimeframe = spendingTimeframe,
                            mainCurrency = mainCurrency,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp)
                        )
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        Column(
                            verticalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                        ) {
                            spendingPerCategory.keys.forEach { categoryName ->
                                val category = categories.find { it.name == categoryName }
                                if (category != null) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically,
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(12.dp)
                                                .background(
                                                    category.color,
                                                    shape = RoundedCornerShape(4.dp)
                                                )
                                        )
                                        Spacer(modifier = Modifier.width(dims.spacing.sm))
                                        Text(
                                            text = category.name,
                                            style = MaterialTheme.typography.bodySmall,
                                            modifier = Modifier.weight(1f)
                                        )
                                        Text(
                                            text = String.format(Locale.US, "%s%.2f", getCurrencySymbol(mainCurrency), spendingPerCategory[categoryName]),
                                            style = MaterialTheme.typography.bodySmall,
                                            fontWeight = FontWeight.Medium
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Handle back button when menu is open (highest priority)
    BackHandler(enabled = showMenu) {
        android.util.Log.d("InsightsBackHandler", "Closing menu")
        showMenu = false
    }
}

@Composable
private fun ColumnChart(
    spendingPerCategory: Map<String, Double>,
    categories: List<CategoryData>,
    spendingTimeframe: SpendingTimeframe,
    modifier: Modifier = Modifier,
    mainCurrency: String = "EUR"
) {
    val currencySymbol = getCurrencySymbol(mainCurrency)
    val maxSpending = spendingPerCategory.values.maxOrNull() ?: 0.0
    val yAxisLabelCount = 5
    val yAxisLabels = List(yAxisLabelCount) { i ->
        val value = maxSpending * (i.toFloat() / (yAxisLabelCount - 1))
        String.format(Locale.US, "%s%.0f", currencySymbol, value)
    }

    val animatables = spendingPerCategory.keys.associateWith {
        remember(it) { Animatable(0f) }
    }

    LaunchedEffect(spendingTimeframe, spendingPerCategory) {
        // Reset all animations to 0 first
        animatables.values.forEach { animatable ->
            animatable.snapTo(0f)
        }
        
        // Then animate to target values
        spendingPerCategory.forEach { (categoryName, spending) ->
            val proportion = if (maxSpending > 0) (spending / maxSpending).toFloat() else 0f
            launch {
                animatables[categoryName]?.animateTo(
                    targetValue = proportion,
                    animationSpec = tween(durationMillis = 800)
                )
            }
        }
    }

    Row(modifier = modifier.fillMaxWidth()) {
        YAxis(
            labels = yAxisLabels,
            modifier = Modifier.padding(end = 8.dp)
        )
        Canvas(modifier = Modifier.fillMaxSize()) {
            val barCount = spendingPerCategory.size
            val barWidth = size.width / (barCount * 1.5f)
            val spacing = barWidth / 2

            spendingPerCategory.keys.forEachIndexed { index, categoryName ->
                val category = categories.find { it.name == categoryName }
                if (category != null) {
                    val barHeight = size.height * (animatables[categoryName]?.value ?: 0f)
                    val x = (index * (barWidth + spacing)) + spacing / 2
                    drawRoundRect(
                        color = category.color,
                        topLeft = androidx.compose.ui.geometry.Offset(x, size.height - barHeight),
                        size = androidx.compose.ui.geometry.Size(barWidth, barHeight),
                        cornerRadius = androidx.compose.ui.geometry.CornerRadius(x = 12f, y = 12f)
                    )
                }
            }
        }
    }
}

@Composable
private fun YAxis(
    labels: List<String>,
    modifier: Modifier = Modifier,
    style: TextStyle = MaterialTheme.typography.bodySmall
) {
    Column(
        modifier = modifier.fillMaxHeight(),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.End
    ) {
        labels.reversed().forEach { label ->
            Text(text = label, style = style)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
private fun SummaryCard(
    title: String,
    amount: Double,
    mainCurrency: String = "EUR"
) {
    val dims = LocalAppDimensions.current
    val currencySymbol = getCurrencySymbol(mainCurrency)
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.height(dims.spacing.xs))
        Text(
            text = String.format(Locale.US, "%s%.2f", currencySymbol, amount),
            style = MaterialTheme.typography.displaySmall.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.primary
        )
    }
}

@Composable
private fun SpendingForecastCard(
    payables: List<PayableItemData>,
    mainCurrency: String
) {
    val dims = LocalAppDimensions.current
    
    // Calculate forecasts
    val monthlyTotal = remember(payables) {
        payables.sumOf { payable ->
            val amount = payable.convertedPrice ?: (payable.price.toDoubleOrNull() ?: 0.0)
            when (payable.billingCycle) {
                "Weekly" -> amount * 4.345
                "Monthly" -> amount
                "Quarterly" -> amount / 3
                "Yearly" -> amount / 12
                else -> amount
            }
        }
    }

    val forecast3m = monthlyTotal * 3
    val forecast6m = monthlyTotal * 6
    val forecast1y = monthlyTotal * 12

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = dims.spacing.section)
    ) {
        Text(
            text = "Spending Forecast",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(bottom = dims.spacing.md)
        )
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(dims.spacing.md),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(dims.spacing.card)
            ) {
                if (payables.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No active subscriptions to forecast.",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                } else {
                    ForecastBarChart(
                        value1 = forecast3m,
                        value2 = forecast6m,
                        value3 = forecast1y
                    )
                    
                    Spacer(modifier = Modifier.height(dims.spacing.lg))
                    
                    Column(verticalArrangement = Arrangement.spacedBy(dims.spacing.sm)) {
                        ForecastPeriodItem(
                            label = "Next 3 Months",
                            amount = forecast3m,
                            mainCurrency = mainCurrency,
                            trend = "Stable",
                            color = MaterialTheme.colorScheme.tertiary
                        )
                        ForecastPeriodItem(
                            label = "Next 6 Months",
                            amount = forecast6m,
                            mainCurrency = mainCurrency,
                            trend = "Stable",
                            color = MaterialTheme.colorScheme.secondary
                        )
                        ForecastPeriodItem(
                            label = "Next 1 Year",
                            amount = forecast1y,
                            mainCurrency = mainCurrency,
                            trend = "Stable",
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ForecastBarChart(
    value1: Double,
    value2: Double,
    value3: Double
) {
    val maxValue = value3.coerceAtLeast(1.0)
    val anim1 = remember { Animatable(0f) }
    val anim2 = remember { Animatable(0f) }
    val anim3 = remember { Animatable(0f) }

    LaunchedEffect(value1, value2, value3) {
        anim1.animateTo((value1 / maxValue).toFloat(), tween(800, delayMillis = 0))
        anim2.animateTo((value2 / maxValue).toFloat(), tween(800, delayMillis = 200))
        anim3.animateTo((value3 / maxValue).toFloat(), tween(800, delayMillis = 400))
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp),
        verticalArrangement = Arrangement.SpaceEvenly
    ) {
        ForecastBar(
            progress = anim1.value,
            color = MaterialTheme.colorScheme.tertiary,
            label = "3M"
        )
        ForecastBar(
            progress = anim2.value,
            color = MaterialTheme.colorScheme.secondary,
            label = "6M"
        )
        ForecastBar(
            progress = anim3.value,
            color = MaterialTheme.colorScheme.primary,
            label = "1Y"
        )
    }
}

@Composable
private fun ForecastBar(
    progress: Float,
    color: Color,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.width(28.dp),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Box(
            modifier = Modifier
                .weight(1f)
                .height(24.dp)
                .background(
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                    shape = RoundedCornerShape(12.dp)
                )
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(progress.coerceIn(0f, 1f))
                    .fillMaxHeight()
                    .background(
                        brush = Brush.horizontalGradient(
                            colors = listOf(
                                color.copy(alpha = 0.7f),
                                color
                            )
                        ),
                        shape = RoundedCornerShape(12.dp)
                    )
            )
        }
    }
}

@Composable
private fun ForecastPeriodItem(
    label: String,
    amount: Double,
    mainCurrency: String,
    trend: String,
    color: Color
) {
    val currencySymbol = getCurrencySymbol(mainCurrency)
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .background(color, RoundedCornerShape(4.dp))
        )
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        
        val icon = when (trend) {
            "Up" -> Icons.AutoMirrored.Filled.TrendingUp
            "Down" -> Icons.AutoMirrored.Filled.TrendingDown
            else -> Icons.AutoMirrored.Filled.TrendingFlat
        }
        
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = String.format(Locale.US, "%s%.2f", currencySymbol, amount),
            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold)
        )
    }
}
