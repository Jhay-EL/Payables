@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Brightness3
import androidx.compose.material.icons.filled.SettingsBrightness
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.computeTopBarAlphaFromContentFade
import com.app.payables.theme.fadeUpTransform
import com.app.payables.theme.pressableCard
import com.app.payables.theme.rememberFadeToTopBarProgress
import com.app.payables.theme.windowYReporter
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import com.app.payables.theme.AppTheme

enum class AppThemeChoice { Light, Dark, System }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppearanceScreen(
    onBack: () -> Unit = {},
    selectedTheme: AppThemeChoice = AppThemeChoice.System,
    onSelectTheme: (AppThemeChoice) -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fadeProgress = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fadeProgress, appearAfterFraction = 0.9f)
    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Selection is controlled by caller

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(text = "Appearance", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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

            // Hero title
            Column(
                modifier = Modifier.fadeUpTransform(progress = fadeProgress)
            ) {
                Text(
                    text = "Appearance",
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
                text = "Choose how the app looks. You can use Light, Dark, or follow System settings.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            SectionHeader()

            ThemeOptionCard(
                title = "Light Mode",
                subtitle = "Use a light appearance",
                icon = { Icon(Icons.Filled.LightMode, null, tint = MaterialTheme.colorScheme.primary) },
                selected = selectedTheme == AppThemeChoice.Light,
                onSelect = { onSelectTheme(AppThemeChoice.Light) },
                isFirst = true,
                isLast = false
            )
            ThemeOptionCard(
                title = "Dark Mode",
                subtitle = "Use a dark appearance",
                icon = { Icon(Icons.Filled.Brightness3, null, tint = MaterialTheme.colorScheme.tertiary) },
                selected = selectedTheme == AppThemeChoice.Dark,
                onSelect = { onSelectTheme(AppThemeChoice.Dark) },
                isFirst = false,
                isLast = false
            )
            ThemeOptionCard(
                title = "System",
                subtitle = "Match your device setting",
                icon = { Icon(Icons.Filled.SettingsBrightness, null, tint = MaterialTheme.colorScheme.secondary) },
                selected = selectedTheme == AppThemeChoice.System,
                onSelect = { onSelectTheme(AppThemeChoice.System) },
                isFirst = false,
                isLast = true
            )
        }
    }
}

@Composable
private fun SectionHeader() {
    Text(
        text = "Theme",
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ThemeOptionCard(
    title: String,
    subtitle: String,
    icon: @Composable () -> Unit,
    selected: Boolean,
    onSelect: () -> Unit,
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
        onClick = onSelect,
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
            // Leading badge
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

            RadioButton(selected = selected, onClick = onSelect)
        }
    }
}

@Preview(showBackground = true)
@Composable
fun AppearanceScreenPreview() {
    AppTheme {
        AppearanceScreen()
    }
}



