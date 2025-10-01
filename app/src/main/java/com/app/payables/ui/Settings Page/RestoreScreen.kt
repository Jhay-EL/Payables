package com.app.payables.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.GridOn
import androidx.compose.material.icons.filled.PictureAsPdf
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import com.app.payables.PayablesApplication
import com.app.payables.data.BackupData
import com.app.payables.theme.AppTheme
import com.app.payables.theme.LocalAppDimensions
import com.app.payables.theme.LocalDashboardTheme
import com.app.payables.theme.computeTopBarAlphaFromContentFade
import com.app.payables.theme.fadeUpTransform
import com.app.payables.theme.pressableCard
import com.app.payables.theme.rememberFadeToTopBarProgress
import com.app.payables.theme.windowYReporter
import com.google.gson.Gson
import kotlinx.coroutines.launch
import java.io.BufferedReader
import java.io.InputStreamReader
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import android.widget.Toast
import com.app.payables.data.Category
import com.app.payables.data.CustomPaymentMethod
import com.app.payables.data.Payable
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestoreScreen(
    onBack: () -> Unit = {},
) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val application = context.applicationContext as PayablesApplication
    val payableRepository = application.payableRepository
    val categoryRepository = application.categoryRepository
    val customPaymentMethodRepository = application.customPaymentMethodRepository

    var showConflictDialog by remember { mutableStateOf(false) }
    var conflict by remember { mutableStateOf<Any?>(null) }
    val conflictChannel = remember { Channel<Any>() }
    val conflictFlow = remember(conflictChannel) { conflictChannel.receiveAsFlow() }
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
                title = { Text(text = "Restore", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
            Box(modifier = Modifier.windowYReporter { currentY ->
                if (titleInitialY == null) titleInitialY = currentY
                titleWindowY = currentY
            })

            Column(
                modifier = Modifier.fadeUpTransform(progress = fadeProgress)
            ) {
                Text(
                    text = "Restore",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fadeProgress),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            Text(
                text = "Restore your payables data from an Excel, JSON, or PDF file.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            SectionHeader()

            val filePicker = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.OpenDocument(),
                onResult = { uri ->
                    uri?.let {
                        coroutineScope.launch {
                            try {
                                context.contentResolver.openInputStream(uri)?.use { inputStream ->
                                    BufferedReader(InputStreamReader(inputStream)).use { reader ->
                                        val json = reader.readText()
                                        val backupData = Gson().fromJson(json, BackupData::class.java)

                                        for (payable in backupData.payables) {
                                            val existing = payableRepository.getPayableById(payable.id)
                                            if (existing != null) {
                                                conflictChannel.send(payable)
                                            } else {
                                                payableRepository.insertPayable(payable)
                                            }
                                        }
                                        for (category in backupData.categories) {
                                            val existing = categoryRepository.getCategoryById(category.id)
                                            if (existing != null) {
                                                conflictChannel.send(category)
                                            } else {
                                                categoryRepository.insertCategory(category)
                                            }
                                        }
                                        for (paymentMethod in backupData.customPaymentMethods) {
                                            val existing = customPaymentMethodRepository.getCustomPaymentMethodById(paymentMethod.id)
                                            if (existing != null) {
                                                conflictChannel.send(paymentMethod)
                                            } else {
                                                customPaymentMethodRepository.insertCustomPaymentMethod(paymentMethod)
                                            }
                                        }
                                    }
                                }
                                Toast.makeText(context, "Restore completed", Toast.LENGTH_SHORT).show()
                            } catch (_: Exception) {
                                Toast.makeText(context, "Failed to restore backup", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }
                }
            )

            LaunchedEffect(conflictFlow) {
                conflictFlow.collect { item ->
                    conflict = item
                    showConflictDialog = true
                }
            }

            RestoreOptionCard(
                title = "JSON Restore",
                subtitle = "Select a .json file",
                icon = {
                    Icon(Icons.Filled.Code, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                },
                onClick = { filePicker.launch(arrayOf("application/json")) },
                isFirst = true,
                isLast = false
            )
            RestoreOptionCard(
                title = "Excel Restore",
                subtitle = "Select an .xlsx file",
                icon = {
                    Icon(Icons.Filled.GridOn, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                },
                onClick = { },
                isFirst = false,
                isLast = false,
                enabled = false
            )
            RestoreOptionCard(
                title = "PDF Restore",
                subtitle = "Select a .pdf file",
                icon = {
                    Icon(Icons.Filled.PictureAsPdf, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                },
                onClick = { },
                isFirst = false,
                isLast = true,
                enabled = false
            )

            if (showConflictDialog) {
                AlertDialog(
                    onDismissRequest = {
                        conflict = null
                        showConflictDialog = false
                                     },
                    title = { Text("Conflict Detected") },
                    text = { Text("An item with the same ID already exists. Overwrite?") },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                coroutineScope.launch {
                                    when (val item = conflict) {
                                        is Payable -> payableRepository.updatePayable(item)
                                        is Category -> categoryRepository.updateCategory(item)
                                        is CustomPaymentMethod -> customPaymentMethodRepository.updateCustomPaymentMethod(item)
                                    }
                                    conflict = null
                                    showConflictDialog = false
                                }
                            }
                        ) {
                            Text("Overwrite")
                        }
                    },
                    dismissButton = {
                        TextButton(
                            onClick = {
                                conflict = null
                                showConflictDialog = false
                            }
                        ) {
                            Text("Skip")
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun SectionHeader() {
    Text(
        text = "Restore options",
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RestoreOptionCard(
    title: String,
    subtitle: String,
    icon: @Composable () -> Unit,
    onClick: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
    enabled: Boolean = true
) {
    val interaction = remember { MutableInteractionSource() }
    val corners = when {
        isFirst -> RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 5.dp, bottomEnd = 5.dp)
        isLast -> RoundedCornerShape(topStart = 5.dp, topEnd = 5.dp, bottomStart = 24.dp, bottomEnd = 24.dp)
        else -> RoundedCornerShape(5.dp)
    }

    Card(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
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
                .padding(LocalAppDimensions.current.spacing.card),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) { icon() }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp)
            ) {
                Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
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

@Preview(showBackground = true)
@Composable
private fun RestoreScreenPreview() {
    AppTheme {
        RestoreScreen()
    }
}



