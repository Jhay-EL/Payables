package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.text.style.TextOverflow
import com.app.payables.theme.AppTheme
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.computeTopBarAlphaFromContentFade
import com.app.payables.theme.fadeUpTransform
import com.app.payables.theme.pressableCard
import com.app.payables.theme.rememberFadeToTopBarProgress
import com.app.payables.theme.windowYReporter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EraseDataScreen(
    onBack: () -> Unit = {},
    onRemoveActive: () -> Unit = {},
    onRemoveFinished: () -> Unit = {},
    onRemovePaused: () -> Unit = {},
    onRemovePaymentMethods: () -> Unit = {},
    onRemoveCustomCategories: () -> Unit = {},
    onRemoveCustomIcons: () -> Unit = {},
    onRemoveAll: () -> Unit = {},
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(text = "Erase Data", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
            top = 0.dp,
            bottom = bottomInset + dims.spacing.navBarContentBottomMargin
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(contentPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Position reporter
            Box(modifier = Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

            // Title
            Column(Modifier.fadeUpTransform(progress = fadeProgress)) {
                Text(
                    text = "Erase Data",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            Text(
                text = "Select what to remove. This action cannot be undone.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            Column {
                EraseOptionCard(
                    title = "Remove Active Payables",
                    subtitle = "Delete all payables currently marked as Active.",
                    isFirst = true,
                    isLast = false,
                    onClick = onRemoveActive
                )
                EraseOptionCard(
                    title = "Remove Finished Payables",
                    subtitle = "Delete all payables marked as Finished/Completed.",
                    isFirst = false,
                    isLast = false,
                    onClick = onRemoveFinished
                )
                EraseOptionCard(
                    title = "Remove Paused Payables",
                    subtitle = "Delete all payables currently paused.",
                    isFirst = false,
                    isLast = false,
                    onClick = onRemovePaused
                )
                EraseOptionCard(
                    title = "Remove payment methods",
                    subtitle = "Delete all saved cards, banks, and other payment methods.",
                    isFirst = false,
                    isLast = false,
                    onClick = onRemovePaymentMethods
                )
                EraseOptionCard(
                    title = "Remove custom categories",
                    subtitle = "Delete categories you created manually.",
                    isFirst = false,
                    isLast = false,
                    onClick = onRemoveCustomCategories
                )
                EraseOptionCard(
                    title = "Remove custom icons",
                    subtitle = "Delete any custom icons you've added.",
                    isFirst = false,
                    isLast = false,
                    onClick = onRemoveCustomIcons
                )
                EraseOptionCard(
                    title = "Remove All Data",
                    subtitle = "Delete EVERYTHING: payables, methods, categories, icons (irreversible).",
                    isFirst = false,
                    isLast = true,
                    onClick = onRemoveAll,
                    emphasize = true
                )
            }
        }
    }
}

// SectionHeader removed; inlined constant header to avoid lint warning

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EraseOptionCard(
    title: String,
    subtitle: String,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit,
    emphasize: Boolean = false
) {
    val interaction = remember { MutableInteractionSource() }
    val corners = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    val container = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
    val titleColor = if (emphasize) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
    val badgeBg = MaterialTheme.colorScheme.error.copy(alpha = 0.25f)
    val badgeTint = MaterialTheme.colorScheme.error

    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interaction),
        shape = corners,
        colors = CardDefaults.cardColors(
            containerColor = container
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interaction
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card)
                .heightIn(min = 84.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Leading badge
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(badgeBg, RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) { Icon(Icons.Filled.Delete, contentDescription = null, tint = badgeTint) }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = titleColor,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun EraseDataScreenPreview() {
    AppTheme {
        EraseDataScreen()
    }
}



