package com.app.payables.ui

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import com.app.payables.theme.*
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddCategoryScreen(
    onBack: () -> Unit = {},
    onSave: (CategoryData) -> Unit = {},
    onOpenCustomIcons: () -> Unit = {},
    initialCategory: CategoryData? = null,
    titleText: String = if (initialCategory == null) "Add Category" else "Edit Category"
) {
    val dims = LocalAppDimensions.current

    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    var name by remember(initialCategory) { mutableStateOf(TextFieldValue(initialCategory?.name ?: "")) }
    val primaryColor = MaterialTheme.colorScheme.primary
    var selectedColor by remember(primaryColor, initialCategory) { mutableStateOf(initialCategory?.color ?: primaryColor) }
    var selectedIcon by remember(initialCategory) { mutableStateOf(initialCategory?.icon ?: Icons.Filled.Category) }
    var showCustomColor by remember { mutableStateOf(false) }
    var showDefaultIcons by remember { mutableStateOf(false) }

    var colorOptions by remember {
        mutableStateOf(
            listOf(
                Color(0xFF3B82F6), // Blue
                Color(0xFF10B981), // Emerald
                Color(0xFFF59E0B), // Amber
                Color(0xFFEF4444), // Red
                Color(0xFF8B5CF6)  // Purple
            )
        )
    }

    // Use Crossfade to eliminate transition glitches
    Crossfade(
        targetState = showCustomColor,
        animationSpec = tween(durationMillis = 250),
        modifier = Modifier.fillMaxSize()
    ) { show ->
        if (!show) {
            Scaffold(
                modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
                topBar = {
                    TopAppBar(
                        scrollBehavior = scrollBehavior,
                        title = { Text(titleText, modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                        navigationIcon = {
                            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                        },
                        actions = {
                            val canSave = name.text.isNotBlank()
                            TextButton(
                                enabled = canSave,
                                onClick = {
                                    if (canSave) {
                                        onSave(
                                            CategoryData(
                                                name = name.text.trim(),
                                                count = if (initialCategory == null) "0" else initialCategory.count,
                                                color = selectedColor,
                                                icon = selectedIcon,
                                                id = initialCategory?.id ?: UUID.randomUUID().toString()
                                            )
                                        )
                                    }
                                }
                            ) { Text("Save") }
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
                    // Y reporter for title fade
                    Box(Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

                    // Title
                    Column(Modifier.fadeUpTransform(fade)) {
                        Text(
                            text = titleText,
                            style = LocalDashboardTheme.current.titleTextStyle,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                            modifier = Modifier.padding(
                                top = dims.titleDimensions.payablesTitleTopPadding,
                                bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                            )
                        )
                    }

                    // Name input
                    Text("Category name", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        placeholder = { Text("e.g. Entertainment") }
                    )

                    Spacer(Modifier.height(dims.spacing.section))

                    // Icon options (stacked cards)
                    Text("Choose icon", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                    Spacer(Modifier.height(8.dp))
                    ChoiceCard(
                        title = "Default icons",
                        description = "Pick from built-in icons.",
                        isFirst = true,
                        isLast = false,
                        onClick = {
                            showDefaultIcons = true
                        },
                        leading = {
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .background(selectedColor.copy(alpha = 0.18f), RoundedCornerShape(16.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(selectedIcon, contentDescription = null, tint = selectedColor, modifier = Modifier.size(20.dp))
                            }
                        }
                    )
                    ChoiceCard(
                        title = "Custom icons",
                        description = "Provide your own icon.",
                        isFirst = false,
                        isLast = true,
                        onClick = { onOpenCustomIcons() },
                        leading = {
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .background(selectedColor.copy(alpha = 0.18f), RoundedCornerShape(16.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(selectedIcon, contentDescription = null, tint = selectedColor, modifier = Modifier.size(20.dp))
                            }
                        }
                    )

                    Spacer(Modifier.height(dims.spacing.section))

                    // Icon color (stacked card styled similar to WidgetScreen's Background color)
                    Text("Choose icon color", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                    Spacer(Modifier.height(8.dp))
                    OptionCard(
                        title = "Default color",
                        isFirst = true,
                        isLast = false
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            colorOptions.forEach { option ->
                                val isSelected = option.value == selectedColor.value
                                val borderColor = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .background(option, RoundedCornerShape(percent = 50))
                                        .border(2.dp, borderColor, RoundedCornerShape(percent = 50))
                                        .clickable { selectedColor = option }
                                )
                            }
                            Spacer(modifier = Modifier.weight(1f))
                            IconButton(onClick = {
                                colorOptions = List(5) {
                                    val hue = (0..360).random().toFloat()
                                    Color.hsv(hue, 0.75f, 0.95f)
                                }
                            }) {
                                Icon(Icons.Filled.Casino, contentDescription = "Shuffle colors")
                            }
                        }
                    }

                    OptionCard(
                        title = "Custom icon color",
                        isFirst = false,
                        isLast = true
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.Start,
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Button(onClick = { showCustomColor = true }) { Text("Choose color") }
                        }
                    }

                    val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                    Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
                }
            }

            // Default icons bottom sheet
            if (showDefaultIcons) {
                val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
                ModalBottomSheet(
                    onDismissRequest = { showDefaultIcons = false },
                    sheetState = sheetState,
                    dragHandle = { BottomSheetDefaults.DragHandle() },
                ) {
                    val dimsSheet = LocalAppDimensions.current
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = dimsSheet.spacing.md)
                            .padding(bottom = dimsSheet.spacing.lg)
                    ) {
                        Text(
                            text = "Default icons",
                            style = MaterialTheme.typography.headlineSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Choose a category icon",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(dimsSheet.spacing.section))

                        val defaultIcons = listOf(
                            Icons.Filled.Category,
                            Icons.Filled.PlayArrow,
                            Icons.Filled.Cloud,
                            Icons.Filled.Home,
                            Icons.Filled.Phone,
                            Icons.Filled.AccountBalance,
                            Icons.Filled.ShoppingCart,
                            Icons.Filled.Security,
                            Icons.Filled.FitnessCenter,
                            Icons.Filled.Fastfood,
                            Icons.Filled.DirectionsCar,
                            Icons.Filled.Pets,
                            Icons.Filled.School,
                            Icons.Filled.SportsEsports,
                            Icons.Filled.Work,
                            Icons.Filled.Wifi,
                            Icons.Filled.MusicNote,
                            Icons.Filled.Book,
                            Icons.Filled.Flight,
                            Icons.Filled.Restaurant
                        )

                        val rows = defaultIcons.chunked(5)
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            rows.forEach { row ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                                ) {
                                    row.forEach { icon ->
                                        val isSelected = icon == selectedIcon
                                        val borderColor = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .aspectRatio(1f)
                                                .background(selectedColor.copy(alpha = 0.18f), RoundedCornerShape(percent = 50))
                                                .border(2.dp, borderColor, RoundedCornerShape(percent = 50))
                                                .clickable {
                                                    selectedIcon = icon
                                                    showDefaultIcons = false
                                                },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(icon, contentDescription = null, tint = selectedColor, modifier = Modifier.size(24.dp))
                                        }
                                    }
                                    if (row.size < 5) {
                                        repeat(5 - row.size) {
                                            Spacer(modifier = Modifier.weight(1f).aspectRatio(1f))
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(dimsSheet.spacing.section))

                        val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                        Spacer(Modifier.height(bottomInset + dimsSheet.spacing.navBarContentBottomMargin))
                    }
                }
            }
        } else {
            CustomColorScreen(
                onBack = { showCustomColor = false },
                onPick = { c -> selectedColor = c }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChoiceCard(
    title: String,
    description: String? = null,
    onClick: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
    leading: @Composable (() -> Unit)? = null
) {
    val corners = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }
    val interaction: MutableInteractionSource = remember { MutableInteractionSource() }
    val cardModifier = Modifier
        .fillMaxWidth()
        .padding(bottom = 2.dp)
        .pressableCard(interactionSource = interaction)
    Card(
        onClick = onClick,
        modifier = cardModifier,
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
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (leading != null) {
                leading()
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
                if (description != null) {
                    Text(
                        text = description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun OptionCard(
    title: String,
    isFirst: Boolean,
    isLast: Boolean,
    content: @Composable ColumnScope.() -> Unit
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
        Column(modifier = Modifier.padding(LocalAppDimensions.current.spacing.card)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.height(8.dp))
            content()
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun AddCategoryScreenPreview() {
    AppTheme {
        AddCategoryScreen()
    }
}


