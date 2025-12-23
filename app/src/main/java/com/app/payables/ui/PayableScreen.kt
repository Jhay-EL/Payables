package com.app.payables.ui

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.window.PopupProperties
import androidx.core.net.toUri
import coil.compose.AsyncImage
import com.app.payables.theme.*
import kotlin.math.pow
import androidx.activity.compose.BackHandler

@Suppress("AssignedValueIsNeverRead")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayableScreen(
    onBack: () -> Unit = {},
    onNavigateToAddPayable: () -> Unit = {},
    onPayableClick: (PayableItemData) -> Unit = {},
    monthlyAmount: String = "0.00",
    payables: List<PayableItemData> = emptyList(),
    screenTitle: String = "All"
) {

    var selectedCurrency by remember { mutableStateOf("EUR") }
    var showCurrencyDropdown by remember { mutableStateOf(false) }
    var showTopBarMenu by remember { mutableStateOf(false) }
    var showSearch by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    var showSortSheet by remember { mutableStateOf(false) }
    var showFilterSheet by remember { mutableStateOf(false) }

    // State for sorting
    var sortOption by remember { mutableStateOf(SortOption.DueDate) }
    var sortDirection by remember { mutableStateOf(SortDirection.Ascending) }

    // State for filtering
    var filterState by remember { mutableStateOf(FilterState()) }

    // Apply filters to the initial list
    val filteredPayables = remember(payables, filterState) {
        payables.filter { payable ->
            val selectedMethods = filterState.paymentMethods.filterValues { it }.keys

            val cycleMatch = filterState.selectedBillingCycle == null || payable.billingCycle == filterState.selectedBillingCycle
            val methodMatch = selectedMethods.isEmpty() || payable.paymentMethod in selectedMethods

            cycleMatch && methodMatch
        }
    }

    // Filter payables based on search query
    val searchFilteredPayables = remember(filteredPayables, searchQuery) {
        if (searchQuery.isBlank()) {
            filteredPayables
        } else {
            filteredPayables.filter { payable ->
                payable.name.contains(searchQuery, ignoreCase = true) ||
                payable.planType.contains(searchQuery, ignoreCase = true)
            }
        }
    }

    // Apply sorting to the search-filtered list
    val sortedPayables = remember(searchFilteredPayables, sortOption, sortDirection) {
        val sortedList = when (sortOption) {
            SortOption.Name -> searchFilteredPayables.sortedBy { it.name }
            SortOption.Amount -> searchFilteredPayables.sortedBy { it.price.toDoubleOrNull() ?: 0.0 }
            SortOption.DueDate -> searchFilteredPayables.sortedBy { it.nextDueDateMillis }
            SortOption.DateAdded -> searchFilteredPayables.sortedBy { it.createdAt }
        }
        if (sortDirection == SortDirection.Descending) {
            sortedList.reversed()
        } else {
            sortedList
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = screenTitle,
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                },
                navigationIcon = { 
                    IconButton(onClick = onBack) { 
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") 
                    } 
                },
                actions = {
                    Box {
                        IconButton(onClick = { showTopBarMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More options")
                        }
                        DropdownMenu(
                            expanded = showTopBarMenu,
                            onDismissRequest = { 
                                android.util.Log.d("PayableScreenDropdown", "onDismissRequest called")
                                showTopBarMenu = false 
                            },
                            offset = DpOffset(x = (-16).dp, y = 0.dp),
                            modifier = Modifier.width(150.dp),
                            properties = PopupProperties(
                                focusable = true,
                                dismissOnBackPress = true,
                                dismissOnClickOutside = true
                            )
                        ) {
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        "Search",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = { 
                                    showTopBarMenu = false
                                    showSearch = !showSearch
                                    if (!showSearch) {
                                        searchQuery = ""
                                    }
                                }
                            )
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        "Add Payable",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = { 
                                    showTopBarMenu = false
                                    onNavigateToAddPayable()
                                }
                            )
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        "Filter",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = { 
                                    showTopBarMenu = false
                                    showFilterSheet = true
                                }
                            )
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        "Sort",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = { 
                                    showTopBarMenu = false
                                    showSortSheet = true
                                }
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors()
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(
                    start = LocalAppDimensions.current.spacing.md,
                    end = LocalAppDimensions.current.spacing.md,
                    top = LocalAppDimensions.current.spacing.md
                )
                .verticalScroll(rememberScrollState())
        ) {
            // Search Bar - appears under top bar with animation
            AnimatedVisibility(
                visible = showSearch,
                enter = slideInVertically(
                    animationSpec = tween(300, easing = EaseOutCubic),
                    initialOffsetY = { -it }
                ) + fadeIn(animationSpec = tween(300, easing = EaseOutCubic)),
                exit = slideOutVertically(
                    animationSpec = tween(250, easing = EaseInCubic),
                    targetOffsetY = { -it }
                ) + fadeOut(animationSpec = tween(250, easing = EaseInCubic))
            ) {
                Column {
                    SearchBar(
                        query = searchQuery,
                        onQueryChange = { searchQuery = it },
                        onClose = { 
                            showSearch = false
                            searchQuery = ""
                        }
                    )
                    Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.lg))
                }
            }
            
            // Content with Currency Selector aligned to center
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Total Payable",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    
                    Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.xs))
                    
                    Text(
                        text = when (selectedCurrency) {
                            "EUR" -> "€$monthlyAmount"
                            "USD" -> "$$monthlyAmount"
                            "GBP" -> "£$monthlyAmount"
                            "JPY" -> "¥$monthlyAmount"
                            else -> "$selectedCurrency $monthlyAmount"
                        },
                        style = MaterialTheme.typography.displayLarge.copy(
                            fontSize = 48.sp,
                            fontWeight = FontWeight.Medium
                        ),
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "Updated just now",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = LocalAppDimensions.current.spacing.xs)
                    )
                }

                // Currency Selector - aligned with center of text content
                ExposedDropdownMenuBox(
                    expanded = showCurrencyDropdown,
                    onExpandedChange = { showCurrencyDropdown = it }
                ) {
                    Surface(
                        modifier = Modifier
                            .menuAnchor()
                            .height(40.dp),
                        shape = RoundedCornerShape(20.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                        onClick = { showCurrencyDropdown = !showCurrencyDropdown }
                    ) {
                        Row(
                            modifier = Modifier
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = selectedCurrency,
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = showCurrencyDropdown)
                        }
                    }
                    ExposedDropdownMenu(
                        expanded = showCurrencyDropdown,
                        onDismissRequest = { showCurrencyDropdown = false }
                    ) {
                        listOf("EUR", "USD", "GBP", "JPY").forEach { currency ->
                            DropdownMenuItem(
                                text = { Text(currency) },
                                onClick = { 
                                    selectedCurrency = currency
                                    showCurrencyDropdown = false
                                }
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.lg))

            // Payables List - Stacked Card Design
            if (sortedPayables.isEmpty() && searchQuery.isNotBlank()) {
                // Empty search results state
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = LocalAppDimensions.current.spacing.xl),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(LocalAppDimensions.current.spacing.md)
                    ) {
                        Icon(
                            Icons.Default.SearchOff,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                        )
                        Text(
                            text = "No payables found",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Try searching with different keywords",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                        )
                    }
                }
            } else if (sortedPayables.isEmpty() && payables.isEmpty()) {
                // Empty state when no payables exist
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = LocalAppDimensions.current.spacing.xl),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(LocalAppDimensions.current.spacing.md)
                    ) {
                        Icon(
                            Icons.Default.Payment,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                        )
                        Text(
                            text = "No payables yet",
                            style = MaterialTheme.typography.headlineSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Add your first payable to get started",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                        )
                        Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.sm))
                        Button(
                            onClick = onNavigateToAddPayable,
                            modifier = Modifier
                                .padding(top = LocalAppDimensions.current.spacing.sm)
                                .height(48.dp)
                                .padding(horizontal = LocalAppDimensions.current.spacing.md)
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(LocalAppDimensions.current.spacing.sm))
                            Text(
                                "Add Payable",
                                style = MaterialTheme.typography.labelLarge
                            )
                        }
                    }
                }
            } else {
                sortedPayables.forEachIndexed { index, payable ->
                    key(payable.id) {
                        PayableCard(
                            title = payable.name,
                            subtitle = payable.planType,
                            amountLabel = when (payable.currency) {
                                "EUR" -> "€${payable.price}"
                                "USD" -> "$${payable.price}"
                                "GBP" -> "£${payable.price}"
                                "JPY" -> "¥${payable.price}"
                                else -> "${payable.currency} ${payable.price}"
                            },
                            badge = payable.dueDate,
                            icon = payable.icon,
                            backgroundColor = payable.backgroundColor,
                            customIconUri = payable.customIconUri,
                            isFirst = index == 0,
                            isLast = index == sortedPayables.lastIndex,
                            onClick = { onPayableClick(payable) }
                        )
                    }
                }
            }

            // Bottom spacing for navigation bar
            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + LocalAppDimensions.current.spacing.navBarContentBottomMargin))
        }
    }
    if (showSortSheet) {
        SortOptionsSheet(
            onDismiss = { showSortSheet = false },
            selectedOption = sortOption,
            onSelectOption = { sortOption = it },
            selectedDirection = sortDirection,
            onSelectDirection = { sortDirection = it }
        )
    }

    if (showFilterSheet) {
        FilterOptionsSheet(
            onDismiss = { showFilterSheet = false },
            filterState = filterState,
            onFilterStateChange = { filterState = it },
            paymentMethods = payables.map { it.paymentMethod }.distinct()
        )
    }
    
    // Handle back button when menu is open (highest priority)
    BackHandler(enabled = showTopBarMenu) {
        android.util.Log.d("PayableScreenBackHandler", "Closing menu")
        showTopBarMenu = false
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilterOptionsSheet(
    onDismiss: () -> Unit,
    filterState: FilterState,
    onFilterStateChange: (FilterState) -> Unit,
    paymentMethods: List<String>
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { BottomSheetDefaults.DragHandle() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LocalAppDimensions.current.spacing.md)
                .padding(bottom = LocalAppDimensions.current.spacing.lg)
        ) {
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.sm))
            Text(
                "Filter by",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.lg))
            Text(
                "Billing Cycle",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.sm))
            Column {
                listOf("Weekly", "Monthly", "Quarterly", "Yearly").forEach { cycle ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onFilterStateChange(filterState.copy(selectedBillingCycle = cycle)) }
                            .padding(vertical = LocalAppDimensions.current.spacing.sm),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = (filterState.selectedBillingCycle == cycle),
                            onClick = { onFilterStateChange(filterState.copy(selectedBillingCycle = cycle)) }
                        )
                        Text(
                            text = cycle,
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.padding(start = LocalAppDimensions.current.spacing.md)
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.lg))
            Text(
                "Payment Method",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.sm))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(LocalAppDimensions.current.spacing.sm)
            ) {
                paymentMethods.forEach { method ->
                    val selected = filterState.paymentMethods[method] ?: false
                    FilterChip(
                        selected = selected,
                        onClick = {
                            val updatedMethods = filterState.paymentMethods.toMutableMap()
                            updatedMethods[method] = !selected
                            onFilterStateChange(filterState.copy(paymentMethods = updatedMethods))
                        },
                        label = { Text(method) }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SortOptionsSheet(
    onDismiss: () -> Unit,
    selectedOption: SortOption,
    onSelectOption: (SortOption) -> Unit,
    selectedDirection: SortDirection,
    onSelectDirection: (SortDirection) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { BottomSheetDefaults.DragHandle() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LocalAppDimensions.current.spacing.md)
                .padding(bottom = LocalAppDimensions.current.spacing.lg)
        ) {
            Text(
                "Sort by",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.md))
            Column {
                SortOption.entries.forEach { option ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelectOption(option) }
                            .padding(vertical = LocalAppDimensions.current.spacing.sm),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = (selectedOption == option),
                            onClick = { onSelectOption(option) }
                        )
                        Text(
                            text = when (option) {
                                SortOption.DueDate -> "Due Date"
                                SortOption.DateAdded -> "Date Added"
                                else -> option.name
                            },
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.padding(start = LocalAppDimensions.current.spacing.md)
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.lg))
            Text(
                "Direction",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(LocalAppDimensions.current.spacing.md))
            SingleChoiceSegmentedButtonRow(
                modifier = Modifier.fillMaxWidth()
            ) {
                SortDirection.entries.forEachIndexed { index, direction ->
                    SegmentedButton(
                        selected = selectedDirection == direction,
                        onClick = { onSelectDirection(direction) },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = SortDirection.entries.size)
                    ) {
                        Text(direction.name)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PayableCard(
    title: String,
    subtitle: String,
    amountLabel: String,
    badge: String,
    icon: ImageVector,
    backgroundColor: Color,
    customIconUri: String? = null,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit
) {
    val dashboardTheme = LocalDashboardTheme.current
    val dims = LocalAppDimensions.current
    val interactionSource = remember { MutableInteractionSource() }
    
    // Calculate text colors based on background brightness
    val isBackgroundBright = isColorBright(backgroundColor)
    val textColor = if (isBackgroundBright) Color.Black else Color.White
    val secondaryTextColor = if (isBackgroundBright) Color.Black.copy(alpha = 0.7f) else
        Color.White.copy(alpha = 0.7f)
    val iconTint = if (isBackgroundBright) Color.Black else Color.White
    
    // Stacked card corner radius logic
    val cornerRadius = when {
        isFirst && isLast -> RoundedCornerShape(dashboardTheme.groupTopCornerRadius)
        isFirst -> RoundedCornerShape(
            topStart = dashboardTheme.groupTopCornerRadius,
            topEnd = dashboardTheme.groupTopCornerRadius,
            bottomStart = dashboardTheme.groupInnerCornerRadius,
            bottomEnd = dashboardTheme.groupInnerCornerRadius
        )
        isLast -> RoundedCornerShape(
            topStart = dashboardTheme.groupInnerCornerRadius,
            topEnd = dashboardTheme.groupInnerCornerRadius,
            bottomStart = dashboardTheme.groupBottomCornerRadius,
            bottomEnd = dashboardTheme.groupBottomCornerRadius
        )
        else -> RoundedCornerShape(dashboardTheme.groupInnerCornerRadius)
    }
    
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = if (isLast) 0.dp else 2.dp)
            .pressableCard(interactionSource = interactionSource),
        shape = cornerRadius,
        colors = CardDefaults.cardColors(
            containerColor = backgroundColor
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(dims.spacing.card),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier.weight(1f),
                horizontalArrangement = Arrangement.spacedBy(dims.spacing.md),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Service Icon (no container)
                if (customIconUri != null) {
                    var imageModel by remember(customIconUri) { mutableStateOf<Any?>(customIconUri.toUri()) }
                    AsyncImage(
                        model = imageModel,
                        contentDescription = "$title logo",
                        onError = {
                            val currentModel = imageModel.toString()
                            if (currentModel.contains("/symbol")) {
                                imageModel = currentModel.replace("/symbol", "/icon")
                            } else if (currentModel.contains("/icon")) {
                                imageModel = currentModel.replace("/icon", "/logo")
                            }
                        },
                        modifier = Modifier.size(48.dp)
                    )
                } else {
                    // Default Material Icon
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = iconTint,
                        modifier = Modifier.size(48.dp)
                    )
                }

                // Service Details
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.headlineSmall.copy(
                            fontWeight = FontWeight.Medium
                        ),
                        color = textColor,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodyLarge,
                        color = secondaryTextColor,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(dims.spacing.sm))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(dims.spacing.xs)
                    ) {
                        Icon(
                            Icons.Default.CalendarToday,
                            contentDescription = null,
                            tint = secondaryTextColor,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = badge,
                            style = MaterialTheme.typography.bodyMedium,
                            color = secondaryTextColor
                        )
                    }
                }
            }

            // Amount Label
            Surface(
                shape = RoundedCornerShape(dims.spacing.md),
                color = textColor.copy(alpha = 0.16f)
            ) {
                Text(
                    text = amountLabel,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium
                    ),
                    color = textColor,
                    modifier = Modifier.padding(
                        horizontal = dims.spacing.md, 
                        vertical = dims.spacing.sm
                    )
                )
            }
        }
    }
}

