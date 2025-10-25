package com.app.payables.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Checklist
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
import com.app.payables.PayablesApplication
import com.app.payables.theme.*
import com.app.payables.ui.PayableItemData
import com.app.payables.util.SettingsManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import com.app.payables.util.AppNotificationManager
import androidx.compose.ui.graphics.Color
import java.util.Locale
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import com.app.payables.util.AlarmScheduler
import android.util.Log
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
	val app = context.applicationContext as PayablesApplication
	val payableRepository = app.payableRepository
	val settingsManager = remember { SettingsManager(context) }

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


	val payables by payableRepository.getActivePayables().collectAsState(initial = emptyList())
	var showSelectPayablesDialog by remember { mutableStateOf(false) }

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
				text = "Enable app push notifications to receive Payment Reminders on your phone before bills are due.",
				style = MaterialTheme.typography.bodyLarge,
				color = MaterialTheme.colorScheme.onSurfaceVariant,
				modifier = Modifier.padding(bottom = dims.spacing.section)
			)

			SectionHeader("Push notifications")
			NotificationToggleCard()

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
				}
			)
			SelectPayablesCard(
				onClick = { showSelectPayablesDialog = true }
			)

			Spacer(modifier = Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
		}
	}

	if (showSelectPayablesDialog) {
		SelectPayablesDialog(
			payables = payables,
			onDismiss = { showSelectPayablesDialog = false },
			settingsManager = settingsManager
		)
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
private fun NotificationToggleCard() {
	val context = LocalContext.current
	val notificationManager = remember { AppNotificationManager(context) }
	var pushEnabled by remember { mutableStateOf(notificationManager.hasNotificationPermission()) }
	val dims = LocalAppDimensions.current
	val interaction = remember { MutableInteractionSource() }
	val corners = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
	val permissionLauncher = rememberLauncherForActivityResult(
		contract = ActivityResultContracts.RequestPermission()
	) { isGranted ->
		if (isGranted) {
			pushEnabled = true
			notificationManager.createNotificationChannel()
		} else {
			pushEnabled = false
		}
	}

	Card(
		onClick = {
			if (!pushEnabled) {
				if (notificationManager.hasNotificationPermission()) {
					pushEnabled = true
				} else {
					notificationManager.requestNotificationPermission(permissionLauncher)
				}
			} else {
				pushEnabled = false
			}
		},
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
						} else {
							notificationManager.requestNotificationPermission(permissionLauncher)
						}
					} else {
						pushEnabled = false
					}
				}
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
	val shape = RoundedCornerShape(dashboardTheme.groupInnerCornerRadius)

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
private fun SelectPayablesCard(
	onClick: () -> Unit
) {
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
		onClick = onClick,
		modifier = Modifier
			.fillMaxWidth()
			.padding(bottom = 0.dp)
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
					.background(MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
				contentAlignment = Alignment.Center
			) {
				Icon(Icons.Filled.Checklist, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
			}

			Column(
				modifier = Modifier
					.weight(1f)
					.padding(start = 16.dp)
			) {
				Text(text = "Select Payables", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
				Text(
					text = "Choose which payables send reminders",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp),
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
			}

			Icon(
				Icons.AutoMirrored.Filled.KeyboardArrowRight,
				contentDescription = "Select payables",
				tint = MaterialTheme.colorScheme.onSurfaceVariant
			)
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SelectPayablesDialog(
	payables: List<PayableItemData>,
	onDismiss: () -> Unit,
	settingsManager: SettingsManager
) {
	val context = LocalContext.current
	val app = context.applicationContext as PayablesApplication
	val alarmScheduler = remember { AlarmScheduler(context) }
	val coroutineScope = rememberCoroutineScope()
	
	val initialEnabledIds = if (settingsManager.hasNotificationSetting()) {
		settingsManager.getEnabledPayableIds()
	} else {
		// Default to all enabled if no setting is saved
		payables.map { it.id }.toSet()
	}
	
	val enabledPayableIds = remember {
		mutableStateOf(initialEnabledIds)
	}

	Dialog(onDismissRequest = onDismiss) {
		Surface(
			shape = MaterialTheme.shapes.extraLarge,
			tonalElevation = 6.dp,
		) {
			Column(modifier = Modifier.padding(24.dp)) {
				Text(
					text = "Select Payables",
					style = MaterialTheme.typography.headlineSmall
				)
				Text(
					text = "Choose which payables will send reminders.",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant,
					modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
				)

				LazyColumn(modifier = Modifier.weight(1f)) {
					items(payables) { payable ->
						val isEnabled = payable.id in enabledPayableIds.value
						Row(
							modifier = Modifier
								.fillMaxWidth()
								.background(
									color = if (isEnabled) MaterialTheme.colorScheme.primary.copy(alpha = 0.1f) else Color.Transparent,
									shape = RoundedCornerShape(8.dp)
								)
								.clickable {
									val currentIds = enabledPayableIds.value.toMutableSet()
									if (payable.id in currentIds) {
										currentIds.remove(payable.id)
									} else {
										currentIds.add(payable.id)
									}
									enabledPayableIds.value = currentIds
								}
								.padding(vertical = 8.dp, horizontal = 12.dp),
							verticalAlignment = Alignment.CenterVertically
						) {
							Column(
								modifier = Modifier.weight(1f)
							) {
								Text(
									text = payable.name,
									style = MaterialTheme.typography.titleMedium
								)
								if (payable.planType.isNotBlank()) {
									Text(
										text = payable.planType,
										style = MaterialTheme.typography.bodyMedium,
										color = MaterialTheme.colorScheme.onSurfaceVariant
									)
								}
							}
							Switch(
								checked = isEnabled,
								onCheckedChange = { isChecked ->
									val currentIds = enabledPayableIds.value.toMutableSet()
									if (isChecked) {
										currentIds.add(payable.id)
									} else {
										currentIds.remove(payable.id)
									}
									enabledPayableIds.value = currentIds
								}
							)
						}
						Spacer(modifier = Modifier.height(4.dp))
					}
				}

				Row(
					modifier = Modifier
						.fillMaxWidth()
						.padding(top = 24.dp),
					horizontalArrangement = Arrangement.End
				) {
					TextButton(onClick = onDismiss) {
						Text("Cancel")
					}
					Spacer(modifier = Modifier.width(8.dp))
					TextButton(
						onClick = {
							// Save enabled payable IDs
							settingsManager.setEnabledPayableIds(enabledPayableIds.value)
							
							// Handle alarm cancellation and scheduling
							coroutineScope.launch(Dispatchers.IO) {
								try {
									// Cancel alarms for payables that were disabled
									val disabledPayables = initialEnabledIds - enabledPayableIds.value
									disabledPayables.forEach { payableId ->
										alarmScheduler.cancelAlarm(payableId)
									}
									
									// Schedule alarms for newly enabled payables
									val newlyEnabledPayables = enabledPayableIds.value - initialEnabledIds
									newlyEnabledPayables.forEach { payableId ->
										app.payableRepository.getPayableById(payableId)?.let { payable ->
											alarmScheduler.rescheduleNextAlarm(payable, settingsManager)
										}
									}
								} catch (e: Exception) {
									Log.e("SelectPayablesDialog", "Error updating alarms", e)
								}
							}
							
							onDismiss()
						}
					) {
						Text("Confirm")
					}
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



