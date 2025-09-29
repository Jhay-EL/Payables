package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.GridOn
import androidx.compose.material.icons.filled.PictureAsPdf
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
fun BackupScreen(
    onBack: () -> Unit = {},
    onExcelExport: () -> Unit = {},
    onJsonExport: () -> Unit = {},
    onPdfExport: () -> Unit = {}
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
                title = { Text(text = "Backup", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
            top = dims.spacing.md,
            bottom = bottomInset + dims.spacing.navBarContentBottomMargin
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(contentPadding)
        ) {
            // Invisible anchor to track Y during scroll
            Box(modifier = Modifier.windowYReporter { currentY ->
                if (titleInitialY == null) titleInitialY = currentY
                titleWindowY = currentY
            })

            // Large screen title with fade/scale transform
            Column(
                modifier = Modifier.fadeUpTransform(progress = fadeProgress)
            ) {
                Text(
                    text = "Backup",
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
                text = "Export your payables data. Choose Excel, JSON, or PDF.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            SectionHeader()

            ExportOptionCard(
                title = "Excel Export",
                subtitle = "Download an .xlsx file",
                icon = {
                    Icon(Icons.Filled.GridOn, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                },
                onClick = onExcelExport,
                isFirst = true,
                isLast = false
            )
            ExportOptionCard(
                title = "JSON Export",
                subtitle = "Download a .json file",
                icon = {
                    Icon(Icons.Filled.Code, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                },
                onClick = onJsonExport,
                isFirst = false,
                isLast = false
            )
            ExportOptionCard(
                title = "PDF Export",
                subtitle = "Download a .pdf file",
                icon = {
                    Icon(Icons.Filled.PictureAsPdf, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                },
                onClick = onPdfExport,
                isFirst = false,
                isLast = true
            )
        }
    }
}

@Composable
private fun SectionHeader() {
    Text(
        text = "Export options",
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ExportOptionCard(
    title: String,
    subtitle: String,
    icon: @Composable () -> Unit,
    onClick: () -> Unit,
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
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interaction),
        shape = corners,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
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
            // Leading icon badge
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) { icon() }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun BackupScreenPreview() {
    AppTheme {
        BackupScreen()
    }
}