// Helper function to determine if a color is bright or dark (from AddPayableScreen)
private fun isColorBright(color: Color): Boolean {
    fun linearize(component: Float): Float {
        return if (component <= 0.04045f) {
            component / 12.92f
        } else {
            (((component + 0.055f) / 1.055f).toDouble().pow(2.4)).toFloat()
        }
    }
    
    val r = linearize(color.red)
    val g = linearize(color.green)
    val b = linearize(color.blue)
    
    val luminance = 0.2126f * r + 0.7152f * g + 0.0722f * b
    return luminance > 0.5f
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onClose: () -> Unit
) {
    val dims = LocalAppDimensions.current
    
    // Add subtle scale animation when search bar appears
    val scale by animateFloatAsState(
        targetValue = 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        )
    )
    
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        placeholder = { 
            Text(
                "Search payables...",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        leadingIcon = { 
            Icon(
                Icons.Default.Search,
                contentDescription = "Search",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(
                        Icons.Default.Clear,
                        contentDescription = "Clear search",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                IconButton(onClick = onClose) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Close search",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        },
        singleLine = true,
        shape = RoundedCornerShape(dims.spacing.md),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = MaterialTheme.colorScheme.primary,
            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
        )
    )
}

// Data class for payable items
data class PayableItemData(
    val id: String = "", // Unique identifier for the payable
    val name: String,
    val planType: String,
    val price: String,
    val currency: String,
    val dueDate: String,
    val icon: ImageVector,
    val backgroundColor: Color,
    val category: String = "Not set",
    val customIconUri: String? = null, // URI for custom imported icons
    val notes: String = "", // Notes field for storing user notes
    val website: String = "", // Website field for storing related URLs
    val paymentMethod: String = "Not set", // Payment method for the payable
    val isPaused: Boolean = false, // Whether the payable is paused
    val isFinished: Boolean = false, // Whether the payable is finished
    val billingStartDate: String = "", // Original billing start date for editing
    val billingCycle: String = "Monthly", // Billing cycle (Monthly, Weekly, Quarterly, Yearly)
    val endDate: String? = null,
    val createdAt: Long = 0L,
    val billingDateMillis: Long = 0L,
    val nextDueDateMillis: Long = 0L
)

enum class SortOption {
    Name,
    Amount,
    DueDate,
    DateAdded
}

enum class SortDirection {
    Ascending,
    Descending
}

data class FilterState(
    val selectedBillingCycle: String? = null,
    val paymentMethods: Map<String, Boolean> = emptyMap()
)

@Preview(showBackground = true)
@Composable
private fun PayableScreenPreview() {
    AppTheme {
        PayableScreen(
            onNavigateToAddPayable = { /* Preview - no navigation */ },
            onPayableClick = { /* Preview - no navigation */ },
            monthlyAmount = "39.52",
            screenTitle = "Entertainment",
            payables = listOf(
                PayableItemData(
                    id = "preview-spotify",
                    name = "Spotify",
                    planType = "Premium Duo",
                    price = "8.99",
                    currency = "EUR",
                    dueDate = "Tomorrow",
                    icon = Icons.Filled.MusicNote,
                    backgroundColor = Color(0xFF1DB954), // Spotify Green
                    category = "Entertainment",
                    notes = "Premium Duo subscription for two accounts",
                    website = "www.spotify.com/account",
                    paymentMethod = "Visa",
                    isFinished = false, // Explicitly active
                    billingStartDate = "October 01, 2024",
                    billingCycle = "Monthly"
                ),
                PayableItemData(
                    id = "preview-netflix",
                    name = "Netflix",
                    planType = "Standard",
                    price = "12.99",
                    currency = "EUR",
                    dueDate = "In 3 days",
                    icon = Icons.Filled.Movie,
                    backgroundColor = Color(0xFFE50914), // Netflix Red
                    category = "Entertainment",
                    notes = "Standard plan with HD streaming",
                    website = "www.netflix.com",
                    paymentMethod = "MasterCard",
                    isFinished = false, // Explicitly active
                    billingStartDate = "September 15, 2024",
                    billingCycle = "Monthly"
                )
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun PayableScreenEmptyPreview() {
    AppTheme {
        PayableScreen(
            onNavigateToAddPayable = { /* Preview - no navigation */ },
            onPayableClick = { /* Preview - no navigation */ },
            monthlyAmount = "0.00"
        )
    }
}