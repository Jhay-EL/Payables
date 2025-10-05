package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.pressableCard
import com.app.payables.theme.windowYReporter
import com.app.payables.theme.rememberFadeToTopBarProgress
import com.app.payables.theme.computeTopBarAlphaFromContentFade
import com.app.payables.theme.fadeUpTransform
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import com.app.payables.theme.AppTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit = {},
    onOpenNotifications: () -> Unit = {},
    onOpenAppearance: () -> Unit = {},
    onOpenCurrency: () -> Unit = {},
    onOpenWidget: () -> Unit = {},
    onOpenBackup: () -> Unit = {},
    onOpenRestore: () -> Unit = {},
    onOpenAbout: () -> Unit = {},
    onOpenEraseData: () -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(text = "Settings", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
        val listState = rememberLazyListState()
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = contentPadding,
            state = listState
        ) {
            // General section
            item {
                // Invisible anchor to track Y during scroll
                Box(modifier = Modifier.windowYReporter { currentY ->
                    if (titleInitialY == null) titleInitialY = currentY
                    titleWindowY = currentY
                })

                // Large screen title with fade/scale transform
                Column(
                    modifier = Modifier
                        .fadeUpTransform(progress = fadeProgress)
                ) {
                    Text(
                        text = "Settings",
                        style = LocalDashboardTheme.current.titleTextStyle,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                        modifier = Modifier.padding(
                            top = dims.titleDimensions.payablesTitleTopPadding,
                            bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                        )
                    )
                }

                SectionHeader(text = "General")
                SettingsItemStack {
                    SettingsCard(
                        title = "Notifications",
                        subtitle = "Enable/Disable app notifications",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.Notifications, null, tint = MaterialTheme.colorScheme.primary) } },
                        trailing = {},
                        isFirst = true,
                        isLast = false,
                        onClick = onOpenNotifications
                    )
                    SettingsCard(
                        title = "Appearance",
                        subtitle = "Change app color appearance",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.Palette, null, tint = MaterialTheme.colorScheme.tertiary) } },
                        trailing = {},
                        isFirst = false,
                        isLast = false,
                        onClick = onOpenAppearance
                    )
                    SettingsCard(
                        title = "Currency",
                        subtitle = "Change default app currency",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.AttachMoney, null, tint = MaterialTheme.colorScheme.secondary) } },
                        trailing = {},
                        isFirst = false,
                        isLast = false,
                        onClick = onOpenCurrency
                    )
                    SettingsCard(
                        title = "Widget",
                        subtitle = "Select what payables will display on\nhome screen",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.GridView, null, tint = MaterialTheme.colorScheme.primary) } },
                        trailing = {},
                        isFirst = false,
                        isLast = true,
                        onClick = onOpenWidget
                    )
            }
            }

            item { Spacer(modifier = Modifier.height(dims.spacing.section)) }

            // Data Management section
            item {
                SectionHeader(text = "Data Management")
                SettingsItemStack {
                    SettingsCard(
                        title = "Backup",
                        subtitle = "Backup all your payables",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.CloudUpload, null, tint = MaterialTheme.colorScheme.primary) } },
                        trailing = {},
                        isFirst = true,
                        isLast = false,
                        onClick = onOpenBackup
                    )
                    SettingsCard(
                        title = "Restore",
                        subtitle = "Restore all your payables",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.Restore, null, tint = MaterialTheme.colorScheme.tertiary) } },
                        trailing = {},
                        isFirst = false,
                        isLast = true,
                        onClick = onOpenRestore
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(dims.spacing.section)) }

            // Support & Info
            item {
                SectionHeader(text = "Support & Info")
                SettingsItemStack {
                    SettingsCard(
                        title = "About Payables",
                        subtitle = "Information and privacy policy",
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.35f)) { Icon(Icons.Filled.Info, null, tint = MaterialTheme.colorScheme.secondary) } },
                        trailing = {},
                        isFirst = true,
                        isLast = false,
                        onClick = onOpenAbout
                    )
                    SettingsCard(
                        title = "Erase data",
                        subtitle = "Remove all data from the app",
                        titleColor = MaterialTheme.colorScheme.error,
                        leading = { BadgeIcon(background = MaterialTheme.colorScheme.error.copy(alpha = 0.25f)) { Icon(Icons.Filled.Delete, null, tint = MaterialTheme.colorScheme.error) } },
                        trailing = {},
                        isFirst = false,
                        isLast = true,
                        onClick = onOpenEraseData
                    )
                }
            }
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
private fun SettingsCard(
    title: String,
    subtitle: String,
    leading: @Composable () -> Unit,
    trailing: @Composable () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
    titleColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit,
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
            leading()
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(text = title, style = MaterialTheme.typography.titleMedium, color = titleColor)
                Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 4.dp), maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            trailing()
        }
    }
}

@Composable
private fun BadgeIcon(
    background: Color,
    content: @Composable () -> Unit
) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .background(background, RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center
    ) { content() }
}
@Composable
private fun SettingsItemStack(content: @Composable ColumnScope.() -> Unit) {
    Column { content() }
}

@Preview(showBackground = true)
@Composable
fun SettingsScreenPreview() {
    AppTheme {
        SettingsScreen()
    }
}