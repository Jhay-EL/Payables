@file:Suppress("AssignedValueIsNeverRead", "COMPOSE_APPLIER_CALL_MISMATCH")

package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.window.PopupProperties
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.core.net.toUri
import coil.compose.AsyncImage
import com.app.payables.data.CustomPaymentMethodRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import android.content.Intent
import com.app.payables.theme.*
import androidx.compose.material.icons.filled.Payment
import com.google.accompanist.systemuicontroller.rememberSystemUiController
import androidx.activity.compose.BackHandler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ViewPayableScreen(
    payable: PayableItemData,
    customPaymentMethodRepository: CustomPaymentMethodRepository? = null,
    onBack: () -> Unit = {},
    onEdit: () -> Unit = {},
    onPause: () -> Unit = {},
    onUnpause: () -> Unit = {},
    onFinish: () -> Unit = {},
    onUnfinish: () -> Unit = {},
    onDelete: () -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    
    // Menu state
    var showTopBarMenu by remember { mutableStateOf(false) }

    // Delete confirmation dialog state
    var showDeleteDialog by remember { mutableStateOf(false) }
    
    // Fade-to-top-bar setup
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    val customPaymentMethods by customPaymentMethodRepository?.getAllCustomPaymentMethods()
        ?.collectAsState(initial = emptyList())
        ?: remember { mutableStateOf(emptyList()) }

    val paymentMethodDetails = remember(payable.paymentMethod, customPaymentMethods) {
        customPaymentMethods.find { it.name == payable.paymentMethod }
    }

    val systemUiController = rememberSystemUiController()
    val useDarkIcons = !isSystemInDarkTheme()

    SideEffect {
        systemUiController.setSystemBarsColor(
            color = Color.Transparent,
            darkIcons = useDarkIcons,
            isNavigationBarContrastEnforced = false
        )
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { 
                    Text(
                        payable.name, 
                        modifier = Modifier.graphicsLayer(alpha = topBarAlpha)
                    ) 
                },
                navigationIcon = { 
                    IconButton(onClick = onBack) { 
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") 
                    } 
                },
                actions = {
                    IconButton(
                        onClick = { showTopBarMenu = !showTopBarMenu }
                    ) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More options")
                    }
                    
                    DropdownMenu(
                        expanded = showTopBarMenu,
                        onDismissRequest = { 
                            android.util.Log.d("ViewPayableDropdown", "onDismissRequest called")
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
                            text = { Text("Edit", style = MaterialTheme.typography.bodyLarge) },
                            onClick = {
                                showTopBarMenu = false
                                onEdit()
                            }
                        )
                        if (!payable.isFinished) {
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        if (payable.isPaused) "Unpause" else "Pause",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = {
                                    showTopBarMenu = false
                                    if (payable.isPaused) onUnpause() else onPause()
                                }
                            )
                        }
                        if (!payable.isPaused) {
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        if (payable.isFinished) "Unfinish" else "Finish",
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                },
                                onClick = {
                                    showTopBarMenu = false
                                    if (payable.isFinished) onUnfinish() else onFinish()
                                }
                            )
                        }
                        DropdownMenuItem(
                            text = { Text("Delete", style = MaterialTheme.typography.bodyLarge) },
                            onClick = {
                                showTopBarMenu = false
                                showDeleteDialog = true
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarColor,
                    scrolledContainerColor = topBarColor
                )
            )
        }
    ) { paddingValues ->
        @Suppress("COMPOSABLE_INVOCATION_KIND_NOT_INFERRED")
        BoxWithConstraints(modifier = Modifier.padding(paddingValues)) {
            val viewportHeight = this.maxHeight

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Icon and Title Section with padding
                Column(
                    modifier = Modifier.padding(horizontal = dims.spacing.md)
                ) {
                    // Y reporter for fade effect
                    Box(Modifier.windowYReporter { y -> 
                        if (titleInitialY == null) titleInitialY = y; titleWindowY = y 
                    })
                    
                    // Content without fade transform to prevent diagonal animation
                    Column {
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        // Icon and Title Section
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .graphicsLayer(
                                    alpha = 1f - fade,
                                    translationY = 12f * fade
                                ),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            // Service Icon (no container)
                            if (payable.customIconUri != null) {
                                var imageModel by remember(payable.customIconUri) { mutableStateOf<Any?>(payable.customIconUri.toUri()) }
                                // Custom icon from URI - maintains natural aspect ratio, no square constraint
                                AsyncImage(
                                    model = imageModel,
                                    contentDescription = "${payable.name} logo",
                                    contentScale = androidx.compose.ui.layout.ContentScale.Fit,
                                    onError = {
                                        val currentModel = imageModel.toString()
                                        if (currentModel.contains("/symbol")) {
                                            imageModel = currentModel.replace("/symbol", "/icon")
                                        } else if (currentModel.contains("/icon")) {
                                            imageModel = currentModel.replace("/icon", "/logo")
                                        }
                                    },
                                    modifier = Modifier
                                        .height(60.dp)
                                        .widthIn(min = 40.dp, max = 120.dp)
                                        .wrapContentWidth()
                                )
                            } else {
                                // Default Material Icon
                                Icon(
                                    imageVector = payable.icon,
                                    contentDescription = "${payable.name} icon",
                                    modifier = Modifier.size(80.dp),
                                    tint = payable.backgroundColor
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(dims.spacing.md))
                            
                            // Title
                            Text(
                                text = payable.name,
                                style = MaterialTheme.typography.headlineLarge,
                                color = MaterialTheme.colorScheme.onSurface,
                                textAlign = TextAlign.Center
                            )
                            
                            // Subtitle (Plan Type)
                            Text(
                                text = payable.planType,
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(top = dims.spacing.xs)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                    }
                }
                
                // Extended Card with fixed content
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = viewportHeight),
                    shape = RoundedCornerShape(
                        topStart = 40.dp,
                        topEnd = 40.dp,
                        bottomStart = 0.dp,
                        bottomEnd = 0.dp
                    ),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                    ),
                    elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(dims.spacing.lg)
                    ) {
                        // === TOP SECTION: Payment Details ===
                        
                        // Amount
                        PayableDetailRow(
                            label = "Amount:",
                            value = when (payable.currency) {
                                "EUR" -> "€${payable.price}"
                                "USD" -> "$${payable.price}"
                                "GBP" -> "£${payable.price}"
                                "JPY" -> "¥${payable.price}"
                                else -> "${payable.currency} ${payable.price}"
                            }
                        )
                        
                        // Converted Amount (if different currency from main)
                        if (payable.convertedPrice != null && payable.mainCurrency != null && payable.currency != payable.mainCurrency) {
                            Spacer(modifier = Modifier.height(dims.spacing.sm))
                            
                            val mainSymbol = when (payable.mainCurrency) {
                                "EUR" -> "€"
                                "USD" -> "$"
                                "GBP" -> "£"
                                "JPY" -> "¥"
                                else -> payable.mainCurrency
                            }
                            
                            PayableDetailRow(
                                label = "In ${payable.mainCurrency}:",
                                value = "$mainSymbol${String.format(java.util.Locale.US, "%.2f", payable.convertedPrice)}"
                            )
                            
                            // Exchange rate (show as 1 main currency = X payable currency)
                            payable.exchangeRate?.let { rate ->
                                Spacer(modifier = Modifier.height(dims.spacing.sm))
                                val invertedRate = 1.0 / rate
                                PayableDetailRow(
                                    label = "Exchange rate:",
                                    value = "1 ${payable.mainCurrency} = ${String.format(java.util.Locale.US, "%.2f", invertedRate)} ${payable.currency}",
                                    valueColor = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        // Billing Cycle
                        PayableDetailRow(
                            label = "Billing Cycle:",
                            value = payable.billingCycle
                        )
                        
                        // Group separator space
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // Next billing date
                        PayableDetailRow(
                            label = "Next billing date:",
                            value = formatNextBillingDate(payable)
                        )
                        
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        // End Date
                        PayableDetailRow(
                            label = "End Date:",
                            value = payable.endDate ?: "N/A"
                        )
                        
                        // Group separator space
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // Payment method
                        PayableDetailRow(
                            label = "Payment method:",
                            value = paymentMethodDetails?.let { "${it.name} •••• ${it.lastFourDigits}" } ?: payable.paymentMethod
                        )
                        
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        // Category
                        PayableDetailRow(
                            label = "Category:",
                            value = payable.category
                        )
                        
                        // Group separator space (consistent with payment details)
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // === BOTTOM SECTIONS: Website and Notes ===
                        val context = LocalContext.current
                        
                        // Website Section
                        PayableDetailRow(
                            label = "Website:",
                            value = payable.website.ifBlank { "Not provided" },
                            valueColor = if (payable.website.isNotBlank()) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            onClick = if (payable.website.isNotBlank()) {
                                {
                                    try {
                                        val url = if (!payable.website.startsWith("http://") && !payable.website.startsWith("https://")) {
                                            "https://${payable.website}"
                                        } else {
                                            payable.website
                                        }
                                        val intent = Intent(Intent.ACTION_VIEW, url.toUri())
                                        context.startActivity(intent)
                                    } catch (_: Exception) {
                                        // Handle cases where the URL is invalid or no browser is available
                                    }
                                }
                            } else {
                                null
                            }
                        )
                        
                        // Group separator space (consistent with payment details groups)
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // Notes Section
                        Text(
                            text = "Notes:",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                        )
                        
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp)
                                .background(
                                    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                                    RoundedCornerShape(16.dp)
                                )
                                .border(
                                    width = 1.dp,
                                    color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                                    shape = RoundedCornerShape(16.dp)
                                )
                                .padding(dims.spacing.md),
                            contentAlignment = Alignment.TopStart
                        ) {
                            if (payable.notes.isNotBlank()) {
                                Text(
                                    text = payable.notes,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            } else {
                                Text(
                                    text = "No notes available",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                            }
                        }
                        
                        // Group separator space (consistent with other groups)
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // === SUBSCRIPTION INFO SECTION ===
                        
                        // Subscribed since
                        PayableDetailRow(
                            label = "Subscribed since:",
                            value = calculateSubscribedSince(payable)
                        )
                        
                        Spacer(modifier = Modifier.height(dims.spacing.md))
                        
                        // Total paid
                        PayableDetailRow(
                            label = "Total paid:",
                            value = calculateTotalPaid(payable) // Calculate based on payable data
                        )
                        
                        // Group separator space
                        Spacer(modifier = Modifier.height(dims.spacing.lg))
                        
                        // === LIST OF PAYMENT DATE SECTION ===
                        
                        // Payment dates list
                        val paymentDates = calculatePaymentDates(payable)
                        var isPaymentDatesExpanded by remember { mutableStateOf(false) }
                        
                        // Clickable header with arrow
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { isPaymentDatesExpanded = !isPaymentDatesExpanded },
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Payment list:",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                                modifier = Modifier.weight(1f)
                            )
                            Text(
                                text = paymentDates.size.toString(),
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                            )
                            Icon(
                                imageVector = if (isPaymentDatesExpanded) Icons.Default.KeyboardArrowDown else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                contentDescription = if (isPaymentDatesExpanded) "Hide payment dates" else "Show payment dates",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                            )
                        }
                        
                        // Show/hide payment dates based on expanded state
                        if (isPaymentDatesExpanded) {
                            Spacer(modifier = Modifier.height(dims.spacing.md))
                            
                            // Show historical payment dates
                            paymentDates.forEach { paymentDate ->
                                PayableDetailRow(
                                    label = paymentDate,
                                    value = "Paid",
                                    valueColor = MaterialTheme.colorScheme.primary
                                )
                                if (paymentDate != paymentDates.last()) {
                                    Spacer(modifier = Modifier.height(dims.spacing.sm))
                                }
                            }
                        }

                        // Bottom spacing for navigation bar
                        val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                        Spacer(Modifier.height(bottomInset))
                    }
                }
            }
        }
    }

    // Delete confirmation dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Payable") },
            text = { Text("Are you sure you want to delete \"${payable.name}\"? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        onDelete()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Handle back button when menu is open (highest priority)
    BackHandler(enabled = showTopBarMenu) {
        android.util.Log.d("ViewPayableBackHandler", "Closing menu")
        showTopBarMenu = false
    }
}

@Composable
private fun PayableDetailRow(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge,
            color = valueColor
        )
    }
}

