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
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import java.util.Locale
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
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import com.app.payables.theme.AppTheme
import kotlinx.coroutines.launch
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Brush
import com.app.payables.data.SpendingTimeframe
import androidx.compose.ui.text.TextStyle
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.ui.window.PopupProperties
import androidx.activity.compose.BackHandler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    onBack: () -> Unit = {},
) {

    val context = LocalContext.current
    val payableRepository = (context.applicationContext as PayablesApplication).payableRepository
    val categoryRepository = (context.applicationContext as PayablesApplication).categoryRepository

    var spendingTimeframe by remember { mutableStateOf(SpendingTimeframe.Monthly) }
    var avgCostTimeframe by remember { mutableStateOf(SpendingTimeframe.Monthly) }

    val avgCost by remember(avgCostTimeframe) {
        payableRepository.getAverageCost(avgCostTimeframe)
    }.collectAsState(initial = 0.0)
    
    val spendingPerCategory by remember(spendingTimeframe) {
        payableRepository.getSpendingPerCategory(spendingTimeframe)
    }.collectAsState(initial = null)
    val categories by categoryRepository.getAllCategories().collectAsState(initial = emptyList())
    val upcomingPayments by payableRepository.getUpcomingPayments().collectAsState(initial = null)
    val topFiveMostExpensive by payableRepository.getTopFiveMostExpensive().collectAsState(initial = null)

    InsightsScreenContent(
        onBack = onBack,
        summaryTitle = "Average ${avgCostTimeframe.name} Cost",
        avgCost = avgCost,
        avgCostTimeframe = avgCostTimeframe,
        spendingPerCategory = spendingPerCategory,
        categories = categories,
        upcomingPayments = upcomingPayments,
        topFiveMostExpensive = topFiveMostExpensive,
        onTimeframeSelected = { spendingTimeframe = it },
        onAvgCostTimeframeSelected = { avgCostTimeframe = it },
        spendingTimeframe = spendingTimeframe
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
    upcomingPayments: List<PayableItemData>?,
    topFiveMostExpensive: List<PayableItemData>?,
    onTimeframeSelected: (SpendingTimeframe) -> Unit,
    onAvgCostTimeframeSelected: (SpendingTimeframe) -> Unit,
    spendingTimeframe: SpendingTimeframe
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
                    spendingTimeframe = spendingTimeframe
                )
            }

            item {
                UpcomingPaymentsCard(
                    upcomingPayments = upcomingPayments
                )
            }

            item {
                TopFiveCard(
                    topFivePayables = topFiveMostExpensive
                )
            }

            item {
                val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
            }
        }
    }
}

@Preview(showBackground = true)
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
            upcomingPayments = listOf(
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
            onTimeframeSelected = {},
            onAvgCostTimeframeSelected = {},
            spendingTimeframe = SpendingTimeframe.Monthly
        )
    }
}

@Composable
private fun TopFiveCard(
    topFivePayables: List<PayableItemData>?
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
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(dims.spacing.md),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            )
        ) {
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
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(250.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No data available.",
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
                        topFivePayables.forEachIndexed { index, payable ->
                            key(payable.id) {
                                TopFiveItem(
                                    payable = payable,
                                    rank = index + 1
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TopFiveItem(
    payable: PayableItemData,
    rank: Int
) {
    val dims = LocalAppDimensions.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = dims.spacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "$rank.",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.width(32.dp)
        )
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = payable.name,
                style = MaterialTheme.typography.bodyLarge,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = payable.planType,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            text = String.format(Locale.US, "€%.2f", payable.price.toDoubleOrNull() ?: 0.0),
            style = MaterialTheme.typography.bodyLarge.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.primary
        )
    }
}

@Composable
private fun UpcomingPaymentsCard(
    upcomingPayments: List<PayableItemData>?
) {
    val dims = LocalAppDimensions.current
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = dims.spacing.section)
    ) {
        Text(
            text = "Upcoming Payments",
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
            when {
                upcomingPayments == null -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                upcomingPayments.isEmpty() -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp)
                            .padding(dims.spacing.card),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No upcoming payments.",
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
                        upcomingPayments.forEachIndexed { index, payable ->
                            key(payable.id) {
                                UpcomingPaymentItem(
                                    payable = payable,
                                    isLast = index == upcomingPayments.lastIndex
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun UpcomingPaymentItem(
    payable: PayableItemData,
    isLast: Boolean
) {
    val dims = LocalAppDimensions.current
    val timelineColor = MaterialTheme.colorScheme.primary
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(IntrinsicSize.Min)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.width(40.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(timelineColor, shape = RoundedCornerShape(4.dp))
            )
            if (!isLast) {
                Box(
                    modifier = Modifier
                        .width(2.dp)
                        .fillMaxHeight()
                        .background(timelineColor)
                )
            }
        }
        Spacer(modifier = Modifier.width(dims.spacing.md))
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(bottom = if (isLast) 0.dp else dims.spacing.lg)
        ) {
            Text(
                text = payable.name,
                style = MaterialTheme.typography.titleMedium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = payable.dueDate,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            text = String.format(Locale.US, "€%.2f", payable.price.toDoubleOrNull() ?: 0.0),
            style = MaterialTheme.typography.bodyLarge.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.primary
        )
    }
}

@Composable
private fun SpendingBreakdownCard(
    spendingPerCategory: Map<String, Double>?,
    categories: List<CategoryData>,
    onTimeframeSelected: (SpendingTimeframe) -> Unit,
    spendingTimeframe: SpendingTimeframe
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
                                            text = String.format(Locale.US, "€%.2f", spendingPerCategory[categoryName]),
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
    modifier: Modifier = Modifier
) {
    val maxSpending = spendingPerCategory.values.maxOrNull() ?: 0.0
    val yAxisLabelCount = 5
    val yAxisLabels = List(yAxisLabelCount) { i ->
        val value = maxSpending * (i.toFloat() / (yAxisLabelCount - 1))
        String.format(Locale.US, "€%.0f", value)
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
) {
    val dims = LocalAppDimensions.current
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.height(dims.spacing.xs))
        Text(
            text = String.format(Locale.US, "€%.2f", amount),
            style = MaterialTheme.typography.displaySmall.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.primary
        )
    }
}
