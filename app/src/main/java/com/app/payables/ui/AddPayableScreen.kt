@file:Suppress("AssignedValueIsNeverRead", "unused")

package com.app.payables.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import android.net.Uri
import androidx.core.net.toUri
import com.app.payables.data.CurrencyList
import com.app.payables.data.Currency
import com.app.payables.data.CustomPaymentMethod
import com.app.payables.data.CustomPaymentMethodRepository
import com.app.payables.theme.*
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.animation.AnimatedContent
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import coil.compose.AsyncImage
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.platform.LocalContext
import com.app.payables.util.isColorBright
import com.app.payables.util.SettingsManager
import com.app.payables.util.InputValidator
// Screen state for transitions
private enum class AddPayableScreenState {
    Main, CustomIcons, CustomColor, CustomPaymentMethod
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddPayableScreen(
    onBack: () -> Unit = {},
    onSave: () -> Unit = {},
    payableRepository: com.app.payables.data.PayableRepository? = null,
    categoryRepository: com.app.payables.data.CategoryRepository? = null,
    customPaymentMethodRepository: CustomPaymentMethodRepository? = null,
    editingPayable: PayableItemData? = null // Optional payable for editing
) {
    val dims = LocalAppDimensions.current

    val isDarkTheme = isSystemInDarkTheme()
    val defaultHeaderColor = if (isDarkTheme) Color(0xFF26272e) else Color(0xFFf0eff7)

    val context = LocalContext.current
    val settingsManager = remember { SettingsManager(context) }
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Form state
    val dateFormatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
    
    // Pre-populate form fields if editing an existing payable
    var title by remember { mutableStateOf(TextFieldValue(editingPayable?.name ?: "")) }
    var amount by remember { mutableStateOf(TextFieldValue(editingPayable?.price ?: "")) }
    var description by remember { mutableStateOf(TextFieldValue(editingPayable?.planType ?: "")) }
    var isRecurring by remember { mutableStateOf(true) } // Default to recurring for now
    var billingDate by remember { 
        mutableStateOf(
            editingPayable?.let { payable ->
                // Parse the billing start date from the existing payable
                try {
                    if (payable.billingStartDate.isNotBlank()) {
                        LocalDate.parse(payable.billingStartDate, dateFormatter)
                    } else {
                        LocalDate.now()
                    }
                } catch (_: Exception) {
                    LocalDate.now()
                }
            } ?: LocalDate.now()
        ) 
    }
    var endDate by remember { 
        mutableStateOf(
            editingPayable?.endDate?.let {
                try {
                    LocalDate.parse(it, dateFormatter)
                } catch (_: Exception) {
                    null
                }
            }
        ) 
    }
    var showBillingDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    val cycles = listOf("Monthly", "Weekly", "Quarterly", "Yearly")
    var cycleExpanded by remember { mutableStateOf(false) }
    var selectedCycle by remember { mutableStateOf(editingPayable?.billingCycle ?: cycles.first()) }
    val currencies = CurrencyList.all
    var currencyExpanded by remember { mutableStateOf(false) }
    var selectedCurrency by remember { mutableStateOf(editingPayable?.currency ?: settingsManager.getDefaultCurrency()) }
    var selectedCategory by remember { mutableStateOf(editingPayable?.category ?: "Not set") }
    var categoryExpanded by remember { mutableStateOf(false) }
    var paymentMethod by remember { mutableStateOf(editingPayable?.paymentMethod ?: "Not set") }
    var paymentExpanded by remember { mutableStateOf(false) }
    var website by remember { mutableStateOf(TextFieldValue(editingPayable?.website ?: "")) }
    var notes by remember { mutableStateOf(TextFieldValue(editingPayable?.notes ?: "")) }
    var selectedIcon by remember { mutableStateOf(editingPayable?.customIconUri?.toUri()) }
    var selectedColor by remember { mutableStateOf(editingPayable?.backgroundColor ?: defaultHeaderColor) }
    var tempColor by remember { mutableStateOf(editingPayable?.backgroundColor ?: defaultHeaderColor) }
    var screenState by remember { mutableStateOf(AddPayableScreenState.Main) }
    var editingPaymentMethod by remember { mutableStateOf<CustomPaymentMethod?>(null) }

    val canSave = title.text.isNotBlank()
    val saveableStateHolder = rememberSaveableStateHolder()
    val coroutineScope = rememberCoroutineScope()
    
    // Load categories from database
    val categories by categoryRepository?.getAllCategories()?.collectAsState(initial = emptyList())
        ?: remember { mutableStateOf(emptyList()) }

    // Load custom payment methods from database
    val customPaymentMethods by customPaymentMethodRepository?.getAllCustomPaymentMethods()?.collectAsState(initial = emptyList())
        ?: remember { mutableStateOf(emptyList()) }
    
    // Create category options list with "Not set" as first option
    val categoryOptions = remember(categories) {
        listOf("Not set") + categories.map { it.name }
    }

    // Create payment method options list with custom payment methods
    val paymentMethodOptions = remember(customPaymentMethods) {
        val customMethods = customPaymentMethods.map { method ->
            if (method.lastFourDigits.isNotBlank()) {
                "${method.name} •••• ${method.lastFourDigits}"
            } else {
                method.name
            }
        }
        listOf("Not set", "Credit Card", "Debit Card", "Bank Transfer", "Custom") + customMethods
    }
    
    // Validation State
    var titleError by remember { mutableStateOf<String?>(null) }
    var amountError by remember { mutableStateOf<String?>(null) }
    var websiteError by remember { mutableStateOf<String?>(null) }

    // Save payable to database (handles both insert and update)
    @ComposableTarget(applier = "androidx.compose.ui.UiComposable")
    fun savePayableToDatabase() {
        // Reset errors
        titleError = null
        amountError = null
        websiteError = null

        // Validate Input
        val titleResult = InputValidator.validateTitle(title.text)
        val amountResult = InputValidator.validateAmount(amount.text)
        val websiteResult = InputValidator.validateUrl(website.text)

        if (!titleResult.successful) {
            titleError = titleResult.errorMessage
        }
        if (!amountResult.successful) {
            amountError = amountResult.errorMessage
        }
        if (!websiteResult.successful) {
            websiteError = websiteResult.errorMessage
        }

        if (!titleResult.successful || !amountResult.successful || !websiteResult.successful) {
            return
        }

        if (payableRepository != null) {
            coroutineScope.launch {
                try {
                    // Handle both custom icons (URIs) and default Material Icons
                    val iconName = "Payment" // Always use default for now since we have customIconUri
                    val customIconUri = selectedIcon?.toString() // Convert Uri to String for storage
                    
                    // Fetch exchange rate data for currency conversion
                    val mainCurrency = settingsManager.getDefaultCurrency()
                    var savedMainCurrency: String? = null
                    var savedExchangeRate: Double? = null
                    var savedConvertedPrice: Double? = null
                    
                    // Only calculate conversion if payable currency differs from main currency
                    if (selectedCurrency != mainCurrency) {
                        try {
                            val app = context.applicationContext as? com.app.payables.PayablesApplication
                            val currencyExchangeRepository = app?.currencyExchangeRepository
                            if (currencyExchangeRepository != null) {
                                // Ensure rates are updated
                                currencyExchangeRepository.ensureRatesUpdated(mainCurrency)
                                
                                // Get the rate for the payable's currency
                                val rate = currencyExchangeRepository.getExchangeRate(selectedCurrency, mainCurrency)
                                if (rate != null) {
                                    val amountValue = amount.text.trim().toDoubleOrNull() ?: 0.0
                                    // rate is how many of source currency equals 1 main currency
                                    // So convertedPrice = amountValue / rate
                                    savedMainCurrency = mainCurrency
                                    savedExchangeRate = 1.0 / rate // 1 payable currency = X main currency
                                    savedConvertedPrice = amountValue / rate
                                }
                            }
                        } catch (e: Exception) {
                            // If exchange rate fetch fails, continue without it
                            android.util.Log.e("AddPayableScreen", "Failed to fetch exchange rate", e)
                        }
                    }
                    
                    if (editingPayable != null) {
                        // Update existing payable
                        val updatedPayable = com.app.payables.data.Payable.create(
                            id = editingPayable.id, // Use existing ID
                            title = title.text.trim(),
                            amount = amount.text.trim(),
                            description = description.text.trim(),
                            isRecurring = isRecurring,
                            billingDate = billingDate,
                            endDate = if (isRecurring) endDate else null,
                            billingCycle = selectedCycle,
                            currency = selectedCurrency,
                            category = selectedCategory,
                            paymentMethod = paymentMethod,
                            website = website.text.trim(),
                            notes = notes.text.trim(),
                            iconName = iconName,
                            customIconUri = customIconUri,
                            color = selectedColor,
                            iconColor = tempColor,
                            savedMainCurrency = savedMainCurrency,
                            savedExchangeRate = savedExchangeRate,
                            savedConvertedPrice = savedConvertedPrice
                        )
                        payableRepository.updatePayable(updatedPayable)
                    } else {
                        // Insert new payable
                        payableRepository.insertPayable(
                            id = java.util.UUID.randomUUID().toString(),
                            title = title.text.trim(),
                            amount = amount.text.trim(),
                            description = description.text.trim(),
                            isRecurring = isRecurring,
                            billingDate = billingDate,
                            endDate = if (isRecurring) endDate else null,
                            billingCycle = selectedCycle,
                            currency = selectedCurrency,
                            category = selectedCategory,
                            paymentMethod = paymentMethod,
                            website = website.text.trim(),
                            notes = notes.text.trim(),
                            iconName = iconName,
                            customIconUri = customIconUri,
                            color = selectedColor,
                            iconColor = tempColor,
                            categoryRepository = categoryRepository,
                            savedMainCurrency = savedMainCurrency,
                            savedExchangeRate = savedExchangeRate,
                            savedConvertedPrice = savedConvertedPrice
                        )
                    }
                    onSave() // Call the callback after successful save
                } catch (_: Exception) {
                    // Handle error - in a real app you might show a snack bar or dialog
                }
            }
        } else {
            // If no repository, just call the callback (for preview/testing)
            onSave()
        }
    }

    // BackHandler removed - DashboardScreen now handles all back navigation
    // Internal screen state changes are handled by onBack callbacks

    AnimatedContent(
        targetState = screenState,
        transitionSpec = AppTransitions.materialSharedAxisHorizontal(
            isForward = { initial, target -> 
                when {
                    initial == AddPayableScreenState.Main && target != AddPayableScreenState.Main -> true
                    initial != AddPayableScreenState.Main && target == AddPayableScreenState.Main -> false
                    else -> true
                }
            },
            durationMillis = 260,
            fadeDurationMillis = 140,
            distanceFraction = 0.22f,
            clip = true
        ),
        contentKey = { it },
        modifier = Modifier.fillMaxSize()
    ) { state ->
        saveableStateHolder.SaveableStateProvider(state) {
            when (state) {
                AddPayableScreenState.Main -> MainAddPayableContent(
                    dims = dims,
                    topBarAlpha = topBarAlpha,
                    topBarColor = topBarColor,
                    scrollBehavior = scrollBehavior,
                    onBack = onBack,
                    onSave = ::savePayableToDatabase,
                    canSave = canSave,
                    isEditMode = editingPayable != null,
                    onTitleYUpdate = { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y },
                    title = title,
                    onTitleChange = { title = it },
                    amount = amount,
                    onAmountChange = { newValue ->
                        val filtered = newValue.text.filter { it.isDigit() || it == '.' }
                        val parts = filtered.split('.')
                        val cleanText = if (parts.size > 2) {
                            parts.take(2).joinToString(".")
                        } else {
                            filtered
                        }
                        amount = TextFieldValue(cleanText, selection = TextRange(cleanText.length))
                    },
                    description = description,
                    onDescriptionChange = { description = it },
                    selectedCurrency = selectedCurrency,
                    currencyExpanded = currencyExpanded,
                    onCurrencyExpandedChange = { currencyExpanded = it },
                    onCurrencySelect = { code -> selectedCurrency = code },
                    currencies = currencies,
                    isRecurring = isRecurring,
                    onRecurringChange = { isRecurring = it },
                    billingDate = billingDate,
                    onShowBillingDatePicker = { showBillingDatePicker = true },
                    endDate = endDate,
                    onEndDateChange = { endDate = it },
                    onShowEndDatePicker = { showEndDatePicker = true },
                    selectedCycle = selectedCycle,
                    cycleExpanded = cycleExpanded,
                    onCycleExpandedChange = { cycleExpanded = it },
                    onCycleSelect = { selectedCycle = it },
                    cycles = cycles,
                    selectedCategory = selectedCategory,
                    categoryExpanded = categoryExpanded,
                    onCategoryExpandedChange = { categoryExpanded = it },
                    onCategorySelect = { selectedCategory = it },
                    categoryOptions = categoryOptions,
                    paymentMethodOptions = paymentMethodOptions,
                    paymentMethod = paymentMethod,
                    paymentExpanded = paymentExpanded,
                    onPaymentExpandedChange = { paymentExpanded = it },
                    onPaymentSelect = { selected ->
                        // If user selects "Custom", open the custom payment method screen
                        if (selected == "Custom") {
                            screenState = AddPayableScreenState.CustomPaymentMethod
                        } else {
                            paymentMethod = selected
                        }
                    },
                    selectedIcon = selectedIcon,
                    selectedColor = selectedColor,
                    tempColor = tempColor,
                    screenState = screenState,
                    onColorSelect = { color ->
                        selectedColor = color
                        tempColor = color
                    },
                    onOpenCustomColor = { 
                        tempColor = selectedColor
                        screenState = AddPayableScreenState.CustomColor
                    },
                    onOpenCustomIcons = { screenState = AddPayableScreenState.CustomIcons },
                    onOpenCustomPaymentMethod = {
                        editingPaymentMethod = null // Clear editing state for new payment method
                        screenState = AddPayableScreenState.CustomPaymentMethod
                    },
                    customPaymentMethods = customPaymentMethods,
                    onEditCustomPayment = { customMethod ->
                        // Set the payment method being edited and open the edit screen
                        editingPaymentMethod = customMethod
                        screenState = AddPayableScreenState.CustomPaymentMethod
                    },
                    website = website,
                    onWebsiteChange = { website = it },
                    notes = notes,
                    onNotesChange = { notes = it },
                    titleError = titleError,
                    amountError = amountError,
                    websiteError = websiteError
                )
                
                AddPayableScreenState.CustomIcons -> CustomIconsScreen(
                    onBack = { screenState = AddPayableScreenState.Main },
                    onPick = { uri ->
                        selectedIcon = uri
                        screenState = AddPayableScreenState.Main
                    }
                )
                
                AddPayableScreenState.CustomColor -> CustomColorScreen(
                    onBack = { 
                        selectedColor = tempColor
                        screenState = AddPayableScreenState.Main
                    },
                    onPick = { color ->
                        tempColor = color
                    }
                )

                AddPayableScreenState.CustomPaymentMethod -> CustomPaymentScreen(
                    customPaymentMethodRepository = customPaymentMethodRepository,
                    onSave = { customPaymentMethod ->
                        // Add the custom payment method to the payment method value
                        paymentMethod = customPaymentMethod.name
                        screenState = AddPayableScreenState.Main
                    },
                    onCancel = {
                        screenState = AddPayableScreenState.Main
                    },
                    onDelete = {
                        screenState = AddPayableScreenState.Main
                    },
                    editingPaymentMethod = editingPaymentMethod
                )
            }
        }
    }

    BackHandler(enabled = screenState != AddPayableScreenState.Main) {
        // Handle back navigation within the AddPayableScreen's own states
        when (screenState) {
            AddPayableScreenState.CustomColor -> {
                selectedColor = tempColor
                screenState = AddPayableScreenState.Main
            }
            AddPayableScreenState.CustomIcons -> screenState = AddPayableScreenState.Main
            AddPayableScreenState.CustomPaymentMethod -> screenState = AddPayableScreenState.Main
            else -> {
                // Should not happen, but as a fallback, call the main onBack
                onBack()
            }
        }
    }

    // Date picker dialogs
    if (showBillingDatePicker) {
        Dialog(
            onDismissRequest = { showBillingDatePicker = false },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            val datePickerState = rememberDatePickerState(
                initialSelectedDateMillis = billingDate.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
            )
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = { Text("Select Billing Date") },
                        navigationIcon = {
                            IconButton(onClick = { showBillingDatePicker = false }) {
                                Icon(Icons.Filled.Close, contentDescription = "Close")
                            }
                        },
                        actions = {
                            TextButton(
                                onClick = {
                                    datePickerState.selectedDateMillis?.let { millis ->
                                        billingDate = LocalDate.ofEpochDay(millis / com.app.payables.data.Payable.MILLIS_PER_DAY)
                                    }
                                    showBillingDatePicker = false
                                }
                            ) {
                                Text("Save")
                            }
                        }
                    )
                }
            ) { paddingValues ->
                DatePicker(
                    state = datePickerState,
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }

    if (showEndDatePicker) {
        Dialog(
            onDismissRequest = { showEndDatePicker = false },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            val datePickerState = rememberDatePickerState(
                initialSelectedDateMillis = endDate?.atStartOfDay(ZoneOffset.UTC)?.toInstant()?.toEpochMilli()
            )
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = { Text("Select End Date") },
                        navigationIcon = {
                            IconButton(onClick = { showEndDatePicker = false }) {
                                Icon(Icons.Filled.Close, contentDescription = "Close")
                            }
                        },
                        actions = {
                            TextButton(
                                onClick = {
                                    datePickerState.selectedDateMillis?.let { millis ->
                                        endDate = LocalDate.ofEpochDay(millis / com.app.payables.data.Payable.MILLIS_PER_DAY)
                                    }
                                    showEndDatePicker = false
                                }
                            ) {
                                Text("Save")
                            }
                        }
                    )
                }
            ) { paddingValues ->
                DatePicker(
                    state = datePickerState,
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainAddPayableContent(
    dims: AppDimensions,
    topBarAlpha: Float,
    topBarColor: Color,
    scrollBehavior: TopAppBarScrollBehavior,
    onBack: () -> Unit,
    onSave: () -> Unit,
    canSave: Boolean,
    isEditMode: Boolean = false,
    onTitleYUpdate: (Int) -> Unit,
    title: TextFieldValue,
    onTitleChange: (TextFieldValue) -> Unit,
    amount: TextFieldValue,
    onAmountChange: (TextFieldValue) -> Unit,
    description: TextFieldValue,
    onDescriptionChange: (TextFieldValue) -> Unit,
    selectedCurrency: String,
    currencyExpanded: Boolean,
    onCurrencyExpandedChange: (Boolean) -> Unit,
    onCurrencySelect: (String) -> Unit,
    currencies: List<Currency>,
    isRecurring: Boolean,
    onRecurringChange: (Boolean) -> Unit,
    billingDate: LocalDate,
    onShowBillingDatePicker: () -> Unit,
    endDate: LocalDate?,
    onEndDateChange: (LocalDate?) -> Unit,
    onShowEndDatePicker: () -> Unit,
    selectedCycle: String,
    cycleExpanded: Boolean,
    onCycleExpandedChange: (Boolean) -> Unit,
    onCycleSelect: (String) -> Unit,
    cycles: List<String>,
    selectedCategory: String,
    categoryExpanded: Boolean,
    onCategoryExpandedChange: (Boolean) -> Unit,
    onCategorySelect: (String) -> Unit,
    categoryOptions: List<String>,
    paymentMethodOptions: List<String>,
    paymentMethod: String,
    paymentExpanded: Boolean,
    onPaymentExpandedChange: (Boolean) -> Unit,
    onPaymentSelect: (String) -> Unit,
    selectedIcon: Uri?,
    selectedColor: Color,
    tempColor: Color,
    screenState: AddPayableScreenState,
    onColorSelect: (Color) -> Unit,
    onOpenCustomColor: () -> Unit,
    onOpenCustomIcons: () -> Unit,
    onOpenCustomPaymentMethod: () -> Unit,
    customPaymentMethods: List<CustomPaymentMethod> = emptyList(),
    onEditCustomPayment: ((CustomPaymentMethod) -> Unit)? = null,
    website: TextFieldValue,
    onWebsiteChange: (TextFieldValue) -> Unit,
    notes: TextFieldValue,
    onNotesChange: (TextFieldValue) -> Unit,
    titleError: String? = null,
    amountError: String? = null,
    websiteError: String? = null
) {
    val dateFormatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy")
    
    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text(if (isEditMode) "Edit Payable" else "New Payable", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } },
                actions = { TextButton(onClick = onSave, enabled = canSave) { Text("Save") } },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarColor,
                    scrolledContainerColor = topBarColor
                )
            )
        }
    ) { paddingValues ->
        val scrollState = rememberScrollState()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = dims.spacing.md)
                .verticalScroll(scrollState)
        ) {
            // Y reporter for header fade
            Box(Modifier.windowYReporter { y -> onTitleYUpdate(y) })

            // Header card similar to screenshot
            val selectedCurrencyData = currencies.find { it.code == selectedCurrency }
            val currencySymbol = selectedCurrencyData?.symbol ?: "€"
            HeaderCard(
                title = title.text.ifBlank { if (isEditMode) "Edit Payable" else "New Payable" },
                amountLabel = "$currencySymbol ${amount.text.ifEmpty { "0.00" }}",
                subtitle = description.text.ifBlank { "No description" },
                badge = "Due ${formatBillingDateRelative(billingDate, selectedCycle)}",
                customIcon = selectedIcon,
                backgroundColor = if (screenState == AddPayableScreenState.CustomColor) tempColor else selectedColor
            )

            Spacer(Modifier.height(dims.spacing.section))

            // Payable Information
            SectionHeader("Payable Information")
            OutlinedTextField(
                value = title,
                onValueChange = onTitleChange,
                modifier = Modifier
                    .fillMaxWidth(),
                label = { Text("Title") },
                leadingIcon = { Icon(Icons.Filled.TextFields, contentDescription = null) },
                singleLine = true,
                isError = titleError != null,
                supportingText = titleError?.let { { Text(it) } }
            )
            Spacer(Modifier.height(dims.spacing.md))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = amount,
                    onValueChange = onAmountChange,
                    modifier = Modifier.weight(2f),
                    label = { Text("Amount") },
                    leadingIcon = { Text(currencySymbol) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    isError = amountError != null,
                    supportingText = amountError?.let { { Text(it) } }
                )
                CurrencyDropdownField(
                    selectedCurrency = selectedCurrency,
                    expanded = currencyExpanded,
                    onExpandedChange = onCurrencyExpandedChange,
                    currencies = currencies,
                    onSelect = onCurrencySelect,
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(Modifier.height(dims.spacing.md))
            OutlinedTextField(
                value = description,
                onValueChange = onDescriptionChange,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Plan Details") },
                leadingIcon = { Icon(Icons.Filled.Description, contentDescription = null) },
                singleLine = true
            )

            Spacer(Modifier.height(dims.spacing.section))

            // Recurring toggle
            SingleChoiceSegmentedButtonRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
            ) {
                SegmentedButton(
                    selected = isRecurring,
                    onClick = { onRecurringChange(true) },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                    icon = {
                        SegmentedButtonDefaults.Icon(active = isRecurring) {
                            Icon(Icons.Filled.Repeat, contentDescription = null)
                        }
                    },
                    label = { Text("Recurring") }
                )
                SegmentedButton(
                    selected = !isRecurring,
                    onClick = { onRecurringChange(false) },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                    icon = {
                        SegmentedButtonDefaults.Icon(active = !isRecurring) {
                            Icon(Icons.Filled.Event, contentDescription = null)
                        }
                    },
                    label = { Text("One time") }
                )
            }

            Spacer(Modifier.height(dims.spacing.section))

            // Billing Information
            SectionHeader("Billing Information")
            OutlinedTextField(
                value = billingDate.format(dateFormatter),
                onValueChange = {},
                readOnly = true,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Billing Date") },
                trailingIcon = {
                    IconButton(onClick = onShowBillingDatePicker) {
                        Icon(Icons.Filled.Event, contentDescription = "Select date")
                    }
                }
            )
            if (isRecurring) {
                Spacer(Modifier.height(dims.spacing.md))
                OutlinedTextField(
                    value = endDate?.format(dateFormatter) ?: "",
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("End Date (Optional)") },
                    trailingIcon = {
                        Row {
                            if (endDate != null) {
                                IconButton(onClick = { onEndDateChange(null) }) {
                                    Icon(Icons.Filled.Close, contentDescription = "Clear")
                                }
                            }
                            IconButton(onClick = onShowEndDatePicker) {
                                Icon(Icons.Filled.Event, contentDescription = "Select date")
                            }
                        }
                    }
                )
                Spacer(Modifier.height(dims.spacing.md))
                ExposedDropdownField(
                    label = "Billing Cycle",
                    value = selectedCycle,
                    expanded = cycleExpanded,
                    onExpandedChange = onCycleExpandedChange,
                    options = cycles,
                    onSelect = onCycleSelect,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(Modifier.height(dims.spacing.section))
            } else {
                Spacer(Modifier.height(dims.spacing.section))
            }

            // Category & Payment
            SectionHeader("Category & Payment")
            ExposedDropdownField(
                label = "Category",
                value = selectedCategory,
                expanded = categoryExpanded,
                onExpandedChange = onCategoryExpandedChange,
                options = categoryOptions,
                onSelect = onCategorySelect,
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = { Icon(Icons.Filled.Category, contentDescription = null) }
            )
            Spacer(Modifier.height(dims.spacing.md))
            ExposedDropdownField(
                label = "Payment Method",
                value = paymentMethod,
                expanded = paymentExpanded,
                onExpandedChange = onPaymentExpandedChange,
                options = paymentMethodOptions,
                onSelect = { selected ->
                    // If user selects "Custom", open the custom payment method screen
                    if (selected == "Custom") {
                        onOpenCustomPaymentMethod()
                    } else {
                        // Check if this is a custom payment method (contains "••••")
                        if (selected.contains("••••")) {
                            // Extract the method name (everything before "••••")
                            val methodName = selected.substringBefore(" ••••").trim()
                            onPaymentSelect(methodName)
                        } else {
                            onPaymentSelect(selected)
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = { Icon(Icons.Filled.CreditCard, contentDescription = null) },
                customPaymentMethods = customPaymentMethods,
                onEditCustomPayment = onEditCustomPayment
            )

            Spacer(Modifier.height(dims.spacing.section))

            // Customization (stacked cards style like Dashboard)
            SectionHeader("Customization")
            CustomizationOptionCard(
                title = "Color",
                subtitle = "Choose theme color for your payable",
                icon = Icons.Filled.Palette,
                onClick = onOpenCustomColor,
                isFirst = true,
                isLast = false,
                additionalContent = {
                    ColorSwatchesRow(
                        options = listOf(
                            Color(0xFF2196F3), // Blue
                            Color(0xFFF44336), // Red
                            Color(0xFF4CAF50), // Green
                            Color(0xFFFFFFFF), // White
                            Color(0xFF000000)  // Black
                        ),
                        selected = selectedColor,
                        onSelect = onColorSelect,
                        onOpenCustom = onOpenCustomColor
                    )
                }
            )
            CustomizationOptionCard(
                title = "Choose Icon",
                subtitle = "Browse and select from icon library",
                icon = Icons.Filled.GridView,
                onClick = onOpenCustomIcons,
                isFirst = false,
                isLast = true,
                selectedIconUri = selectedIcon,
                iconTint = selectedColor
            )

            Spacer(Modifier.height(dims.spacing.section))

            // Additional Details
            SectionHeader("Additional Details")
            OutlinedTextField(
                value = website,
                onValueChange = onWebsiteChange,
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = { Icon(Icons.Filled.Link, contentDescription = null) },
                placeholder = { Text("Website (Optional)") },
                singleLine = true,
                isError = websiteError != null,
                supportingText = { websiteError?.let { Text(it) } }
            )
            Spacer(Modifier.height(dims.spacing.md))
            OutlinedTextField(
                value = notes,
                onValueChange = onNotesChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 140.dp),
                label = { Text("Notes (Optional)") }
            )

            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CustomizationOptionCard(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
    iconTint: Color? = null,
    iconContainerColor: Color? = null,
    additionalContent: (@Composable () -> Unit)? = null,
    selectedIconUri: Uri? = null
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
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f),
            contentColor = MaterialTheme.colorScheme.onSurface,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f),
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        interactionSource = interactionSource
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(LocalAppDimensions.current.spacing.card)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(
                            iconContainerColor ?: MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.41f),
                            RoundedCornerShape(16.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (selectedIconUri != null) {
                        var imageModel by remember(selectedIconUri) { mutableStateOf<Any?>(selectedIconUri) }
                        AsyncImage(
                            model = imageModel,
                            contentDescription = "Selected Icon",
                            onError = {
                                val currentModel = imageModel.toString()
                                if (currentModel.contains("/symbol")) {
                                    imageModel = currentModel.replace("/symbol", "/icon")
                                } else if (currentModel.contains("/icon")) {
                                    imageModel = currentModel.replace("/icon", "/logo")
                                }
                            },
                            modifier = Modifier.size(24.dp)
                        )
                    } else {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                            tint = iconTint ?: MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
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
            
            // Additional content below the main row
            additionalContent?.let { content ->
                Spacer(Modifier.height(12.dp))
                content()
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

@Composable
private fun HeaderCard(
    title: String,
    amountLabel: String,
    subtitle: String,
    badge: String,
    customIcon: Uri? = null,
    backgroundColor: Color = MaterialTheme.colorScheme.surfaceColorAtElevation(6.dp)
) {
    // Calculate if the background is bright or dark to determine text color
    val isBackgroundBright = isColorBright(backgroundColor)
    val textColor = if (isBackgroundBright) Color.Black else Color.White
    val secondaryTextColor = if (isBackgroundBright) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f)
    val iconTint = if (isBackgroundBright) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f)
    val dims = LocalAppDimensions.current
    Card(
        modifier = Modifier
            .fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = backgroundColor
        )
    ) {
        Column(modifier = Modifier.padding(dims.spacing.card)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Icon aligned to center of content
                if (customIcon != null) {
                    var imageModel by remember(customIcon) { mutableStateOf<Any?>(customIcon) }
                    // Custom icon - maintains natural aspect ratio, no square constraint
                    AsyncImage(
                        model = imageModel,
                        contentDescription = "Brand Logo",
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
                    // Default icon with background container
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .background(MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.25f), RoundedCornerShape(16.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.Dashboard, contentDescription = null)
                    }
                }

                // Main content column with title, subtitle, and badge
                Column(modifier = Modifier.weight(1f).padding(start = 16.dp)) {
                    // Title and subtitle in a column
                    Text(title, style = MaterialTheme.typography.titleLarge,fontWeight = FontWeight.Bold, color = textColor)

                    Spacer(Modifier.height(4.dp))

                    Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = secondaryTextColor)

                    Spacer(Modifier.height(12.dp))

                    // Badge row
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Event, contentDescription = null, tint = iconTint)
                        Spacer(Modifier.width(8.dp))
                        Text(badge, style = MaterialTheme.typography.bodyMedium, color = secondaryTextColor)
                    }
                }

                // Amount label on the right
                Box(
                    modifier = Modifier
                        .background(textColor.copy(alpha = 0.16f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 14.dp)
                ) { Text(amountLabel, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = textColor) }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ExposedDropdownField(
    label: String,
    value: String,
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    options: List<String>,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
    leadingIcon: (@Composable () -> Unit)? = null,
    customPaymentMethods: List<CustomPaymentMethod> = emptyList(),
    onEditCustomPayment: ((CustomPaymentMethod) -> Unit)? = null
) {
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = onExpandedChange, modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = {},
            readOnly = true,
            modifier = Modifier.menuAnchor().fillMaxWidth(),
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            leadingIcon = leadingIcon
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { onExpandedChange(false) }) {
            options.forEach { option ->
                // Check if this option is a custom payment method
                val customMethod = customPaymentMethods.find { method ->
                    val displayText = if (method.lastFourDigits.isNotBlank()) {
                        "${method.name} •••• ${method.lastFourDigits}"
                    } else {
                        method.name
                    }
                    displayText == option
                }

                if (customMethod != null) {
                    // Custom payment method - show with edit button
                    DropdownMenuItem(
                        text = { Text(option) },
                        onClick = { onSelect(option); onExpandedChange(false) },
                        trailingIcon = {
                            IconButton(
                                onClick = {
                                    onEditCustomPayment?.invoke(customMethod)
                                    onExpandedChange(false)
                                },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    Icons.Filled.Edit,
                                    contentDescription = "Edit ${customMethod.name}",
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                    )
                } else {
                    // Standard payment method - no edit button
                    DropdownMenuItem(
                        text = {
                            val color = if (option == "Custom") MaterialTheme.colorScheme.primary else Color.Unspecified
                            Text(option, color = color)
                        },
                        onClick = { onSelect(option); onExpandedChange(false) }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CurrencyDropdownField(
    selectedCurrency: String,
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    currencies: List<Currency>,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = onExpandedChange, modifier = modifier) {
        OutlinedTextField(
            value = selectedCurrency,
            onValueChange = {},
            readOnly = true,
            modifier = Modifier.menuAnchor().fillMaxWidth(),
            label = { Text("Currency") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) }
        )
        ExposedDropdownMenu(
            expanded = expanded, 
            onDismissRequest = { onExpandedChange(false) },
            modifier = Modifier
                .heightIn(max = 320.dp) // Make dropdown larger
                .widthIn(min = 180.dp) // Make dropdown wider
        ) {
            currencies.forEach { currency ->
                DropdownMenuItem(
                    text = { Text(currency.code) }, 
                    onClick = { 
                        onSelect(currency.code)
                        onExpandedChange(false) 
                    }
                )
            }
        }
    }
}

@Composable
private fun ColorSwatchesRow(
    options: List<Color>,
    selected: Color,
    onSelect: (Color) -> Unit,
    onOpenCustom: (() -> Unit)? = null
) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        options.forEach { option ->
            val border = if (option == selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
            val interactionSource = remember { MutableInteractionSource() }
            
            Surface(
                onClick = { onSelect(option) },
                modifier = Modifier.size(36.dp),
                shape = RoundedCornerShape(18.dp),
                color = option,
                border = BorderStroke(width = 2.dp, color = border),
                interactionSource = interactionSource
            ) {
                // Empty content - just the colored surface
            }
        }
        if (onOpenCustom != null) {
            // Custom color button
            val interactionSource = remember { MutableInteractionSource() }
            Surface(
                onClick = onOpenCustom,
                modifier = Modifier.size(36.dp),
                shape = RoundedCornerShape(18.dp),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
                border = BorderStroke(width = 2.dp, color = MaterialTheme.colorScheme.primary),
                interactionSource = interactionSource
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Text("+", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }
}

// Helper function to format billing date as relative time (like PayableScreen)
private fun formatBillingDateRelative(billingDate: LocalDate, cycle: String = "Monthly"): String {
    // Calculate the next due date based on the billing cycle (same logic as in Payable.kt)
    val nextDueDate = calculateNextDueDateForAddPayable(billingDate, cycle)
    
    val today = LocalDate.now()
    val tomorrow = today.plusDays(1)
    val daysDifference = ChronoUnit.DAYS.between(today, nextDueDate)
    val weeksDifference = ChronoUnit.WEEKS.between(today, nextDueDate)
    val monthsDifference = ChronoUnit.MONTHS.between(today, nextDueDate)
    val yearsDifference = ChronoUnit.YEARS.between(today, nextDueDate)
    
    return when {
        nextDueDate.isEqual(today) -> "Today"
        nextDueDate.isEqual(tomorrow) -> "Tomorrow"
        daysDifference <= 6 -> "in $daysDifference days"
        weeksDifference == 1L -> "in 1 week"
        weeksDifference in 2..3 -> "in $weeksDifference weeks"
        monthsDifference == 1L -> "in 1 month"
        monthsDifference in 2..11 -> "in $monthsDifference months"
        yearsDifference == 1L -> "in 1 year"
        yearsDifference > 1 -> "in $yearsDifference years"
        else -> "in $daysDifference days" // Fallback for edge cases
    }
}

// Calculate next due date based on billing cycle (mirrors Payable.kt logic)
private fun calculateNextDueDateForAddPayable(billingDate: LocalDate, cycle: String): LocalDate {
    val today = LocalDate.now()
    var nextDue = billingDate
    
    // If the billing date is in the future, return it as-is
    if (billingDate.isAfter(today)) {
        return billingDate
    }
    
    // Calculate the next occurrence based on cycle
    while (nextDue <= today) {
        nextDue = when (cycle.lowercase()) {
            "weekly" -> nextDue.plusWeeks(1)
            "monthly" -> nextDue.plusMonths(1)
            "quarterly" -> nextDue.plusMonths(3)
            "yearly" -> nextDue.plusYears(1)
            else -> nextDue.plusMonths(1) // Default to monthly
        }
    }
    
    return nextDue
}

@Preview(showBackground = true)
@Composable
private fun AddPayableScreenPreview() {
    AppTheme {
        AddPayableScreen()
    }
}
