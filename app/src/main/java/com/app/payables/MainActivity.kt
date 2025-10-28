package com.app.payables
import com.app.payables.ui.settings.AboutScreen
import android.app.AlarmManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.mutableStateListOf
import com.app.payables.theme.AppTheme
import com.app.payables.ui.DashboardScreen
import com.app.payables.ui.AddCategoryScreen
import com.app.payables.ui.SettingsScreen
import com.app.payables.ui.settings.NotificationScreen
import com.app.payables.ui.settings.AppearanceScreen
import com.app.payables.ui.settings.AppThemeChoice
import com.app.payables.ui.settings.CurrencyScreen
import com.app.payables.ui.settings.WidgetScreen
import com.app.payables.ui.settings.BackupScreen
import com.app.payables.ui.settings.RestoreScreen
import com.app.payables.ui.settings.EraseDataScreen
import com.app.payables.ui.CustomColorScreen
import com.app.payables.ui.CustomIconsScreen
import androidx.compose.animation.AnimatedContent
import com.app.payables.theme.AppTransitions
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.launch
import com.app.payables.ui.InsightsScreen
import com.app.payables.util.AppNotificationManager
import com.app.payables.util.SettingsManager

class MainActivity : ComponentActivity() {
    
    private var showAlarmPermDialog by mutableStateOf(false)
    private var showNotificationPermDialog by mutableStateOf(false)
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Request permissions on first launch
        requestInitialPermissionsIfNeeded()

        setContent {
            var themeChoice by remember { mutableStateOf(AppThemeChoice.System) }
            val useDarkTheme = when (themeChoice) {
                AppThemeChoice.Light -> false
                AppThemeChoice.Dark -> true
                AppThemeChoice.System -> isSystemInDarkTheme()
            }

            AppTheme(darkTheme = useDarkTheme) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val activity = this@MainActivity
                    val backStack = remember { mutableStateListOf(AppRoute.Dashboard) }
                    var showExitDialog by remember { mutableStateOf(false) }
                    
                    // Get repository and coroutine scope for database operations
                    val repository = (applicationContext as PayablesApplication).categoryRepository
                    val coroutineScope = rememberCoroutineScope()

                    fun navigateTo(route: AppRoute) {
                        if (backStack.last() != route) backStack.add(route)
                    }
                    fun back() {
                        if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) else showExitDialog = true
                    }

                    val currentRoute = backStack.last()
                    var customColorTarget by remember { mutableStateOf<CustomColorTarget?>(null) }
                    var widgetBackgroundColor by remember { mutableStateOf<Color?>(null) }
                    var widgetTextColor by remember { mutableStateOf<Color?>(null) }

                    val saveableStateHolder = rememberSaveableStateHolder()

                    BackHandler(enabled = backStack.size > 1) {
                        back()
                    }

                    AnimatedContent(
                        targetState = currentRoute,
                        transitionSpec = AppTransitions.materialSharedAxisHorizontal(
                            isForward = { initial, target -> routeDepth(target) > routeDepth(initial) },
                            durationMillis = 300,  // Increased for more visible slide
                            fadeDurationMillis = 150,  // Increased for smoother fade
                            distanceFraction = 0.25f,  // Increased for more pronounced slide
                            clip = true
                        ),
                        contentKey = { it.ordinal },
                        modifier = Modifier.fillMaxSize()
                    ) { route ->
                        saveableStateHolder.SaveableStateProvider(route) {
                            when (route) {
                            AppRoute.Dashboard ->
                                DashboardScreen(
                                    onOpenSettings = { navigateTo(AppRoute.Settings) },
                                    onOpenAddCategory = {
                                        backStack.add(AppRoute.AddCategory)
                                    },
                                    onOpenInsights = { navigateTo(AppRoute.Insights) }
                                )
                            AppRoute.Settings ->
                                SettingsScreen(
                                    onBack = { back() },
                                    onOpenNotifications = { navigateTo(AppRoute.Notifications) },
                                    onOpenAppearance = { navigateTo(AppRoute.Appearance) },
                                    onOpenCurrency = { navigateTo(AppRoute.Currency) },
                                    onOpenWidget = { navigateTo(AppRoute.Widget) },
                                    onOpenBackup = { navigateTo(AppRoute.Backup) },
                                    onOpenRestore = { navigateTo(AppRoute.Restore) },
                                    onOpenAbout = { navigateTo(AppRoute.About) },
                                    onOpenEraseData = { navigateTo(AppRoute.EraseData) }
                                )
                            AppRoute.Backup ->
                                BackupScreen(
                                    onBack = { back() }
                                )
                            AppRoute.Restore ->
                                RestoreScreen(
                                    onBack = { back() }
                                )
                            AppRoute.About ->
                                AboutScreen(
                                    onBack = { back() }
                                )
                            AppRoute.EraseData ->
                                EraseDataScreen(
                                    onBack = { back() }
                                )
                            AppRoute.Notifications ->
                                NotificationScreen(
                                    onBack = { back() }
                                )
                            AppRoute.Appearance ->
                                AppearanceScreen(
                                    onBack = { back() },
                                    selectedTheme = themeChoice,
                                    onSelectTheme = { choice -> themeChoice = choice }
                                )
                            AppRoute.Currency ->
                                CurrencyScreen(
                                    onBack = { back() }
                                )
                            AppRoute.Widget ->
                                WidgetScreen(
                                    onBack = { back() },
                                    onOpenCustomColor = {
                                        customColorTarget = CustomColorTarget.Background
                                        navigateTo(AppRoute.CustomColor)
                                    },
                                    onOpenCustomTextColor = {
                                        customColorTarget = CustomColorTarget.Text
                                        navigateTo(AppRoute.CustomColor)
                                    },
                                    backgroundColor = widgetBackgroundColor ?: MaterialTheme.colorScheme.primaryContainer,
                                    onBackgroundColorChange = { c -> widgetBackgroundColor = c },
                                    textColor = widgetTextColor ?: MaterialTheme.colorScheme.onSurface,
                                    onTextColorChange = { c -> widgetTextColor = c }
                                )
                            AppRoute.CustomColor ->
                                CustomColorScreen(
                                    onBack = { back() },
                                    onPick = { c ->
                                        when (customColorTarget) {
                                            CustomColorTarget.Background -> widgetBackgroundColor = c
                                            CustomColorTarget.Text -> widgetTextColor = c
                                            null -> {}
                                        }
                                    }
                                )
                            AppRoute.AddCategory ->
                                AddCategoryScreen(
                                    onBack = { back() },
                                    onSave = { categoryData ->
                                        coroutineScope.launch {
                                            repository.insertCategory(categoryData)
                                            back()
                                        }
                                    },
                                    onOpenCustomIcons = { navigateTo(AppRoute.CustomIcons) }
                                )
                            AppRoute.CustomIcons ->
                                CustomIconsScreen(
                                    onBack = { back() }
                                )
                            AppRoute.Insights ->
                                InsightsScreen(
                                    onBack = { back() }
                                )
                            }
                        }
                    }

