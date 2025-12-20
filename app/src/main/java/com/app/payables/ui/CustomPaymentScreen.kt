@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.activity.compose.BackHandler
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.material3.TopAppBarDefaults
import com.app.payables.data.CustomPaymentMethod
import com.app.payables.data.CustomPaymentMethodRepository
import com.app.payables.theme.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomPaymentScreen(
    customPaymentMethodRepository: CustomPaymentMethodRepository? = null,
    onSave: (CustomPaymentMethod) -> Unit = {},
    onCancel: () -> Unit = {},
    onDelete: () -> Unit = {},
    editingPaymentMethod: CustomPaymentMethod? = null // Optional parameter for editing
) {
    val dims = LocalAppDimensions.current
    val coroutineScope = rememberCoroutineScope()
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Fade-to-top-bar setup
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)

    // Determine if we're editing or creating
    val isEditing = editingPaymentMethod != null
    val screenTitle = "Payment Method"

    // Form state with TextFieldValue for better text handling - pre-populate if editing
    var paymentMethodName by remember(editingPaymentMethod) {
        mutableStateOf(TextFieldValue(editingPaymentMethod?.name ?: ""))
    }
    var lastFourDigits by remember(editingPaymentMethod) {
        mutableStateOf(TextFieldValue(editingPaymentMethod?.lastFourDigits ?: ""))
    }
    var selectedIcon by remember(editingPaymentMethod) {
        mutableStateOf(editingPaymentMethod?.iconName ?: "CreditCard")
    }
    var selectedColor by remember(editingPaymentMethod) {
        mutableStateOf(editingPaymentMethod?.let { Color(it.colorValue.toULong()) } ?: Color(0xFF2196F3))
    }

    // Available icons for payment methods
    val paymentIcons = listOf(
        "CreditCard" to Icons.Filled.CreditCard,
        "AccountBalance" to Icons.Filled.AccountBalance,
        "Payment" to Icons.Filled.Payment,
        "Money" to Icons.Filled.Money,
        "Savings" to Icons.Filled.Savings,
        "Home" to Icons.Filled.Home,
        "Business" to Icons.Filled.Business,
        "LocalAtm" to Icons.Filled.LocalAtm
    )

    val canSave = paymentMethodName.text.isNotBlank() && lastFourDigits.text.isNotBlank()

    // Save custom payment method to database
    fun saveCustomPaymentMethod() {
        if (customPaymentMethodRepository != null && canSave) {
            coroutineScope.launch {
                try {
                    if (isEditing) {
                        // Update existing payment method
                        val updatedMethod = editingPaymentMethod.copy(
                            name = paymentMethodName.text.trim(),
                            lastFourDigits = lastFourDigits.text.trim(),
                            iconName = selectedIcon,
                            colorValue = selectedColor.value.toLong(),
                            updatedAt = System.currentTimeMillis()
                        )
                        customPaymentMethodRepository.updateCustomPaymentMethod(updatedMethod)
                        onSave(updatedMethod)
                    } else {
                        // Create new payment method
                        val customPaymentMethod = CustomPaymentMethod.create(
                            name = paymentMethodName.text.trim(),
                            lastFourDigits = lastFourDigits.text.trim(),
                            iconName = selectedIcon,
                            colorValue = selectedColor.value.toLong()
                        )
                        customPaymentMethodRepository.insertCustomPaymentMethod(customPaymentMethod)
                        onSave(customPaymentMethod)
                    }
                } catch (_: Exception) {
                    // Handle error - in a real app you might show a snack bar or dialog
                }
            }
        } else {
            // If no repository, just call the callback (for preview/testing)
            if (isEditing) {
                val updatedMethod = editingPaymentMethod.copy(
                    name = paymentMethodName.text.trim(),
                    lastFourDigits = lastFourDigits.text.trim(),
                    iconName = selectedIcon,
                    colorValue = selectedColor.value.toLong()
                )
                onSave(updatedMethod)
            } else {
                val customPaymentMethod = CustomPaymentMethod.create(
                    name = paymentMethodName.text.trim(),
                    lastFourDigits = lastFourDigits.text.trim(),
                    iconName = selectedIcon,
                    colorValue = selectedColor.value.toLong()
                )
                onSave(customPaymentMethod)
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(screenTitle, modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = {
                    IconButton(onClick = onCancel) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = { saveCustomPaymentMethod() },
                        enabled = canSave
                    ) {
                        Text("Save")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topBarColor,
                    scrolledContainerColor = topBarColor
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = dims.spacing.md)
                .verticalScroll(rememberScrollState())
        ) {
            // Y reporter for fade effect
            Box(Modifier.windowYReporter { y ->
                if (titleInitialY == null) titleInitialY = y; titleWindowY = y
            })

            // Title with fade transform
            Column(Modifier.fadeUpTransform(fade)) {
                Text(
                    text = screenTitle,
                    style = MaterialTheme.typography.displayMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            // Card Details Section Header
            Text(
                text = "Card Details",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = dims.spacing.card)
            )

            // Payment Method Name
            OutlinedTextField(
                value = paymentMethodName,
                onValueChange = { paymentMethodName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Payment Method Name") },
                placeholder = { Text("e.g., My Chase Card") },
                leadingIcon = { Icon(Icons.Filled.CreditCard, contentDescription = null) },
                singleLine = true
            )

            Spacer(Modifier.height(dims.spacing.md))

            // Last 4 Digits
            OutlinedTextField(
                value = lastFourDigits,
                onValueChange = { newValue ->
                    val filtered = newValue.text.filter { it.isDigit() }
                    val cleanText = if (filtered.length <= 4) filtered else filtered.take(4)
                    lastFourDigits = TextFieldValue(cleanText, selection = TextRange(cleanText.length))
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Last 4 Digits") },
                placeholder = { Text("1234") },
                leadingIcon = { Icon(Icons.Filled.Tag, contentDescription = null) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )

            Spacer(Modifier.height(dims.spacing.section))

            // Choose Icon Section Header
            Text(
                text = "Choose Icon",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = dims.spacing.card)
            )

            Text(
                text = "Select an icon to represent your payment method",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.md)
            )

            // Icon grid with proper theme styling
            Column(verticalArrangement = Arrangement.spacedBy(dims.spacing.sm)) {
                paymentIcons.chunked(4).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(dims.spacing.sm), modifier = Modifier.fillMaxWidth()) {
                        row.forEach { (iconName, iconVector) ->
                            val isSelected = selectedIcon == iconName
                            val borderColor = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                            val backgroundColor = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)

                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .aspectRatio(1f)
                                    .clip(RoundedCornerShape(dims.radii.md))
                                    .background(backgroundColor)
                                    .border(2.dp, borderColor, RoundedCornerShape(dims.radii.md))
                                    .clickable { selectedIcon = iconName }
                                    .padding(dims.spacing.sm),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = iconVector,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(dims.iconSizes.md)
                                )
                            }
                        }
                        if (row.size < 4) repeat(4 - row.size) {
                            Spacer(modifier = Modifier.weight(1f).aspectRatio(1f))
                        }
                    }
                }
            }

            Spacer(Modifier.height(dims.spacing.section))

            if (isEditing) {
                Spacer(Modifier.height(dims.spacing.section))
                TextButton(
                    onClick = { showDeleteDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            color = MaterialTheme.colorScheme.errorContainer,
                            shape = RoundedCornerShape(dims.radii.md)
                        )
                ) {
                    Text(
                        "Delete",
                        color = Color.White,
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }

            // Bottom spacing for navigation bar
            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Payment Method") },
            text = { Text("Are you sure you want to delete \"${editingPaymentMethod?.name}\"?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        editingPaymentMethod?.let { method ->
                            coroutineScope.launch {
                                customPaymentMethodRepository?.deleteCustomPaymentMethod(method)
                                onDelete()
                            }
                        }
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

    // Handle system back button
    BackHandler(true) { onCancel() }
}

@Preview(showBackground = true, name = "Add Custom Payment Method")
@Composable
private fun CustomPaymentScreenPreview() {
    AppTheme {
        CustomPaymentScreen()
    }
}

@Preview(showBackground = true, name = "Edit Custom Payment Method")
@Composable
private fun CustomPaymentScreenEditPreview() {
    AppTheme {
        CustomPaymentScreen(
            editingPaymentMethod = CustomPaymentMethod.create(
                name = "My Chase Card",
                lastFourDigits = "1234",
                iconName = "CreditCard",
                colorValue = Color(0xFF3B82F6).value.toLong()
            )
        )
    }
}