// Helper function to calculate subscription start date
private fun calculateSubscribedSince(payable: PayableItemData): String {
    // Parse the actual billing start date from payable data
    val startDate = if (payable.billingStartDate.isNotBlank()) {
        try {
            LocalDate.parse(payable.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
        } catch (_: Exception) {
            // Fallback to 6 months ago if parsing fails
            LocalDate.now().minusMonths(6)
        }
    } else {
        // Fallback to 6 months ago if no billing start date
        LocalDate.now().minusMonths(6)
    }
    val formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
    return startDate.format(formatter)
}

// Helper function to calculate total amount paid (in main currency if available)
// If payable is currently paused, only counts cycles up to the pause date
private fun calculateTotalPaid(payable: PayableItemData): String {
    try {
        // Parse the actual billing start date from payable data
        val startDate = if (payable.billingStartDate.isNotBlank()) {
            try {
                LocalDate.parse(payable.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
            } catch (_: Exception) {
                // Fallback to 6 months ago if parsing fails
                LocalDate.now().minusMonths(6)
            }
        } else {
            // Fallback to 6 months ago if no billing start date
            LocalDate.now().minusMonths(6)
        }
        
        // If currently paused or finished, use the respective timestamp as end date; otherwise use today
        val endDate = when {
            payable.isPaused && payable.pausedAtMillis != null -> 
                LocalDate.ofEpochDay(payable.pausedAtMillis / 86_400_000L)
            payable.isFinished && payable.finishedAtMillis != null -> 
                LocalDate.ofEpochDay(payable.finishedAtMillis / 86_400_000L)
            else -> LocalDate.now()
        }
        
        // Calculate the number of billing cycles elapsed based on actual billing cycle
        // Add 1 because the first payment is made on the start date
        val billingCycleLower = payable.billingCycle.lowercase()
        val cyclesElapsed = 1 + when (billingCycleLower) {
            "weekly" -> ChronoUnit.WEEKS.between(startDate, endDate)
            "monthly" -> ChronoUnit.MONTHS.between(startDate, endDate)
            "quarterly" -> ChronoUnit.MONTHS.between(startDate, endDate) / 3
            "yearly" -> ChronoUnit.YEARS.between(startDate, endDate)
            else -> {
                // Debug: Log unexpected billing cycle
                println("DEBUG: Unexpected billing cycle: '${payable.billingCycle}' -> '$billingCycleLower'")
                ChronoUnit.MONTHS.between(startDate, endDate) // Default to monthly
            }
        }
        
        // Get the amount per billing cycle - use converted amount if available (for main currency display)
        val amountPerCycle = if (payable.convertedPrice != null && payable.mainCurrency != null && payable.currency != payable.mainCurrency) {
            payable.convertedPrice
        } else {
            payable.price.toDoubleOrNull() ?: 0.0
        }
        
        // Determine which currency to display
        val displayCurrency = if (payable.convertedPrice != null && payable.mainCurrency != null && payable.currency != payable.mainCurrency) {
            payable.mainCurrency
        } else {
            payable.currency
        }
        
        // Calculate total paid based on actual billing cycles
        val totalPaid = amountPerCycle * cyclesElapsed
        
        // Format the total with currency symbol
        return when (displayCurrency) {
            "EUR" -> "€${String.format(java.util.Locale.US, "%.2f", totalPaid)}"
            "USD" -> "$${String.format(java.util.Locale.US, "%.2f", totalPaid)}"
            "GBP" -> "£${String.format(java.util.Locale.US, "%.2f", totalPaid)}"
            "JPY" -> "¥${String.format(java.util.Locale.US, "%.0f", totalPaid)}"
            else -> "$displayCurrency ${String.format(java.util.Locale.US, "%.2f", totalPaid)}"
        }
    } catch (_: Exception) {
        val displayCurrency = payable.mainCurrency ?: payable.currency
        return "$displayCurrency 0.00"
    }
}

// Helper function to calculate all payment dates from subscription start to present (or pause date)
// If payable is currently paused, only shows payment dates up to the pause date
private fun calculatePaymentDates(payable: PayableItemData): List<String> {
    try {
        // Parse the actual billing start date from payable data
        val subscriptionStart = if (payable.billingStartDate.isNotBlank()) {
            try {
                LocalDate.parse(payable.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
            } catch (_: Exception) {
                // Fallback to 6 months ago if parsing fails
                LocalDate.now().minusMonths(6)
            }
        } else {
            // Fallback to 6 months ago if no billing start date
            LocalDate.now().minusMonths(6)
        }
        
        // If currently paused or finished, use the respective timestamp as end date; otherwise use today
        val endDate = when {
            payable.isPaused && payable.pausedAtMillis != null -> 
                LocalDate.ofEpochDay(payable.pausedAtMillis / 86_400_000L)
            payable.isFinished && payable.finishedAtMillis != null -> 
                LocalDate.ofEpochDay(payable.finishedAtMillis / 86_400_000L)
            else -> LocalDate.now()
        }
        
        val paymentDates = mutableListOf<String>()
        val formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
        
        var currentDate = subscriptionStart
        
        // Generate payment dates based on billing cycle, up to the end date
        while (currentDate <= endDate) {
            paymentDates.add(currentDate.format(formatter))
            
            // Calculate next payment date based on actual billing cycle
            val billingCycleLower = payable.billingCycle.lowercase()
            currentDate = when (billingCycleLower) {
                "weekly" -> currentDate.plusWeeks(1)
                "monthly" -> currentDate.plusMonths(1)
                "quarterly" -> currentDate.plusMonths(3)
                "yearly" -> currentDate.plusYears(1)
                else -> {
                    // Debug: Log unexpected billing cycle
                    println("DEBUG: Unexpected billing cycle in payment dates: '${payable.billingCycle}' -> '$billingCycleLower'")
                    currentDate.plusMonths(1) // Default to monthly
                }
            }
        }
        
        // Return dates in reverse chronological order (most recent first)
        return paymentDates.reversed()
    } catch (_: Exception) {
        // Return empty list if there's an error
        return emptyList()
    }
}

// Helper function to format next billing date as absolute date (MMMM dd, yyyy)
private fun formatNextBillingDate(payable: PayableItemData): String {
    try {
        // Parse the billing start date if available
        val billingStartDate = if (payable.billingStartDate.isNotBlank()) {
            try {
                LocalDate.parse(payable.billingStartDate, DateTimeFormatter.ofPattern("MMMM dd, yyyy"))
            } catch (_: Exception) {
                // Fallback to current date if parsing fails
                LocalDate.now()
            }
        } else {
            // Fallback to current date if no billing start date
            LocalDate.now()
        }
        
        // Calculate the next billing date based on billing cycle
        val today = LocalDate.now()
        var nextBillingDate = billingStartDate
        
        // If billing start date is in the past, calculate the next occurrence
        while (nextBillingDate <= today) {
            val billingCycleLower = payable.billingCycle.lowercase()
            nextBillingDate = when (billingCycleLower) {
                "weekly" -> nextBillingDate.plusWeeks(1)
                "monthly" -> nextBillingDate.plusMonths(1)
                "quarterly" -> nextBillingDate.plusMonths(3)
                "yearly" -> nextBillingDate.plusYears(1)
                else -> {
                    // Debug: Log unexpected billing cycle
                    println("DEBUG: Unexpected billing cycle in next billing date: '${payable.billingCycle}' -> '$billingCycleLower'")
                    nextBillingDate.plusMonths(1) // Default to monthly
                }
            }
        }
        
        // Format as MMMM dd, yyyy
        val formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
        return nextBillingDate.format(formatter)
        
    } catch (_: Exception) {
        // Fallback to current relative format if calculation fails
        return payable.dueDate
    }
}

@Preview(showBackground = true, heightDp = 1500)
@Composable
private fun ViewPayableScreenPreview() {
    AppTheme {
        ViewPayableScreen(
            payable = PayableItemData(
                id = "preview-spotify-view",
                name = "Spotify",
                planType = "Premium Duo",
                price = "9.99",
                currency = "EUR",
                dueDate = "September 5, 2024",
                icon = Icons.Default.Payment,
                backgroundColor = Color(0xFF1DB954),
                category = "Entertainment",
                notes = "Premium Duo subscription for two accounts. Includes ad-free music streaming and offline downloads.",
                website = "www.spotify.com/account",
                paymentMethod = "Visa ****1234",
                isFinished = false,
                billingStartDate = "August 05, 2024",
                billingCycle = "Monthly"
            ),
            onEdit = { /* Preview - no action */ },
            onPause = { /* Preview - no action */ },
            onUnpause = { /* Preview - no action */ },
            onFinish = { /* Preview - no action */ },
            onUnfinish = { /* Preview - no action */ },
            onDelete = { /* Preview - no action */ }
        )
    }
}
