@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.pressableCard
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.window.Dialog
import com.app.payables.theme.*
import com.app.payables.util.SettingsManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import com.app.payables.util.AppNotificationManager
import java.util.Locale
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import com.app.payables.PayablesApplication
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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
	var showTimePicker by remember { mutableStateOf(false) }

	val context = LocalContext.current
	val settingsManager = remember { SettingsManager(context) }
	val scope = rememberCoroutineScope()
	val app = context.applicationContext as PayablesApplication

	val (hour, minute) = settingsManager.getNotificationTime()
	val timePickerState = rememberTimePickerState(initialHour = hour, initialMinute = minute, is24Hour = false)
	val amPm = if (hour < 12) "AM" else "PM"
	val displayHour = when {
		hour == 0 -> 12
		hour > 12 -> hour - 12
		else -> hour
	}
	var selectedTime by remember { mutableStateOf(String.format(Locale.US, "%d:%02d %s", displayHour, minute, amPm)) }
	var reminderPreference by remember { mutableIntStateOf(settingsManager.getReminderPreference()) }

	if (showTimePicker) {
		TimePickerDialog(
			onCancel = { showTimePicker = false },
			onConfirm = {
				val newHour = timePickerState.hour
				val newMinute = timePickerState.minute
				settingsManager.setNotificationTime(newHour, newMinute)

				val newAmPm = if (newHour < 12) "AM" else "PM"
				val newDisplayHour = when {
					newHour == 0 -> 12
					newHour > 12 -> newHour - 12
					else -> newHour
				}
				selectedTime = String.format(Locale.US, "%d:%02d %s", newDisplayHour, newMinute, newAmPm)
				showTimePicker = false
				
				// Reschedule alarms with new time
				scope.launch(Dispatchers.IO) {
					app.payableRepository.rescheduleAllAlarms()
				}
			},
			timePickerState = timePickerState
		)
	}

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

		Column(
			modifier = Modifier
				.fillMaxSize()
				.padding(paddingValues)
				.verticalScroll(rememberScrollState())
				.padding(horizontal = dims.spacing.md)
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
			text = "Enable push notifications to receive reminders for all active payables before they're due.",
				style = MaterialTheme.typography.bodyLarge,
				color = MaterialTheme.colorScheme.onSurfaceVariant,
				modifier = Modifier.padding(bottom = dims.spacing.section)
			)

		SectionHeader("Push notifications")
		NotificationSettingsGroup()
		
		// Lockscreen note
		Text(
			text = "Note: Make sure \"Sensitive notifications\" is enabled in your device's lockscreen settings for notifications to appear when locked.",
			style = MaterialTheme.typography.bodySmall,
			color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
			modifier = Modifier.padding(top = dims.spacing.sm, start = dims.spacing.xs, end = dims.spacing.xs)
		)

		Spacer(modifier = Modifier.height(dims.spacing.section))

		SectionHeader("Alerts")
		AlertTimeCard(
			selectedTime = selectedTime,
			onClick = { showTimePicker = true }
		)
		ReminderPreferenceCard(
			selectedDays = reminderPreference,
			onSelect = { days ->
				reminderPreference = days
				settingsManager.setReminderPreference(days)
				
				// Reschedule alarms with new reminder preference
				scope.launch(Dispatchers.IO) {
					app.payableRepository.rescheduleAllAlarms()
				}
			}
		)

		Spacer(modifier = Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
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
private fun NotificationSettingsGroup() {
	val context = LocalContext.current
	val settingsManager = remember { SettingsManager(context) }
	val notificationManager = remember { AppNotificationManager(context) }
	
	// Initialize from saved state AND permission status
	var pushEnabled by remember { 
		mutableStateOf(
			settingsManager.isPushNotificationsEnabled() && 
			notificationManager.hasNotificationPermission()
		)
	}
	var showOnLockscreen by remember { mutableStateOf(settingsManager.getShowOnLockscreen()) }
	
	val dims = LocalAppDimensions.current
	val dashboardTheme = LocalDashboardTheme.current
	val permissionLauncher = rememberLauncherForActivityResult(
		contract = ActivityResultContracts.RequestPermission()
	) { isGranted ->
		if (isGranted) {
			pushEnabled = true
			settingsManager.setPushNotificationsEnabled(true)
			notificationManager.createNotificationChannel()
		} else {
			pushEnabled = false
			settingsManager.setPushNotificationsEnabled(false)
		}
	}

	// Top card - Push Notifications
	Card(
		onClick = {
			if (!pushEnabled) {
				if (notificationManager.hasNotificationPermission()) {
					pushEnabled = true
					settingsManager.setPushNotificationsEnabled(true)
				} else {
					notificationManager.requestNotificationPermission(permissionLauncher)
				}
			} else {
				pushEnabled = false
				settingsManager.setPushNotificationsEnabled(false)
			}
		},
		modifier = Modifier
			.fillMaxWidth()
			.pressableCard(interactionSource = remember { MutableInteractionSource() }),
		shape = RoundedCornerShape(
			topStart = dashboardTheme.groupTopCornerRadius,
			topEnd = dashboardTheme.groupTopCornerRadius,
			bottomStart = dashboardTheme.groupInnerCornerRadius,
			bottomEnd = dashboardTheme.groupInnerCornerRadius
		),
		colors = CardDefaults.cardColors(
			containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
		),
		elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
		interactionSource = remember { MutableInteractionSource() }
	) {
		Row(
			modifier = Modifier
				.fillMaxWidth()
				.padding(dims.spacing.card),
			verticalAlignment = Alignment.CenterVertically
		) {
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
					modifier = Modifier.padding(top = 4.dp),
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
			}

			Switch(
				checked = pushEnabled,
				onCheckedChange = {
					if (it) {
						if (notificationManager.hasNotificationPermission()) {
							pushEnabled = true
							settingsManager.setPushNotificationsEnabled(true)
						} else {
							notificationManager.requestNotificationPermission(permissionLauncher)
						}
					} else {
						pushEnabled = false
						settingsManager.setPushNotificationsEnabled(false)
					}
				}
			)
		}
	}

	Spacer(modifier = Modifier.height(2.dp))

	// Bottom card - Show on lockscreen (disabled when push notifications are off)
	val lockscreenCardAlpha = if (pushEnabled) 1f else 0.5f
	
	Card(
		onClick = {
			if (pushEnabled) {
				showOnLockscreen = !showOnLockscreen
				settingsManager.setShowOnLockscreen(showOnLockscreen)
			}
		},
		enabled = pushEnabled,
		modifier = Modifier
			.fillMaxWidth()
			.pressableCard(interactionSource = remember { MutableInteractionSource() })
			.graphicsLayer(alpha = lockscreenCardAlpha),
		shape = RoundedCornerShape(
			topStart = dashboardTheme.groupInnerCornerRadius,
			topEnd = dashboardTheme.groupInnerCornerRadius,
			bottomStart = dashboardTheme.groupBottomCornerRadius,
			bottomEnd = dashboardTheme.groupBottomCornerRadius
		),
		colors = CardDefaults.cardColors(
			containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f),
			disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
		),
		elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
		interactionSource = remember { MutableInteractionSource() }
	) {
		Row(
			modifier = Modifier
				.fillMaxWidth()
				.padding(dims.spacing.card),
			verticalAlignment = Alignment.CenterVertically
		) {
			Box(
				modifier = Modifier
					.size(44.dp)
					.background(
						MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.35f),
						RoundedCornerShape(16.dp)
					),
				contentAlignment = Alignment.Center
			) {
				Icon(
					Icons.Filled.LockOpen,
					contentDescription = null,
					tint = MaterialTheme.colorScheme.secondary
				)
			}

			Column(
				modifier = Modifier
					.weight(1f)
					.padding(start = 16.dp)
			) {
				Text(
					text = "Show on lockscreen",
					style = MaterialTheme.typography.titleMedium,
					color = MaterialTheme.colorScheme.onSurface
				)
				Text(
					text = if (pushEnabled) "Display notifications on your lockscreen" 
					       else "Enable push notifications first",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp),
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
			}

			Switch(
				checked = showOnLockscreen,
				onCheckedChange = {
					if (pushEnabled) {
						showOnLockscreen = it
						settingsManager.setShowOnLockscreen(it)
					}
				},
				enabled = pushEnabled
			)
		}
	}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AlertTimeCard(
	selectedTime: String,
	onClick: () -> Unit
) {
	val dims = LocalAppDimensions.current
	val interaction = remember { MutableInteractionSource() }
	val dashboardTheme = LocalDashboardTheme.current
	val shape = RoundedCornerShape(
			topStart = dashboardTheme.groupTopCornerRadius,
			topEnd = dashboardTheme.groupTopCornerRadius,
			bottomStart = dashboardTheme.groupInnerCornerRadius,
			bottomEnd = dashboardTheme.groupInnerCornerRadius
		)

	Card(
		onClick = onClick,
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
			Box(
				modifier = Modifier
					.size(44.dp)
					.background(MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
				contentAlignment = Alignment.Center
			) {
				Icon(Icons.Filled.Schedule, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
			}

			Column(
				modifier = Modifier
					.weight(1f)
					.padding(start = 16.dp)
			) {
				Text(text = "Time", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
				Text(
					text = "Set time for reminders",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp),
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
			}

			Row(verticalAlignment = Alignment.CenterVertically) {
				Text(
					text = selectedTime,
					style = MaterialTheme.typography.bodyLarge,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(end = dims.spacing.sm)
				)
				Icon(
					Icons.AutoMirrored.Filled.KeyboardArrowRight,
					contentDescription = "Set time",
					tint = MaterialTheme.colorScheme.onSurfaceVariant
				)
			}
		}
	}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReminderPreferenceCard(
	selectedDays: Int,
	onSelect: (Int) -> Unit
) {
	val options = mapOf(
		"On due date" to 0,
		"1 day before" to 1,
		"2 days before" to 2,
		"3 days before" to 3,
		"1 week before" to 7
	)
	var expanded by remember { mutableStateOf(false) }
	val selectedText = options.entries.find { it.value == selectedDays }?.key ?: "On due date"

	val dims = LocalAppDimensions.current
	val interaction = remember { MutableInteractionSource() }
	val dashboardTheme = LocalDashboardTheme.current
	val shape = RoundedCornerShape(
		topStart = dashboardTheme.groupInnerCornerRadius,
		topEnd = dashboardTheme.groupInnerCornerRadius,
		bottomStart = dashboardTheme.groupBottomCornerRadius,
		bottomEnd = dashboardTheme.groupBottomCornerRadius
	)

	Card(
		onClick = { expanded = true },
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
				Text(text = "Remind me", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
				Text(
					text = "Set when you receive reminders",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp),
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
			}

			Box {
				Row(verticalAlignment = Alignment.CenterVertically) {
					Text(
						text = selectedText,
						style = MaterialTheme.typography.bodyLarge,
						color = MaterialTheme.colorScheme.onSurfaceVariant,
						modifier = Modifier.padding(end = dims.spacing.sm)
					)
					Icon(
						Icons.AutoMirrored.Filled.KeyboardArrowRight,
						contentDescription = "Set reminder preference",
						tint = MaterialTheme.colorScheme.onSurfaceVariant
					)
				}
				DropdownMenu(
					expanded = expanded,
					onDismissRequest = { expanded = false }
				) {
					options.forEach { (text, days) ->
						DropdownMenuItem(
							text = { Text(text) },
							onClick = {
								onSelect(days)
								expanded = false
							}
						)
					}
				}
			}
		}
	}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TimePickerDialog(
	onCancel: () -> Unit,
	onConfirm: () -> Unit,
	timePickerState: TimePickerState
) {
	Dialog(onDismissRequest = onCancel) {
		Surface(
			shape = MaterialTheme.shapes.extraLarge,
			tonalElevation = 6.dp,
			modifier = Modifier
				.width(IntrinsicSize.Min)
				.height(IntrinsicSize.Min)
				.background(
					shape = MaterialTheme.shapes.extraLarge,
					color = MaterialTheme.colorScheme.surface
				),
		) {
			Column(
				modifier = Modifier.padding(24.dp),
				horizontalAlignment = Alignment.CenterHorizontally
			) {
				Text(
					modifier = Modifier
						.fillMaxWidth()
						.padding(bottom = 20.dp),
					text = "Select Time",
					style = MaterialTheme.typography.labelLarge
				)
				TimePicker(state = timePickerState)
				Row(
					modifier = Modifier
						.height(40.dp)
						.fillMaxWidth()
				) {
					Spacer(modifier = Modifier.weight(1f))
					TextButton(onClick = onCancel) { Text("Cancel") }
					TextButton(onClick = onConfirm) { Text("OK") }
				}
			}
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



