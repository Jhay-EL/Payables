package com.app.payables.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.animateContentSize
import com.app.payables.theme.AppTransitions
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import com.app.payables.theme.*
import androidx.activity.compose.BackHandler
import java.util.UUID
import androidx.compose.ui.platform.LocalContext
import com.app.payables.PayablesApplication
import androidx.compose.runtime.collectAsState
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    modifier: Modifier = Modifier,
    onOpenSettings: () -> Unit = {},
    onOpenAddCategory: () -> Unit = {},
    onOpenInsights: () -> Unit = {}
) {
    // Get repositories from Application
    val context = LocalContext.current
    val app = context.applicationContext as PayablesApplication
    val repository = app.categoryRepository
    val payableRepository = app.payableRepository
    val customPaymentMethodRepository = app.customPaymentMethodRepository
    val coroutineScope = rememberCoroutineScope()
    
    var showMenu by remember { mutableStateOf(false) }
    var showAddSheet by remember { mutableStateOf(false) }
    var showHideSheet by remember { mutableStateOf(false) }
    var hideCategories by remember { mutableStateOf(false) }
    var hidePausedFinished by remember { mutableStateOf(false) }
    var hideInsights by remember { mutableStateOf(false) }
    var isEditingCategories by remember { mutableStateOf(false) }
    var editingCategoryIndex by remember { mutableIntStateOf(-1) }
    var showEditCategoryFullScreen by remember { mutableStateOf(false) }
    var showCustomIconsFullScreen by remember { mutableStateOf(false) }
    var showAddPayableFullScreen by remember { mutableStateOf(false) }
    var showPayablesFullScreen by remember { mutableStateOf(false) }
    var showViewPayableFullScreen by remember { mutableStateOf(false) }
    var selectedPayable by remember { mutableStateOf<PayableItemData?>(null) }
    var selectedPayableFilter by remember { mutableStateOf<PayableFilter>(PayableFilter.All) }
    
    // State for animated deletion
    val categoriesBeingDeleted = remember { mutableStateListOf<String>() }
    
    // State for delete confirmation dialog
    var showDeleteConfirmDialog by remember { mutableStateOf(false) }
    var categoryToDeleteIndex by remember { mutableIntStateOf(-1) }

    // Preserve scroll position across navigation
    val lazyListState = rememberSaveable(saver = LazyListState.Saver) {
        LazyListState()
    }

    // Load categories from database
    val categories by repository.getAllCategories().collectAsState(initial = emptyList())
    
    // Load active payables from database for count calculations (UI representation)
    val allPayablesUI by payableRepository.getActivePayables().collectAsState(initial = emptyList())
    
    // Load paused payables for the paused section
    val pausedPayablesUI by payableRepository.getPausedPayables().collectAsState(initial = emptyList())
    
    val payablesDueThisWeek by payableRepository.getActivePayablesDueThisWeek().collectAsState(initial = emptyList())
    val payablesDueThisMonth by payableRepository.getActivePayablesDueThisMonth().collectAsState(initial = emptyList())
    
    // Calculate dynamic counts directly from UI data to ensure accuracy
    val counts = remember(allPayablesUI, categories) {
        val categoryCountsMap = mutableMapOf<String, Int>()
        
        // Count payables by their actual stored category
        categories.forEach { category ->
            val count = allPayablesUI.count { payable -> payable.category == category.name }
            categoryCountsMap[category.name] = count
        }
        
        categoryCountsMap.toMap()
    }
    
    // Calculate overview counts
    val overviewCounts = remember(allPayablesUI, payablesDueThisWeek, payablesDueThisMonth) {
        mapOf(
            "All" to allPayablesUI.size,
            "This Week" to payablesDueThisWeek.size,
            "This Month" to payablesDueThisMonth.size
        )
    }
    
    // Update categories with real counts
    val categoriesWithCounts = remember(categories, counts) {
        categories.map { category ->
            val count = counts[category.name] ?: 0
            category.copy(count = count.toString())
        }
    }
    
    // Convert to mutable list for UI operations (editing, etc.)
    val mutableCategories = remember(categoriesWithCounts) { 
        mutableStateListOf<CategoryData>().apply { 
            clear()
            addAll(categoriesWithCounts) 
        } 
    }
    
    // Simplified screen state to prevent overlapping renders
    val currentEditScreen by remember {
        derivedStateOf {
            when {
                showCustomIconsFullScreen -> EditScreenState.CustomIcons
                showEditCategoryFullScreen -> EditScreenState.EditCategory
                showAddPayableFullScreen -> EditScreenState.AddPayable
                showViewPayableFullScreen -> EditScreenState.ViewPayable
                showPayablesFullScreen -> EditScreenState.Payables
                else -> EditScreenState.None
            }
        }
    }
    
    // Clean transition logic - removed complex LaunchedEffect

    // Clean state management with proper sequencing
    LaunchedEffect(showEditCategoryFullScreen, showCustomIconsFullScreen, showAddPayableFullScreen, showViewPayableFullScreen, showPayablesFullScreen) {
        // Reset editing index when all screens are closed
        if (!showCustomIconsFullScreen && !showEditCategoryFullScreen && !showAddPayableFullScreen && !showViewPayableFullScreen && !showPayablesFullScreen) {
            editingCategoryIndex = -1
        }
    }

    // Defer selectedPayable cleanup until after exit animation completes
    LaunchedEffect(showViewPayableFullScreen) {
        if (!showViewPayableFullScreen) {
            // Clear selectedPayable after the exit animation has time to complete
            selectedPayable = null
        }
    }

    var payablesTitleInitialY by remember { mutableStateOf<Int?>(null) }
    var payablesTitleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }

    val onTitlePositioned: (Int) -> Unit = { y ->
        if (payablesTitleInitialY == null) {
            payablesTitleInitialY = y
        }
        payablesTitleWindowY = y
    }

    val density = LocalDensity.current
    val initialY = payablesTitleInitialY

    // Calculate the fade progress of the main "Payables" title.
    // It is fully visible (progress = 0) at its initial position and fully faded (progress = 1)
    // as it approaches the top app bar.
    val titleFadeProgress = if (initialY != null) {
        val fadeStartPx = initialY.toFloat()
        // Threshold where app bar title should take over
        val appBarThresholdPx = with(density) { 72.dp.toPx() }
        val fadeRangePx = (fadeStartPx - appBarThresholdPx).coerceAtLeast(1f)
        val currentY = payablesTitleWindowY.toFloat()
        ((fadeStartPx - currentY) / fadeRangePx).coerceIn(0f, 1f)
    } else {
        // When scroll position is restored, check if we're scrolled past the title
        // Use derivedStateOf to avoid excessive recompositions from frequently changing scroll state
        val scrollBasedFade by remember {
            derivedStateOf {
                val firstVisibleItemIndex = lazyListState.firstVisibleItemIndex
                val firstVisibleItemScrollOffset = lazyListState.firstVisibleItemScrollOffset
                if (firstVisibleItemIndex > 0 || firstVisibleItemScrollOffset > with(density) { 200.dp.toPx() }) {
                    1f // Show top bar title if scrolled significantly
                } else {
                    0f // Default to fully visible
                }
            }
        }
        scrollBasedFade
    }

    // Calculate the alpha for the title in the top bar.
    // It starts appearing only after the main title has faded by 90%.
    val topBarAlphaStart = 0.9f
    val topBarAlpha = ((titleFadeProgress - topBarAlphaStart) / (1f - topBarAlphaStart)).coerceIn(0f, 1f)

    // Material 3 app bar scroll behavior and dynamic color when content under bar
    val topBarScrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    val topBarContainerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)

    // Complete screen management with smooth page transitions
    AnimatedContent(
        targetState = currentEditScreen,
        transitionSpec = AppTransitions.materialSharedAxisHorizontal(
            isForward = { initial, target -> 
                routeDepthForEditScreen(target) > routeDepthForEditScreen(initial)
            },
            durationMillis = 300,
            fadeDurationMillis = 150,
            distanceFraction = 0.3f,
            clip = false
        ),
        contentKey = { it },
        modifier = Modifier.fillMaxSize()
    ) { screenState ->
        when (screenState) {
            EditScreenState.None -> {
                // Show Dashboard content
                Scaffold(
                    modifier = Modifier.nestedScroll(topBarScrollBehavior.nestedScrollConnection),
                    topBar = {
                        TopAppBar(
                            scrollBehavior = topBarScrollBehavior,
                            title = {
                                Text(
                                    if (isEditingCategories) "Categories edit mode" else "Payables",
                                    modifier = Modifier.graphicsLayer(alpha = topBarAlpha)
                                )
                            },
                            colors = TopAppBarDefaults.topAppBarColors(
                                containerColor = topBarContainerColor,
                                scrolledContainerColor = topBarContainerColor
                            ),
                            actions = {
                                if (isEditingCategories) {
                                    TextButton(onClick = { isEditingCategories = false }) { Text("Done") }
                                } else {
                                    IconButton(onClick = { showMenu = !showMenu }) {
                                        Icon(Icons.Default.MoreVert, contentDescription = "More")
                                    }
                                    DropdownMenu(
                                        expanded = showMenu,
                                        onDismissRequest = { showMenu = false },
                                        offset = DpOffset(x = (-16).dp, y = 0.dp),
                                        modifier = Modifier.width(150.dp)
                                    ) {
                                        DropdownMenuItem(
                                            text = { Text("Add", style = MaterialTheme.typography.bodyLarge) },
                                            onClick = {
                                                showMenu = false
                                                showAddSheet = true
                                            }
                                        )
                                        DropdownMenuItem(
                                            text = { Text("Edit", style = MaterialTheme.typography.bodyLarge) },
                                            onClick = {
                                                showMenu = false
                                                isEditingCategories = true
                                            }
                                        )
                                        DropdownMenuItem(
                                            text = { Text("Hide Panel", style = MaterialTheme.typography.bodyLarge) },
                                            onClick = {
                                                showMenu = false
                                                showHideSheet = true
                                            }
                                        )
                                        DropdownMenuItem(
                                            text = { Text("Settings", style = MaterialTheme.typography.bodyLarge) },
                                            onClick = {
                                                showMenu = false
                                                onOpenSettings()
                                            }
                                        )
                                    }
                                }
                            }
                        )
                    }
                ) { paddingValues ->
                    val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()

                    LazyColumn(
                        state = lazyListState, // Preserve scroll position
                        modifier = modifier
                            .fillMaxSize()
                            .padding(paddingValues), // Apply padding from Scaffold
                        contentPadding = PaddingValues(
                            bottom = bottomInset + LocalAppDimensions.current.spacing.navBarContentBottomMargin
                        )
                    ) {
                        // Overview Section
                        item {
                            OverviewSection(
                                titleFadeProgress = titleFadeProgress,
                                onTitlePositionInWindowChange = onTitlePositioned,
                                onAllClick = { 
                                    selectedPayableFilter = PayableFilter.All
                                    showPayablesFullScreen = true 
                                },
                                onThisWeekClick = {
                                    selectedPayableFilter = PayableFilter.ThisWeek
                                    showPayablesFullScreen = true
                                },
                                onThisMonthClick = {
                                    selectedPayableFilter = PayableFilter.ThisMonth
                                    showPayablesFullScreen = true
                                },
                                overviewCounts = overviewCounts
                            )
                        }

                        // Categories Section
                        if (!hideCategories) {
                            item {
                                CategoriesSection(
                                    categories = mutableCategories,
                                    isEditing = isEditingCategories,
                                    categoriesBeingDeleted = categoriesBeingDeleted,
                                    onEdit = { index ->
                                        if (index in mutableCategories.indices) {
                                            editingCategoryIndex = index
                                            showEditCategoryFullScreen = true
                                        }
                                    },
                                    onDelete = { index ->
                                        if (index in mutableCategories.indices) {
                                            categoryToDeleteIndex = index
                                            showDeleteConfirmDialog = true
                                        }
                                    },
                                    onCategoryClick = { categoryName ->
                                        selectedPayableFilter = PayableFilter.Category(categoryName)
                                        showPayablesFullScreen = true
                                    }
                                )
                            }
                        }

                        // Insights Preview Card
                        if (!hideInsights) {
                            item {
                                InsightsPreviewCard(
                                    onClick = onOpenInsights
                                )
                            }
                        }

                        // Paused/Finished Section
                        if (!hidePausedFinished) {
                            item {
                                val finishedPayables = payableRepository.getAllPayables().collectAsState(initial = emptyList()).value.filter { it.isFinished }
                                PausedFinishedSection(
                                    pausedPayables = pausedPayablesUI,
                                    finishedPayables = finishedPayables,
                                    onPausedClick = {
                                        if (pausedPayablesUI.isNotEmpty()) {
                                            selectedPayableFilter = PayableFilter.Paused
                                            showPayablesFullScreen = true
                                        }
                                    },
                                    onFinishedClick = {
                                        if (finishedPayables.isNotEmpty()) {
                                            selectedPayableFilter = PayableFilter.Finished
                                            showPayablesFullScreen = true
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            EditScreenState.EditCategory -> {
                if (editingCategoryIndex in mutableCategories.indices && mutableCategories.isNotEmpty()) {
                    AddCategoryScreen(
                        onBack = { 
                            showEditCategoryFullScreen = false 
                            editingCategoryIndex = -1
                        },
                        onSave = { updated ->
                            coroutineScope.launch {
                                repository.updateCategory(updated)
                            }
                            showEditCategoryFullScreen = false
                            editingCategoryIndex = -1
                        },
                        onOpenCustomIcons = { showCustomIconsFullScreen = true },
                        initialCategory = mutableCategories[editingCategoryIndex],
                        titleText = "Edit Category"
                    )
                } else {
                    // Handle case where categories are still loading or index is invalid
                    LaunchedEffect(mutableCategories.size) {
                        // If categories loaded but index is invalid, go back to dashboard
                        if (mutableCategories.isNotEmpty() && editingCategoryIndex !in mutableCategories.indices) {
                            showEditCategoryFullScreen = false
                            editingCategoryIndex = -1
                        }
                    }
                    // Show loading or empty state while waiting for data
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        if (mutableCategories.isEmpty()) {
                            CircularProgressIndicator()
                        } else {
                            // Invalid index, will trigger LaunchedEffect to go back
                            Box(modifier = Modifier.fillMaxSize())
                        }
                    }
                }
            }
            EditScreenState.CustomIcons -> {
                CustomIconsScreen(
                    onBack = { 
                        // Return to EditCategory
                        showCustomIconsFullScreen = false
                    }
                )
            }
            EditScreenState.AddPayable -> {
                AddPayableScreen(
                    onBack = {
                        showAddPayableFullScreen = false
                        if (selectedPayable != null) {
                            showViewPayableFullScreen = true
                        }
                    },
                    onSave = {
                        coroutineScope.launch {
                            val editedPayableId = selectedPayable?.id
                            showAddPayableFullScreen = false
                            if (editedPayableId != null) {
                                val allPayables = payableRepository.getAllPayables().first()
                                val updatedPayable = allPayables.find { it.id == editedPayableId }
                                if (updatedPayable != null) {
                                    selectedPayable = updatedPayable
                                    showViewPayableFullScreen = true
                                } else {
                                    selectedPayable = null
                                }
                            }
                        }
                    },
                    payableRepository = payableRepository,
                    categoryRepository = repository,
                    customPaymentMethodRepository = customPaymentMethodRepository,
                    editingPayable = selectedPayable // Pass the selected payable for editing
                )
            }
            EditScreenState.Payables -> {
                // Choose data source based on filter
                val sourcePayables = when (selectedPayableFilter) {
                    is PayableFilter.Paused -> pausedPayablesUI
                    is PayableFilter.Finished -> {
                        // Get all payables and filter for finished ones (only shown in Finished section)
                        payableRepository.getAllPayables().collectAsState(initial = emptyList()).value.filter { it.isFinished }
                    }
                    is PayableFilter.ThisWeek -> payablesDueThisWeek
                    is PayableFilter.ThisMonth -> payablesDueThisMonth
                    else -> {
                        // For active payables (non-paused, non-finished)
                        // Note: We removed automatic finished status checking to prevent
                        // accidental marking of payables as finished on app restart
                        val activePayables = payableRepository.getActivePayables().collectAsState(initial = emptyList()).value
                        activePayables
                    }
                }
                
                // Filter payables based on selected filter
                val filteredPayables = remember(sourcePayables, selectedPayableFilter) {
                    val currentFilter = selectedPayableFilter // Store in local variable for smart casting
                    when (currentFilter) {
                        is PayableFilter.All,
                        is PayableFilter.Paused,
                        is PayableFilter.ThisWeek,
                        is PayableFilter.ThisMonth,
                        is PayableFilter.Finished -> sourcePayables // Already filtered by data source
                        is PayableFilter.Category -> {
                            // Filter payables by their actual stored category
                            sourcePayables.filter { payable ->
                                payable.category == currentFilter.categoryName
                            }
                        }
                    }
                }
                
                PayableScreen(
                    onBack = { 
                        showPayablesFullScreen = false
                    },
                    onNavigateToAddPayable = { showAddPayableFullScreen = true },
                    onPayableClick = { payable ->
                        selectedPayable = payable
                        showViewPayableFullScreen = true
                    },
                    payables = filteredPayables,
                    monthlyAmount = calculateTotalAmount(filteredPayables),
                    screenTitle = selectedPayableFilter.displayTitle
                )
            }
            EditScreenState.ViewPayable -> {
                selectedPayable?.let { payable ->
                    ViewPayableScreen(
                        payable = payable,
                        customPaymentMethodRepository = customPaymentMethodRepository,
                        onBack = {
                            showViewPayableFullScreen = false
                            showPayablesFullScreen = true
                        },
                        onEdit = {
                            // Navigate to AddPayableScreen in edit mode
                            // Don't clear selectedPayable since AddPayableScreen needs it for editing
                            showAddPayableFullScreen = true
                        },
                        onPause = {
                            // Implement pause functionality
                            coroutineScope.launch {
                                payableRepository.pausePayable(payable.id)
                            }
                            // BackHandler will handle navigation
                            showViewPayableFullScreen = false
                        },
                        onUnpause = {
                            // Implement unpause functionality
                            coroutineScope.launch {
                                payableRepository.unpausePayable(payable.id)
                            }
                            // BackHandler will handle navigation
                            showViewPayableFullScreen = false
                            showPayablesFullScreen = false
                        },
                        onFinish = {
                            // Implement finish functionality
                            coroutineScope.launch {
                                payableRepository.finishPayable(payable.id)
                            }
                            // BackHandler will handle navigation
                            showViewPayableFullScreen = false
                        },
                        onUnfinish = {
                            // Implement unfinish functionality
                            coroutineScope.launch {
                                payableRepository.unfinishPayable(payable.id)
                            }
                            // BackHandler will handle navigation
                            showViewPayableFullScreen = false
                            showPayablesFullScreen = false
                        },
                        onDelete = {
                            // Implement delete functionality
                            coroutineScope.launch {
                                payableRepository.deletePayable(payable.id, repository)
                            }
                            // BackHandler will handle navigation
                            showViewPayableFullScreen = false
                            selectedPayable = null
                        }
                    )
                } ?: run {
                    // Handle case where selectedPayable is null (shouldn't happen)
                    LaunchedEffect(Unit) {
                        showViewPayableFullScreen = false
                    }
                }
            }
        }
    }

    // Add New bottom sheet (Material 3 Modal Bottom Sheet)
    if (showAddSheet) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { showAddSheet = false },
            sheetState = sheetState,
            dragHandle = { BottomSheetDefaults.DragHandle() },
        ) {
            AddNewSheetContent(
                onAddPayable = {
                    showAddSheet = false
                    showAddPayableFullScreen = true
                },
                onAddCategory = {
                    showAddSheet = false
                    onOpenAddCategory()
                }
            )
        }
    }

    // Hide Panel bottom sheet
    if (showHideSheet) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { showHideSheet = false },
            sheetState = sheetState,
            dragHandle = { BottomSheetDefaults.DragHandle() },
        ) {
            HidePanelSheetContent(
                hideCategories = hideCategories,
                onToggleCategories = { hideCategories = it },
                hidePausedFinished = hidePausedFinished,
                onTogglePausedFinished = { hidePausedFinished = it },
                hideInsights = hideInsights,
                onToggleInsights = { hideInsights = it }
            )
        }
    }

    // Centralized back handler for all navigation
    // This is the ONLY BackHandler in the entire app to prevent conflicts
    BackHandler(enabled = currentEditScreen != EditScreenState.None) {
        when (currentEditScreen) {
            EditScreenState.CustomIcons -> {
                // Return to EditCategory by disabling CustomIcons only
                showCustomIconsFullScreen = false
            }
            EditScreenState.EditCategory -> {
                // Return to Dashboard by disabling EditCategory
                showEditCategoryFullScreen = false
                editingCategoryIndex = -1
            }
            EditScreenState.AddPayable -> {
                showAddPayableFullScreen = false
                // Return to ViewPayableScreen if we came from there (selectedPayable exists)
                // Otherwise return to Payables screen
                if (selectedPayable != null) {
                    showViewPayableFullScreen = true
                }
                // Don't clear selectedPayable here - keep it for ViewPayableScreen
            }
            EditScreenState.ViewPayable -> {
                // Single state change to prevent animation conflicts
                showViewPayableFullScreen = false
                // Return to Payables screen when backing out of ViewPayable
                showPayablesFullScreen = true
                // Don't set selectedPayable = null here - defer to LaunchedEffect for smooth animation
            }
            EditScreenState.Payables -> {
                showPayablesFullScreen = false
            }
            EditScreenState.None -> {
                // This case is unreachable because the handler is disabled when state is None.
                // It's here to make the 'when' exhaustive.
            }
        }
    }

    // Delete confirmation dialog
    if (showDeleteConfirmDialog && categoryToDeleteIndex in mutableCategories.indices) {
        val categoryToDelete = mutableCategories[categoryToDeleteIndex]
        
        fun closeDialog() {
            showDeleteConfirmDialog = false
            categoryToDeleteIndex = -1
        }
        
        AlertDialog(
            onDismissRequest = { closeDialog() },
            title = { Text("Delete Category") },
            text = { Text("Delete \"${categoryToDelete.name}\"?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        categoriesBeingDeleted.add(categoryToDelete.id)
                        coroutineScope.launch {
                            kotlinx.coroutines.delay(300)
                            repository.deleteCategory(categoryToDelete.id)
                            categoriesBeingDeleted.remove(categoryToDelete.id)
                        }
                        closeDialog()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { closeDialog() }) {
                    Text("Cancel")
                }
            }
        )
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OverviewSection(
    titleFadeProgress: Float,
    onTitlePositionInWindowChange: (Int) -> Unit,
    onAllClick: () -> Unit = {},
    onThisWeekClick: () -> Unit = {},
    onThisMonthClick: () -> Unit = {},
    overviewCounts: Map<String, Int> = emptyMap()
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                start = LocalAppDimensions.current.spacing.md,
                end = LocalAppDimensions.current.spacing.md,
                top = LocalAppDimensions.current.spacing.md + LocalAppDimensions.current.titleDimensions.payablesTitleTopPadding
            )
    ) {
        // Invisible anchor to continuously track position during scroll
        Box(
            modifier = Modifier.onGloballyPositioned { coordinates ->
                onTitlePositionInWindowChange(coordinates.positionInWindow().y.toInt())
            }
        )

        // Payables Title (continuous fade + slight move/scale)
        Column(
            modifier = Modifier
                .graphicsLayer(
                    translationY = (12f * titleFadeProgress),
                    scaleX = 1f - (0.02f * titleFadeProgress),
                    scaleY = 1f - (0.02f * titleFadeProgress)
                )
        ) {
            Text(
                text = "Payables",
                style = MaterialTheme.typography.displayMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - titleFadeProgress)
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.titleDimensions.payablesTitleToOverviewSpacing))
        }

        // Section Header
        Text(
            text = "Overview",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
        )

        // Overview Cards
        OverviewCard(
            title = "All",
            subtitle = "View all payables",
            count = (overviewCounts["All"] ?: 0).toString(),
            icon = Icons.Filled.Dashboard,
            isFirst = true,
            isLast = false,
            onClick = onAllClick
        )

        OverviewCard(
            title = "This Week",
            subtitle = "Due this week",
            count = (overviewCounts["This Week"] ?: 0).toString(),
            icon = Icons.Filled.DateRange,
            isFirst = false,
            isLast = false,
            onClick = onThisWeekClick
        )

        OverviewCard(
            title = "This Month",
            subtitle = "Due this month",
            count = (overviewCounts["This Month"] ?: 0).toString(),
            icon = Icons.Filled.CalendarToday,
            isFirst = false,
            isLast = true,
            onClick = onThisMonthClick
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OverviewCard(
    title: String,
    subtitle: String,
    count: String,
    icon: ImageVector,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit = {}
) {
    val cornerRadius = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    val interactionSource = remember { MutableInteractionSource() }

    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interactionSource),
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon Container
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        MaterialTheme.colorScheme.secondaryContainer,
                        RoundedCornerShape(16.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = "$title overview",
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSecondaryContainer
                )
            }

            // Text Content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            // Count Badge
            if (count.isNotEmpty()) {
                Box(
                    modifier = Modifier
                        .background(
                            MaterialTheme.colorScheme.secondaryContainer,
                            RoundedCornerShape(16.dp)
                        )
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = count,
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddNewSheetContent(
    onAddPayable: () -> Unit,
    onAddCategory: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = LocalAppDimensions.current.spacing.md)
            .padding(bottom = LocalAppDimensions.current.spacing.lg)
    ) {
        // Header
        Text(
            text = "Add New",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "What would you like to add?",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.section))

        AddOptionCard(
            title = "Payable",
            subtitle = "Add a new subscription or bill",
            icon = Icons.Filled.Edit,
            onClick = onAddPayable,
            isFirst = true,
            isLast = false
        )
        AddOptionCard(
            title = "Category",
            subtitle = "Create a new category for payables",
            icon = Icons.Filled.Category,
            onClick = onAddCategory,
            isFirst = false,
            isLast = true
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddOptionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean
) {
    val interactionSource = remember { MutableInteractionSource() }
    val cornerRadius = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interactionSource),
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Leading icon in a soft container to match expressive guidelines
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                        RoundedCornerShape(16.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = "Add $title",
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HideOptionCard(
    title: String,
    subtitle: String,
    isChecked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    isFirst: Boolean,
    isLast: Boolean
) {
    val interactionSource = remember { MutableInteractionSource() }
    val cornerRadius = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    Card(
        onClick = { onCheckedChange(!isChecked) },
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interactionSource),
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
            Switch(
                checked = isChecked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HidePanelSheetContent(
    hideCategories: Boolean,
    onToggleCategories: (Boolean) -> Unit,
    hidePausedFinished: Boolean,
    onTogglePausedFinished: (Boolean) -> Unit,
    hideInsights: Boolean,
    onToggleInsights: (Boolean) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = LocalAppDimensions.current.spacing.md)
            .padding(bottom = LocalAppDimensions.current.spacing.lg)
    ) {
        Text(
            text = "Hide Panel",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Select which sections to hide",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.section))

        HideOptionCard(
            title = "Hide Categories",
            subtitle = "Hide the Categories section",
            isChecked = hideCategories,
            onCheckedChange = onToggleCategories,
            isFirst = true,
            isLast = false
        )
        HideOptionCard(
            title = "Hide Paused/Finished",
            subtitle = "Hide the Paused/Finished section",
            isChecked = hidePausedFinished,
            onCheckedChange = onTogglePausedFinished,
            isFirst = false,
            isLast = false
        )
        HideOptionCard(
            title = "Hide Insights",
            subtitle = "Hide the Spending Insights section",
            isChecked = hideInsights,
            onCheckedChange = onToggleInsights,
            isFirst = false,
            isLast = true
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoriesSection(
    categories: SnapshotStateList<CategoryData>,
    isEditing: Boolean,
    categoriesBeingDeleted: List<String>,
    onEdit: (Int) -> Unit,
    onDelete: (Int) -> Unit,
    onCategoryClick: (String) -> Unit = {}
) {
    // Item heights for layout calculation
    val itemHeightsPx = remember(categories.size) { MutableList(categories.size) { 0 } }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = LocalAppDimensions.current.spacing.md, start = LocalAppDimensions.current.spacing.md, end = LocalAppDimensions.current.spacing.md)

    ) {
        // Section Header (no trailing Done here; Done is in TopAppBar actions)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 48.dp)
                .padding(bottom = LocalAppDimensions.current.spacing.cardToHeader),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Reserve space and avoid text reflow when actions change
            Text(
                text = "Categories",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(top = 8.dp),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            // Empty trailing to keep spacing consistent with other sections
            Spacer(modifier = Modifier.width(1.dp))
        }

        // Categories List with animated deletion
        categories.forEachIndexed { index, category ->
            // Provide a stable composition key per item so gesture/press state follows the item
            key(category.id) {
                val isBeingDeleted = category.id in categoriesBeingDeleted
                
                AnimatedVisibility(
                    visible = !isBeingDeleted,
                    exit = slideOutHorizontally(
                        targetOffsetX = { -it }, // Slide out to the left
                        animationSpec = tween(
                            durationMillis = 300,
                            easing = FastOutSlowInEasing
                        )
                    ) + fadeOut(
                        animationSpec = tween(
                            durationMillis = 300,
                            easing = LinearOutSlowInEasing
                        )
                    ) + scaleOut(
                        targetScale = 0.8f,
                        animationSpec = tween(
                            durationMillis = 300,
                            easing = FastOutSlowInEasing
                        )
                    )
                ) {
                    CategoryCard(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 2.dp)
                            .animateContentSize( // Smooth size changes for remaining cards
                                animationSpec = spring(
                                    dampingRatio = Spring.DampingRatioMediumBouncy,
                                    stiffness = Spring.StiffnessMedium
                                )
                            ),
                        category = category,
                        isFirst = index == 0,
                        isLast = index == categories.size - 1,
                        isEditing = isEditing,
                        onHeightMeasured = { h -> if (index in itemHeightsPx.indices) itemHeightsPx[index] = h },
                        onEdit = { onEdit(index) },
                        onDelete = { onDelete(index) },
                        onCategoryClick = { onCategoryClick(category.name) }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoryCard(
    modifier: Modifier = Modifier,
    category: CategoryData,
    isFirst: Boolean,
    isLast: Boolean,
    isEditing: Boolean,
    onHeightMeasured: (Int) -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onCategoryClick: () -> Unit = {}
) {

    val cornerRadius = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    val interactionSource = remember { MutableInteractionSource() }

    Card(
        onClick = if (!isEditing) { onCategoryClick } else { {} },
        modifier = modifier
            .fillMaxWidth()
            .then(if (!isEditing) Modifier.pressableCard(interactionSource = interactionSource) else Modifier)
            // Measure card height for layout calculation
            .onGloballyPositioned { onHeightMeasured(it.size.height) },
        enabled = !isEditing, // Disable card interactions in edit mode
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Category icon (always show, regardless of edit mode)
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        category.color.copy(alpha = 0.18f),
                        RoundedCornerShape(16.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = category.icon,
                    contentDescription = "${category.name} category",
                    modifier = Modifier.size(20.dp),
                    tint = category.color
                )
            }

            // Category Name
            Text(
                text = category.name,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            )

            AnimatedContent(
                targetState = isEditing,
                transitionSpec = {
                    val duration = 220
                    (slideInHorizontally(animationSpec = tween(duration)) { it / 4 } +
                        fadeIn(animationSpec = tween(duration / 2))) togetherWith
                    (slideOutHorizontally(animationSpec = tween(duration)) { -it / 4 } +
                        fadeOut(animationSpec = tween(duration / 2)))
                },
                label = "trailingEditSwap",
                contentKey = { editing -> if (editing) "edit_buttons" else "count_badge" }
            ) { editing ->
                if (!editing) {
                    // Show count badge when not editing
                    Box(
                        modifier = Modifier
                            .background(
                                category.color.copy(alpha = 0.18f),
                                RoundedCornerShape(16.dp)
                            )
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = category.count,
                            style = MaterialTheme.typography.labelLarge,
                            color = category.color
                        )
                    }
                } else {
                    // Show edit buttons when editing
                    CompositionLocalProvider(LocalMinimumInteractiveComponentEnforcement provides false) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconButton(
                                onClick = onEdit,
                                modifier = Modifier.size(44.dp)
                            ) {
                                Icon(
                                    Icons.Filled.Edit, 
                                    contentDescription = "Edit ${category.name}", 
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                            IconButton(
                                onClick = onDelete,
                                modifier = Modifier.size(44.dp)
                            ) {
                                Icon(
                                    Icons.Filled.Delete, 
                                    contentDescription = "Delete ${category.name}", 
                                    tint = MaterialTheme.colorScheme.error, 
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// Removed unused EditCategorySheetContent after migrating to full-screen editor

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PausedFinishedSection(
    pausedPayables: List<PayableItemData> = emptyList(),
    finishedPayables: List<PayableItemData> = emptyList(),
    onPausedClick: () -> Unit = {},
    onFinishedClick: () -> Unit = {}
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = LocalAppDimensions.current.spacing.section, start = LocalAppDimensions.current.spacing.md, end = LocalAppDimensions.current.spacing.md)
    ) {
        // Section Header
        Text(
            text = "Paused/Finished",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
        )

        // Paused Card
        StatusCard(
            title = "Paused",
            subtitle = "Temporarily paused payables",
            count = pausedPayables.size.toString(),
            icon = Icons.Filled.Pause,
            color = MaterialTheme.colorScheme.tertiary,
            isFirst = true,
            isLast = false,
            onClick = onPausedClick
        )

        // Finished Card
        StatusCard(
            title = "Finished",
            subtitle = "Completed payables",
            count = finishedPayables.size.toString(),
            icon = Icons.Filled.CheckCircle,
            color = MaterialTheme.colorScheme.secondary,
            isFirst = false,
            isLast = true,
            onClick = onFinishedClick
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatusCard(
    title: String,
    subtitle: String,
    count: String,
    icon: ImageVector,
    color: Color,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit = {}
) {
    val cornerRadius = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    val interactionSource = remember { MutableInteractionSource() }

    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .pressableCard(interactionSource = interactionSource),
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon
            Icon(
                imageVector = icon,
                contentDescription = "$title status",
                modifier = Modifier.size(24.dp),
                tint = color
            )

            // Text Content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Count Badge
            if (count.isNotEmpty()) {
                Box(
                    modifier = Modifier
                        .background(
                            color.copy(alpha = 0.5f),
                            RoundedCornerShape(16.dp)
                        )
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = count,
                        style = MaterialTheme.typography.labelLarge,
                        color = color
                    )
                }
            }
        }
    }
}

// Data Classes
data class CategoryData(
    val name: String,
    val count: String,
    val color: Color,
    val icon: ImageVector,
    val id: String = UUID.randomUUID().toString()
)


// Enum for edit screen states to avoid nested animation conflicts  
private enum class EditScreenState { None, EditCategory, CustomIcons, AddPayable, Payables, ViewPayable }

// Sealed class for payable filtering
private sealed class PayableFilter(val displayTitle: String) {
    object All : PayableFilter("All")
    object ThisWeek : PayableFilter("This Week")
    object ThisMonth : PayableFilter("This Month")
    object Paused : PayableFilter("Paused")
    object Finished : PayableFilter("Finished")
    data class Category(val categoryName: String) : PayableFilter(categoryName)
}

// Helper function to calculate total monthly amount from payables
private fun calculateTotalAmount(payables: List<PayableItemData>): String {
    if (payables.isEmpty()) return "0.00"
    
    try {
        val total = payables
            .filter { it.currency == "EUR" } // Filter by EUR for now - can be made dynamic later
            .mapNotNull { 
                try {
                    it.price.toDoubleOrNull()
                } catch (_: NumberFormatException) {
                    null
                }
            }
            .sum()
        
        return String.format(java.util.Locale.US, "%.2f", total)
    } catch (_: Exception) {
        return "0.00"
    }
}

private fun routeDepthForEditScreen(screen: EditScreenState): Int = when (screen) {
    EditScreenState.None -> 0
    EditScreenState.EditCategory -> 1
    EditScreenState.Payables -> 1
    EditScreenState.ViewPayable -> 2  // Deeper than Payables for correct animation direction
    EditScreenState.AddPayable -> 3  // Deeper than ViewPayable for correct animation direction when editing
    EditScreenState.CustomIcons -> 2
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true)
@Composable
fun DashboardScreenPreview() {
    AppTheme {
        DashboardScreenContent()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DashboardScreenContent() {
    // Create a preview-friendly version without database dependencies
    val dims = LocalAppDimensions.current
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Payables") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp)
                ),
                actions = {
                    IconButton(onClick = { }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(
                bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding() + dims.spacing.navBarContentBottomMargin
            )
        ) {
            item {
                OverviewSection(
                    titleFadeProgress = 0f,
                    onTitlePositionInWindowChange = { },
                    onAllClick = { },
                    onThisWeekClick = { },
                    onThisMonthClick = { },
                    overviewCounts = mapOf("All" to 5, "This Week" to 2, "This Month" to 4)
                )
            }
            
            item {
                // Mock categories for preview
                val mockCategories = remember { 
                    mutableStateListOf(
                        CategoryData("Entertainment", "3", Color(0xFF2196F3), Icons.Filled.Movie),
                        CategoryData("Utilities", "5", Color(0xFF4CAF50), Icons.Filled.Home),
                        CategoryData("Software", "2", Color(0xFFFF9800), Icons.Filled.Computer)
                    )
                }
                
                CategoriesSection(
                    categories = mockCategories,
                    isEditing = false,
                    categoriesBeingDeleted = emptyList(),
                    onEdit = { },
                    onDelete = { },
                    onCategoryClick = { }
                )
            }
            
            item {
                PausedFinishedSection()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsPreviewCard(
    onClick: () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val dashboardTheme = LocalDashboardTheme.current

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                top = LocalAppDimensions.current.spacing.section,
                start = LocalAppDimensions.current.spacing.md,
                end = LocalAppDimensions.current.spacing.md
            )
    ) {
        Text(
            text = "Insights",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
        )

        Card(
            onClick = onClick,
            modifier = Modifier
                .fillMaxWidth()
                .pressableCard(interactionSource = interactionSource),
            shape = RoundedCornerShape(dashboardTheme.groupTopCornerRadius),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
            interactionSource = interactionSource
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(
                        horizontal = LocalAppDimensions.current.spacing.card,
                        vertical = LocalAppDimensions.current.spacing.lg
                    ),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(LocalAppDimensions.current.spacing.md)
                ) {
                    Icon(
                        Icons.Default.BarChart,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Column {
                        Text(
                            text = "Spending Insights",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            text = "Tap to view a breakdown of your spending",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = "View Insights",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
