package com.app.payables.ui

import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.viewinterop.AndroidView
import android.widget.ImageView
import androidx.compose.ui.platform.LocalContext
import com.app.payables.theme.AppTheme
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.computeTopBarAlphaFromContentFade
import com.app.payables.theme.fadeUpTransform
import com.app.payables.theme.rememberFadeToTopBarProgress
import com.app.payables.theme.windowYReporter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(
    onBack: () -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    val versionName = remember {
        try {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: ""
        } catch (_: Exception) { "" }
    }
    val appIconDrawable = remember {
        try { context.packageManager.getApplicationIcon(context.packageName) } catch (_: Exception) { null }
    }
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
                title = { Text(text = "About", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
            bottom = bottomInset + dims.spacing.navBarContentBottomMargin
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(contentPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Anchor for fade to top bar
            Box(modifier = Modifier.windowYReporter { currentY ->
                if (titleInitialY == null) titleInitialY = currentY
                titleWindowY = currentY
            })

            // Title
            Column(modifier = Modifier.fadeUpTransform(progress = fadeProgress)) {
                Text(
                    text = "About Payables",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            // App identity (no card background)
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = dims.spacing.section + 30.dp)
            ) {
                if (appIconDrawable != null) {
                    AndroidView(
                        factory = { ctx -> ImageView(ctx).apply { setImageDrawable(appIconDrawable) } },
                        update = { it.setImageDrawable(appIconDrawable) },
                        modifier = Modifier.size(88.dp)
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(88.dp)
                    )
                }
                Spacer(Modifier.height(12.dp))
                Text("Payables", style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(4.dp))
                Text("Version $versionName", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            // App description (no section label)
            Text(
                text = "Payables helps you track and manage recurring payments so you never miss a due date. Customize widgets, set reminders, and stay on top of your subscriptions.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = dims.spacing.section + 8.dp)
            )

            Text(
                text = "Key features:",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader),
                fontWeight = FontWeight.Normal
            )
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                FeatureRow("Track upcoming and recurring payments")
                FeatureRow("Customizable home widgets")
                FeatureRow("Currency selection and search")
                FeatureRow("Light, Dark, and System themes")
                FeatureRow("Backup and restore your data")
            }
            Spacer(Modifier.height(dims.spacing.section + 20.dp))

            Text(
                text = "Developer & Privacy",
                style = LocalDashboardTheme.current.sectionHeaderTextStyle,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
            )
            Column {
                StackedInfoCard(
                    isFirst = true,
                    isLast = false,
                    content = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Info, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text("Developer", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                                Spacer(Modifier.height(4.dp))
                                Text("Jhay EL", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                )
                StackedInfoCard(
                    isFirst = false,
                    isLast = true,
                    content = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text("Privacy", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                                Spacer(Modifier.height(4.dp))
                                Text("We respect your privacy. Data stays on-device unless you choose to export.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StackedInfoCard(
    isFirst: Boolean,
    isLast: Boolean,
    content: @Composable RowScope.() -> Unit
) {
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
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(modifier = Modifier.padding(LocalAppDimensions.current.spacing.card), verticalAlignment = Alignment.CenterVertically) {
            content()
        }
    }
}

@Composable
private fun FeatureRow(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        val bulletStyle = MaterialTheme.typography.bodyLarge.copy(
            fontSize = MaterialTheme.typography.bodyLarge.fontSize
        )
        Text("\u2022", style = bulletStyle, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.width(10.dp))
        Text(text = text, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Normal)
    }
}

@Preview(showBackground = true)
@Composable
private fun AboutScreenPreview() {
    AppTheme {
        AboutScreen()
    }
}



