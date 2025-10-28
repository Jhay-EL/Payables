package com.app.payables.ui.settings

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
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.os.Environment
import android.widget.Toast
import android.graphics.pdf.PdfDocument
import android.graphics.Paint
import android.graphics.Typeface
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BackupScreen(
    onBack: () -> Unit = {},
) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    val application = context.applicationContext as PayablesApplication
    val payableRepository = application.payableRepository
    val categoryRepository = application.categoryRepository
    val customPaymentMethodRepository = application.customPaymentMethodRepository

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
                title = { Text(text = "Backup", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
                    text = "Backup",
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
                text = "Export your payables data. Choose Excel, JSON, or PDF.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = dims.spacing.section)
            )

            SectionHeader()

            val onJsonExport = {
                coroutineScope.launch {
                    val payables = payableRepository.getAllPayablesList()
                    val categories = categoryRepository.getNonDefaultCategoriesList()
                    val customPaymentMethods = customPaymentMethodRepository.getAllCustomPaymentMethodsList()

                    val backupData = BackupData(payables, categories, customPaymentMethods)
                    val json = Gson().toJson(backupData)

                    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                    val filename = "payables_backup_$timestamp.json"
                    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    val file = File(downloadsDir, filename)

                    try {
                        FileOutputStream(file).use {
                            it.write(json.toByteArray())
                        }
                        Toast.makeText(context, "Backup saved to Downloads", Toast.LENGTH_SHORT).show()
                    } catch (_: Exception) {
                        Toast.makeText(context, "Failed to save backup", Toast.LENGTH_SHORT).show()
                    }
                }
            }

            val onExcelExport = {
                coroutineScope.launch {
                    val payables = payableRepository.getAllPayablesList()
                    
                    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                    val filename = "payables_export_$timestamp.csv"
                    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    val file = File(downloadsDir, filename)

                    try {
                        FileOutputStream(file).use { outputStream ->
                            // CSV Header
                            val header = "Title,Amount,Currency,Due Date,Category,Payment Method,Billing Cycle,Status\n"
                            outputStream.write(header.toByteArray())
                            
                            // CSV Data
                            payables.forEach { payable ->
                                val row = formatPayableForCsv(payable)
                                outputStream.write(row.toByteArray())
                            }
                        }
                        Toast.makeText(context, "CSV exported to Downloads", Toast.LENGTH_SHORT).show()
                    } catch (_: Exception) {
                        Toast.makeText(context, "Failed to export CSV", Toast.LENGTH_SHORT).show()
                    }
                }
            }

            val onPdfExport = {
                coroutineScope.launch {
                    val payables = payableRepository.getAllPayablesList()
                    
                    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                    val filename = "payables_report_$timestamp.pdf"
                    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    val file = File(downloadsDir, filename)

                    try {
                        val pdfDocument = PdfDocument()
                        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create() // A4 size
                        var page = pdfDocument.startPage(pageInfo)
                        var canvas = page.canvas
                        
                        val titlePaint = Paint().apply {
                            textSize = 24f
                            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                        }
                        val headerPaint = Paint().apply {
                            textSize = 14f
                            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                        }
                        val bodyPaint = Paint().apply {
                            textSize = 10f
                        }
                        
                        var yPosition = 50f
                        
                        // Title
                        canvas.drawText("Payables Export", 50f, yPosition, titlePaint)
                        yPosition += 20f
                        canvas.drawText(SimpleDateFormat("MMMM dd, yyyy", Locale.getDefault()).format(Date()), 50f, yPosition, bodyPaint)
                        yPosition += 40f
                        
                        // Group payables by status
                        val activePayables = payables.filter { !it.isPaused && !it.isFinished }
                        val pausedPayables = payables.filter { it.isPaused }
                        val finishedPayables = payables.filter { it.isFinished }
                        
                        // Active section
                        if (activePayables.isNotEmpty()) {
                            canvas.drawText("Active (${activePayables.size})", 50f, yPosition, headerPaint)
                            yPosition += 20f
                            activePayables.forEach { payable ->
                                if (yPosition > 800) {
                                    pdfDocument.finishPage(page)
                                    page = pdfDocument.startPage(pageInfo)
                                    canvas = page.canvas
                                    yPosition = 50f
                                }
                                val text = formatPayableForPdf(payable)
                                canvas.drawText(text, 50f, yPosition, bodyPaint)
                                yPosition += 15f
                            }
                            yPosition += 20f
                        }
                        
                        // Paused section
                        if (pausedPayables.isNotEmpty()) {
                            if (yPosition > 800) {
                                pdfDocument.finishPage(page)
                                page = pdfDocument.startPage(pageInfo)
                                canvas = page.canvas
                                yPosition = 50f
                            }
                            canvas.drawText("Paused (${pausedPayables.size})", 50f, yPosition, headerPaint)
                            yPosition += 20f
                            pausedPayables.forEach { payable ->
                                if (yPosition > 800) {
                                    pdfDocument.finishPage(page)
                                    page = pdfDocument.startPage(pageInfo)
                                    canvas = page.canvas
                                    yPosition = 50f
                                }
                                val text = formatPayableForPdf(payable)
                                canvas.drawText(text, 50f, yPosition, bodyPaint)
                                yPosition += 15f
                            }
                            yPosition += 20f
                        }
                        
                        // Finished section
                        if (finishedPayables.isNotEmpty()) {
                            if (yPosition > 800) {
                                pdfDocument.finishPage(page)
                                page = pdfDocument.startPage(pageInfo)
                                canvas = page.canvas
                                yPosition = 50f
                            }
                            canvas.drawText("Finished (${finishedPayables.size})", 50f, yPosition, headerPaint)
                            yPosition += 20f
                            finishedPayables.forEach { payable ->
                                if (yPosition > 800) {
                                    pdfDocument.finishPage(page)
                                    page = pdfDocument.startPage(pageInfo)
                                    canvas = page.canvas
                                    yPosition = 50f
                                }
                                val text = formatPayableForPdf(payable)
                                canvas.drawText(text, 50f, yPosition, bodyPaint)
                                yPosition += 15f
                            }
                        }
                        
                        // Footer
                        if (yPosition > 800) {
                            pdfDocument.finishPage(page)
                            page = pdfDocument.startPage(pageInfo)
                            canvas = page.canvas
                            yPosition = 50f
                        }
                        yPosition += 20f
                        canvas.drawText("Total: ${payables.size} payables", 50f, yPosition, headerPaint)
                        
                        pdfDocument.finishPage(page)
                        
                        FileOutputStream(file).use {
                            pdfDocument.writeTo(it)
                        }
                        pdfDocument.close()
                        
                        Toast.makeText(context, "PDF exported to Downloads", Toast.LENGTH_SHORT).show()
                    } catch (e: Exception) {
                        Toast.makeText(context, "Failed to export PDF: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                }
            }

            ExportOptionCard(
                title = "JSON Export",
                subtitle = "Download a .json file",
                icon = {
                    Icon(Icons.Filled.Code, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                },
                onClick = { onJsonExport() },
                isFirst = true,
                isLast = false
            )
            ExportOptionCard(
                title = "Excel Export",
                subtitle = "Download a .csv file",
                icon = {
                    Icon(Icons.Filled.GridOn, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                },
                onClick = { onExcelExport() },
                isFirst = false,
                isLast = false
            )
            ExportOptionCard(
                title = "PDF Export",
                subtitle = "Download a .pdf file",
                icon = {
                    Icon(Icons.Filled.PictureAsPdf, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                },
                onClick = { onPdfExport() },
                isFirst = false,
                isLast = true
            )
        }
    }
}

@Composable
private fun SectionHeader() {
    Text(
        text = "Export options",
        style = LocalDashboardTheme.current.sectionHeaderTextStyle,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = LocalAppDimensions.current.spacing.cardToHeader)
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ExportOptionCard(
    title: String,
    subtitle: String,
    icon: @Composable () -> Unit,
    onClick: () -> Unit,
    isFirst: Boolean,
    isLast: Boolean,
    enabled: Boolean = true,
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
            // Leading icon badge
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

// Helper function to format payable data for CSV
private fun formatPayableForCsv(payable: com.app.payables.data.Payable): String {
    val status = getPayableStatus(payable)
    val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / (24 * 60 * 60 * 1000))
    val dueDate = com.app.payables.data.Payable.calculateNextDueDate(billingDate, payable.billingCycle)
    val dueDateFormatted = dueDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy"))
    
    // Escape CSV fields by wrapping in quotes and escaping internal quotes
    fun escapeField(field: String): String {
        return "\"${field.replace("\"", "\"\"")}\""
    }
    
    return "${escapeField(payable.title)},${escapeField(payable.amount)},${escapeField(payable.currency)},${escapeField(dueDateFormatted)},${escapeField(payable.category)},${escapeField(payable.paymentMethod)},${escapeField(payable.billingCycle)},${escapeField(status)}\n"
}

// Helper function to format payable data for PDF
private fun formatPayableForPdf(payable: com.app.payables.data.Payable): String {
    val billingDate = LocalDate.ofEpochDay(payable.billingDateMillis / (24 * 60 * 60 * 1000))
    val dueDate = com.app.payables.data.Payable.calculateNextDueDate(billingDate, payable.billingCycle)
    val dueDateFormatted = dueDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy"))
    
    return "${payable.title} - ${payable.amount} ${payable.currency} - Due: $dueDateFormatted - ${payable.category}"
}

// Helper function to get payable status
private fun getPayableStatus(payable: com.app.payables.data.Payable): String {
    return when {
        payable.isFinished -> "Finished"
        payable.isPaused -> "Paused"
        else -> "Active"
    }
}

@Preview(showBackground = true)
@Composable
private fun BackupScreenPreview() {
    AppTheme {
        BackupScreen()
    }
}



