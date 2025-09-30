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
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.width
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    onBack: () -> Unit = {},
    summaryTitle: String = "Normalized Monthly Cost",
) {

    val context = LocalContext.current
    val payableRepository = (context.applicationContext as PayablesApplication).payableRepository
    val categoryRepository = (context.applicationContext as PayablesApplication).categoryRepository
    val monthlyCost by payableRepository.getNormalizedMonthlyCost().collectAsState(initial = 0.0)
    val spendingPerCategory by payableRepository.getSpendingPerCategory().collectAsState(initial = emptyMap())
    val categories by categoryRepository.getAllCategories().collectAsState(initial = emptyList())
    val upcomingPayments by payableRepository.getUpcomingPayments().collectAsState(initial = emptyList())
    val topFiveMostExpensive by payableRepository.getTopFiveMostExpensive().collectAsState(initial = emptyList())

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
                    amount = monthlyCost,
                    icon = Icons.Default.AccountBalanceWallet
                )
            }

            item {
                SpendingBreakdownCard(
                    spendingPerCategory = spendingPerCategory,
                    categories = categories
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
        InsightsScreen()
    }
}

@Composable
private fun TopFiveCard(
    topFivePayables: List<PayableItemData>
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
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(dims.spacing.card)
            ) {
                topFivePayables.forEachIndexed { index, payable ->
                    TopFiveItem(
                        payable = payable,
                        rank = index + 1
                    )
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
        Icon(
            imageVector = payable.icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = payable.backgroundColor
        )
        Spacer(modifier = Modifier.width(dims.spacing.md))
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
    upcomingPayments: List<PayableItemData>
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
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(dims.spacing.card)
            ) {
                upcomingPayments.forEachIndexed { index, payable ->
                    UpcomingPaymentItem(
                        payable = payable,
                        isLast = index == upcomingPayments.lastIndex
                    )
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
    spendingPerCategory: Map<String, Double>,
    categories: List<CategoryData>
) {
    val dims = LocalAppDimensions.current
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = dims.spacing.section)
    ) {
        Text(
            text = "Spending Breakdown",
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
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(dims.spacing.card),
                verticalAlignment = Alignment.CenterVertically
            ) {
                DonutChart(
                    spendingPerCategory = spendingPerCategory,
                    categories = categories,
                    modifier = Modifier.size(120.dp)
                )
                Spacer(modifier = Modifier.width(dims.spacing.lg))
                Column(
                    verticalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                ) {
                    spendingPerCategory.keys.forEach { categoryName ->
                        val category = categories.find { it.name == categoryName }
                        if (category != null) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(12.dp)
                                        .background(
                                            category.color,
                                            shape = RoundedCornerShape(4.dp)
                                        )
                                )
                                Text(
                                    text = category.name,
                                    style = MaterialTheme.typography.bodyLarge
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
private fun DonutChart(
    spendingPerCategory: Map<String, Double>,
    categories: List<CategoryData>,
    modifier: Modifier = Modifier
) {
    val totalSpending = spendingPerCategory.values.sum()
    val proportions = spendingPerCategory.values.map { (it / totalSpending).toFloat() }
    val animatedProgress = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        animatedProgress.animateTo(
            targetValue = 1f,
            animationSpec = tween(durationMillis = 1000)
        )
    }

    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            var startAngle = -90f
            proportions.forEachIndexed { index, proportion ->
                val sweepAngle = 360 * proportion * animatedProgress.value
                val category = categories.find { it.name == spendingPerCategory.keys.elementAt(index) }
                drawArc(
                    color = category?.color ?: Color.Gray,
                    startAngle = startAngle,
                    sweepAngle = sweepAngle,
                    useCenter = false,
                    style = Stroke(width = 30f, cap = StrokeCap.Round)
                )
                startAngle += sweepAngle
            }
        }
                Text(
                    text = String.format(Locale.US, "€%.2f", totalSpending),
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurface
                )
    }
}

@Composable
private fun SummaryCard(
    title: String,
    amount: Double,
    icon: ImageVector
) {
    val dims = LocalAppDimensions.current
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(dims.spacing.md),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(dims.spacing.card),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = String.format(Locale.US, "€%.2f", amount),
                    style = MaterialTheme.typography.displaySmall.copy(
                        fontWeight = FontWeight.Medium
                    ),
                    color = MaterialTheme.colorScheme.primary
                )
            }
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}
