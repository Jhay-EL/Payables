@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import com.app.payables.data.Currency
import com.app.payables.data.CurrencyList
import com.app.payables.theme.*
import com.app.payables.util.SettingsManager
import kotlinx.coroutines.android.awaitFrame
import androidx.compose.material.icons.filled.Check

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CurrencyScreen(
    onBack: () -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    val context = LocalContext.current
    val settingsManager = remember { SettingsManager(context) }
    var search by remember { mutableStateOf(TextFieldValue("")) }
    var isSearchActive by remember { mutableStateOf(false) }
    val results = remember(search) { CurrencyList.search(search.text) }
    val selectedCurrencyCode = settingsManager.getDefaultCurrency()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(text = "Currency", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
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
            top = dims.spacing.md,
        )
        val listBottomPadding = bottomInset + dims.spacing.navBarContentBottomMargin

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(contentPadding)
        ) {
            // Invisible anchor
            Box(Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

            // Title
            Column(Modifier.fadeUpTransform(fadeProgress)) {
                Text(
                    text = "Currency",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            // Description
            Text(
                text = "Set the app default currency",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            // Search field / Header
            AnimatedContent(
                targetState = isSearchActive,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "SearchToggle"
            ) { searchActive ->
                if (searchActive) {
                    val focusRequester = remember { FocusRequester() }
                    OutlinedTextField(
                        value = search,
                        onValueChange = { search = it },
                        modifier = Modifier
                            .fillMaxWidth()
                            .focusRequester(focusRequester),
                        singleLine = true,
                        label = { Text("Search currency") },
                        trailingIcon = {
                            IconButton(onClick = {
                                isSearchActive = false
                                search = TextFieldValue("")
                            }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear search")
                            }
                        }
                    )

                    LaunchedEffect(Unit) {
                        awaitFrame() // Wait for the field to be composed
                        focusRequester.requestFocus()
                    }
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = LocalAppDimensions.current.spacing.cardToHeader),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        SectionHeader()
                        IconButton(onClick = { isSearchActive = true }) {
                            Icon(Icons.Default.Search, contentDescription = "Search")
                        }
                    }
                }
            }

            Spacer(Modifier.height(dims.spacing.md))

            LazyColumn(
                contentPadding = PaddingValues(bottom = listBottomPadding)
            ) {
                itemsIndexed(results, key = { _, c -> c.code }) { index, currency ->
                    val isFirst = index == 0
                    val isLast = index == results.lastIndex
                    CurrencyRow(
                        currency = currency,
                        isSelected = currency.code == selectedCurrencyCode,
                        onSelect = {
                            settingsManager.setDefaultCurrency(currency.code)
                            onBack()
                        },
                        isFirst = isFirst,
                        isLast = isLast
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionHeader() {
    Text(
        text = "All currencies",
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface
    )
}

@Composable
private fun CurrencyRow(
    currency: Currency,
    isSelected: Boolean,
    onSelect: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
) {
    val interaction = remember { MutableInteractionSource() }
    val dims = LocalAppDimensions.current
    
    val dashboardTheme = LocalDashboardTheme.current
    val shape = when {
        isFirst && isLast -> RoundedCornerShape(
            topStart = dashboardTheme.groupTopCornerRadius,
            topEnd = dashboardTheme.groupTopCornerRadius,
            bottomStart = dashboardTheme.groupBottomCornerRadius,
            bottomEnd = dashboardTheme.groupBottomCornerRadius
        )
        isFirst -> RoundedCornerShape(
            topStart = dashboardTheme.groupTopCornerRadius,
            topEnd = dashboardTheme.groupTopCornerRadius,
            bottomStart = dashboardTheme.groupInnerCornerRadius,
            bottomEnd = dashboardTheme.groupInnerCornerRadius
        )
        isLast -> RoundedCornerShape(
            topStart = dashboardTheme.groupInnerCornerRadius,
            topEnd = dashboardTheme.groupInnerCornerRadius,
            bottomStart = dashboardTheme.groupBottomCornerRadius,
            bottomEnd = dashboardTheme.groupBottomCornerRadius
        )
        else -> RoundedCornerShape(dashboardTheme.groupInnerCornerRadius)
    }

    Card(
        onClick = onSelect,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interaction),
        shape = shape,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interaction
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(dims.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Badge
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = currency.symbol,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(text = currency.code, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                Text(text = currency.name, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp))
            }

            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected currency",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CurrencyScreenPreview() {
    AppTheme {
        CurrencyScreen()
    }
}



