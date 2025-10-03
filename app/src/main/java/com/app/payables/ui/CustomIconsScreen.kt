package com.app.payables.ui

import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.widget.ImageView
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import androidx.activity.compose.BackHandler
import com.app.payables.data.ImportedIconsStore
import com.app.payables.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomIconsScreen(
    onBack: () -> Unit = {},
    onImport: (Uri) -> Unit = {},
    onPick: (Uri) -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    val context = LocalContext.current
    var icons by remember { mutableStateOf(ImportedIconsStore.getIcons(context)) }

    // Use Storage Access Framework (persistable permission) to avoid crashes after process death
    val openDoc = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        if (uri != null) {
            try {
                context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: Throwable) { /* ignore if already granted */ }
            ImportedIconsStore.addIcon(context, uri.toString())
            icons = ImportedIconsStore.getIcons(context)
            onImport(uri)
        }
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text("Custom Icons", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = topBarColor, scrolledContainerColor = topBarColor)
            )
        }
    ) { paddingValues ->
        var isSelecting by remember { mutableStateOf(false) }
        val selectedUris = remember { mutableStateListOf<String>() }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = dims.spacing.md)
                .verticalScroll(rememberScrollState())
        ) {
            // Y reporter
            Box(Modifier.windowYReporter { y -> if (titleInitialY == null) titleInitialY = y; titleWindowY = y })

            Column(Modifier.fadeUpTransform(fade)) {
                Text(
                    text = "Custom Icons",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }

            // Actions inside content
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                Button(onClick = { openDoc.launch(arrayOf("image/*")) }) { Text("Import") }
                OutlinedButton(onClick = {
                    isSelecting = !isSelecting
                    if (!isSelecting) selectedUris.clear()
                }) { Text(if (isSelecting) "Done" else "Select") }
            }

            Spacer(Modifier.height(dims.spacing.md))

            Text("Imported icons", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.height(8.dp))

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                val visibleIcons = icons.filter { uri ->
                    isUriReadable(context.contentResolver, uri.toUri())
                }
                val rows = visibleIcons.chunked(4)
                rows.forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                        row.forEach { uriStr ->
                            val uri = uriStr.toUri()
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .aspectRatio(1f)
                                    .clip(RoundedCornerShape(16.dp))
                                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f))
                                    .border(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.5f), RoundedCornerShape(16.dp))
                                    .clickable {
                                        if (isSelecting) {
                                            if (uriStr in selectedUris) selectedUris.remove(uriStr) else selectedUris.add(uriStr)
                                        } else {
                                            onPick(uri)
                                        }
                                    }
                            ) {
                                AndroidView(
                                    factory = { ctx ->
                                        ImageView(ctx).apply {
                                            // Maintain aspect ratio within square without cropping
                                            scaleType = ImageView.ScaleType.FIT_CENTER
                                            setImageURI(uri)
                                        }
                                    },
                                    update = { it.setImageURI(uri) },
                                    modifier = Modifier.matchParentSize()
                                )
                                if (isSelecting) {
                                    val isChecked = uriStr in selectedUris
                                    val overlayColor = if (isChecked) MaterialTheme.colorScheme.primary.copy(alpha = 0.16f) else Color.Transparent
                                    Box(
                                        modifier = Modifier
                                            .matchParentSize()
                                            .background(overlayColor)
                                            .border(2.dp, if (isChecked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f), RoundedCornerShape(16.dp))
                                    )
                                }
                            }
                        }
                        if (row.size < 4) repeat(4 - row.size) { Spacer(modifier = Modifier.weight(1f).aspectRatio(1f)) }
                    }
                }
            }

            if (isSelecting) {
                Spacer(Modifier.height(dims.spacing.md))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(onClick = { selectedUris.clear(); isSelecting = false }, modifier = Modifier.weight(1f)) { Text("Cancel") }
                    Button(onClick = {
                        if (selectedUris.isNotEmpty()) {
                            selectedUris.toList().forEach { ImportedIconsStore.removeIcon(context, it) }
                            icons = ImportedIconsStore.getIcons(context)
                            selectedUris.clear()
                            isSelecting = false
                        }
                    }, enabled = selectedUris.isNotEmpty(), modifier = Modifier.weight(1f)) { Text("Delete selected") }
                }
            }

            Spacer(Modifier.height(dims.spacing.section))

            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }
    
    // Handle system back button
    BackHandler(true) { onBack() }
}

private fun isUriReadable(resolver: ContentResolver, uri: Uri): Boolean {
    return try {
        resolver.openInputStream(uri)?.use { true } ?: false
    } catch (_: Throwable) {
        false
    }
}

@Preview(showBackground = true)
@Composable
private fun CustomIconsScreenPreview() {
    AppTheme {
        CustomIconsScreen()
    }
}
