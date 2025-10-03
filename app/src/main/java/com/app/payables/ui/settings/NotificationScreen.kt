package com.app.payables.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Notifications
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
import com.app.payables.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationScreen(
	onBack: () -> Unit = {}
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
				title = { Text(text = "Notifications", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
					text = "Notifications",
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
				text = "Enable app push notifications to receive Payment Reminders on your phone before bills are due.",
				style = MaterialTheme.typography.bodyLarge,
				color = MaterialTheme.colorScheme.onSurfaceVariant,
				modifier = Modifier.padding(bottom = dims.spacing.section)
			)

			SectionHeader()
			NotificationToggleCard()
		}
	}
}

@Composable
private fun SectionHeader() {
	Text(
		text = "Push notifications",
		style = LocalDashboardTheme.current.sectionHeaderTextStyle,
		color = MaterialTheme.colorScheme.onSurface,
		modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
	)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NotificationToggleCard() {
	var pushEnabled by remember { mutableStateOf(false) }
	val dims = LocalAppDimensions.current
	val interaction = remember { MutableInteractionSource() }
	val corners = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 24.dp, bottomEnd = 24.dp)

	Card(
		onClick = { pushEnabled = !pushEnabled },
		modifier = Modifier
			.fillMaxWidth()
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
				.padding(dims.spacing.card),
			verticalAlignment = Alignment.CenterVertically
		) {
			// Leading icon badge
			Box(
				modifier = Modifier
					.size(44.dp)
					.background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
				contentAlignment = Alignment.Center
			) {
				Icon(Icons.Filled.Notifications, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
			}

			Column(
				modifier = Modifier
					.weight(1f)
					.padding(start = 16.dp)
			) {
				Text(text = "Push Notifications", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
				Text(
					text = "Payment Reminders will be sent as system notifications.",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp)
				)
			}

			Switch(checked = pushEnabled, onCheckedChange = { pushEnabled = it })
		}
	}
}

@Preview(showBackground = true)
@Composable
fun NotificationScreenPreview() {
	AppTheme {
		NotificationScreen()
	}
}