                    if (currentRoute == AppRoute.Dashboard && showExitDialog) {
                        AlertDialog(
                            onDismissRequest = { showExitDialog = false },
                            confirmButton = {
                                TextButton(onClick = { showExitDialog = false; activity.finish() }) { Text("Exit") }
                            },
                            dismissButton = {
                                TextButton(onClick = { showExitDialog = false }) { Text("Cancel") }
                            },
                            title = { Text("Exit app?") },
                            text = { Text("Are you sure you want to exit?") }
                        )
                    }
                    
                    // Notification permission dialog
                    if (showNotificationPermDialog) {
                        val permissionLauncher = rememberLauncherForActivityResult(
                            contract = ActivityResultContracts.RequestPermission()
                        ) { isGranted ->
                            showNotificationPermDialog = false
                            val settingsManager = SettingsManager(activity)
                            if (isGranted) {
                                onPermissionsGranted(settingsManager)
                            }
                            // After handling notification permission, check alarm permission
                            checkAlarmPermission()
                        }
                        
                        LaunchedEffect(Unit) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                permissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                showNotificationPermDialog = false
                                checkAlarmPermission()
                            }
                        }
                    }
                    
                    // Alarm permission dialog
                    if (showAlarmPermDialog) {
                        AlertDialog(
                            onDismissRequest = { showAlarmPermDialog = false },
                            confirmButton = {
                                TextButton(onClick = { 
                                    showAlarmPermDialog = false
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                        startActivity(intent)
                                    }
                                }) { Text("Open Settings") }
                            },
                            dismissButton = {
                                TextButton(onClick = { showAlarmPermDialog = false }) { Text("Skip") }
                            },
                            title = { Text("Alarm Permission Required") },
                            text = { Text("To send timely reminders, this app needs permission to set alarms. You'll be redirected to settings.") }
                        )
                    }
                }
            }
        }
    }

    private fun requestInitialPermissionsIfNeeded() {
        val settingsManager = SettingsManager(this)
        
        // Only request once on first launch
        if (!settingsManager.hasRequestedPermissions()) {
            settingsManager.setPermissionsRequested()
            
            // Step 1: Request notification permission first
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) 
                    == PackageManager.PERMISSION_GRANTED) {
                    // Already granted, enable notifications
                    onPermissionsGranted(settingsManager)
                    // Then check alarm permission
                    checkAlarmPermission()
                } else {
                    // Show notification permission dialog
                    showNotificationPermDialog = true
                }
            } else {
                // Pre-Android 13, notifications don't need runtime permission
                onPermissionsGranted(settingsManager)
                // Then check alarm permission
                checkAlarmPermission()
            }
        }
    }

    private fun checkAlarmPermission() {
        // Step 2: Check SCHEDULE_EXACT_ALARM permission (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                // Show dialog explaining why we need this permission
                showAlarmPermDialog = true
            }
        }
    }

    private fun onPermissionsGranted(settingsManager: SettingsManager) {
        // Enable push notifications by default
        settingsManager.setPushNotificationsEnabled(true)
        
        // Create notification channel
        val notificationManager = AppNotificationManager(this)
        notificationManager.createNotificationChannel()
    }
}

private fun routeDepth(route: AppRoute): Int = when (route) {
    AppRoute.Dashboard -> 0
    AppRoute.Settings -> 1
    AppRoute.Notifications -> 2
    AppRoute.Appearance -> 2
    AppRoute.Currency -> 2
    AppRoute.Widget -> 2
    AppRoute.CustomColor -> 3
    AppRoute.AddCategory -> 3
    AppRoute.CustomIcons -> 4
    AppRoute.Backup -> 2
    AppRoute.Restore -> 2
    AppRoute.About -> 2
    AppRoute.EraseData -> 2
    AppRoute.Insights -> 1
}

private enum class AppRoute { Dashboard, Settings, Notifications, Appearance, Currency, Widget, Backup, Restore, About, EraseData, CustomColor, AddCategory, CustomIcons, Insights }

private enum class CustomColorTarget { Background, Text }
