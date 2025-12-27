@file:Suppress("AssignedValueIsNeverRead")

package com.app.payables.ui

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import coil.compose.AsyncImage
import com.app.payables.data.ImportedIconsStore
import com.app.payables.theme.*
import com.app.payables.util.LogoKitService
import kotlinx.coroutines.launch
import java.io.File

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun CustomIconsScreen(
    onBack: () -> Unit,
    onPick: (Uri) -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    // Tab state
    val pagerState = rememberPagerState(pageCount = { 2 })
    val coroutineScope = rememberCoroutineScope()
    val tabTitles = listOf("Search by Brand", "Import Icons")

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text("Custom Icons") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
        ) {
            // Tab Row
            TabRow(
                selectedTabIndex = pagerState.currentPage,
                modifier = Modifier.padding(horizontal = dims.spacing.md)
            ) {
                tabTitles.forEachIndexed { index, title ->
                    Tab(
                        selected = pagerState.currentPage == index,
                        onClick = { coroutineScope.launch { pagerState.animateScrollToPage(index) } },
                        text = { Text(title) },
                        icon = {
                            Icon(
                                imageVector = if (index == 0) Icons.Default.Search else Icons.Default.Upload,
                                contentDescription = null
                            )
                        }
                    )
                }
            }

            // Pager Content
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f)
            ) { page ->
                when (page) {
                    0 -> BrandSearchTab(onPick = onPick)
                    1 -> CustomIconsTab(onPick = onPick)
                }
            }
        }
    }
    BackHandler(true) { onBack() }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BrandSearchTab(
    onPick: (Uri) -> Unit
) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<com.app.payables.util.BrandSearchResult>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = dims.spacing.md)
    ) {
        Spacer(Modifier.height(dims.spacing.md))

        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Brand name") },
            placeholder = { Text("e.g., Nike, Apple, Spotify") },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            singleLine = true
        )

        Spacer(Modifier.height(dims.spacing.sm))

        Button(
            onClick = {
                if (searchQuery.isNotBlank()) {
                    isLoading = true
                    errorMessage = null
                    searchResults = emptyList()
                    coroutineScope.launch {
                        val results = LogoKitService.searchBrands(context, searchQuery)
                        searchResults = results
                        isLoading = false
                        if (results.isEmpty()) {
                            errorMessage = "No logos found. Try another brand name."
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = searchQuery.isNotBlank() && !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
                Spacer(Modifier.width(8.dp))
            }
            Text(if (isLoading) "Searching..." else "Search")
        }

        Spacer(Modifier.height(dims.spacing.section))

        // Error message
        if (errorMessage != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Text(
                    text = errorMessage!!,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(dims.spacing.md)
                )
            }
            Spacer(Modifier.height(dims.spacing.sm))
        }

        // Results grid
        if (searchResults.isNotEmpty()) {
            Text(
                text = "Results (${searchResults.size})",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = dims.spacing.sm)
            )

            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 140.dp),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 120.dp),
                horizontalArrangement = Arrangement.spacedBy(dims.spacing.md),
                verticalArrangement = Arrangement.spacedBy(dims.spacing.md)
            ) {
                // Flatten all logo variations into individual items
                searchResults.forEach { brandResult ->
                    brandResult.logos.forEach { logo ->
                        logo.formats.forEach { format ->
                            item {
                                LogoVariationCard(
                                    brandName = brandResult.name,
                                    logoType = logo.type,
                                    logoTheme = logo.theme,
                                    logoFormat = format.format,
                                    logoUrl = format.src,
                                    onClick = {
                                        // Download and cache the logo when selected
                                        coroutineScope.launch {
                                            val filePath = LogoKitService.downloadAndCacheLogo(
                                                context,
                                                format.src,
                                                brandResult.name
                                            )
                                            filePath?.let { path ->
                                                val fileUri = File(path).toUri()
                                                // Register the downloaded logo in ImportedIconsStore for persistence
                                                ImportedIconsStore.addIcon(context, fileUri.toString())
                                                onPick(fileUri)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        } else if (isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator()
                    Spacer(Modifier.height(dims.spacing.md))
                    Text(
                        text = "Searching for brands...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            // Empty state
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Search for a brand to see logos",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun LogoVariationCard(
    brandName: String,
    logoType: String,
    logoTheme: String,
    logoFormat: String,
    logoUrl: String,
    onClick: () -> Unit
) {
    val dims = LocalAppDimensions.current
    
    Card(
        onClick = onClick,
        modifier = Modifier
           .fillMaxWidth()
            .height(220.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(dims.spacing.sm),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Logo preview
            Card(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                )
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = logoUrl,
                        contentDescription = "$brandName logo",
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(dims.spacing.xs)
                    )
                }
            }

            Spacer(Modifier.height(dims.spacing.xs))

            // Brand name
            Text(
                text = brandName,
                style = MaterialTheme.typography.labelMedium,
                textAlign = TextAlign.Center,
                maxLines = 1,
                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth()
            )

            // Type & Theme
            Text(
                text = "${logoType.capitalize()} • ${logoTheme.capitalize()}",
                style = MaterialTheme.typography.labelSmall,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )

            // Format
            Text(
                text = "Format: ${logoFormat.uppercase()}",
                style = MaterialTheme.typography.labelSmall,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

// Extension function for capitalize
private fun String.capitalize(): String {
    return this.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
}


@Composable
private fun CustomIconsTab(onPick: (Uri) -> Unit) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    var importedIcons by remember { mutableStateOf(ImportedIconsStore.getIcons(context)) }
    var isImporting by remember { mutableStateOf(false) }
    
    // Selection state
    var isSelectionMode by remember { mutableStateOf(false) }
    var selectedIcons by remember { mutableStateOf(setOf<String>()) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { sourceUri ->
            isImporting = true
            coroutineScope.launch {
                try {
                    // Copy the image to persistent internal storage
                    val savedPath = copyImageToInternalStorage(context, sourceUri)
                    savedPath?.let { path ->
                        val fileUri = File(path).toUri()
                        ImportedIconsStore.addIcon(context, fileUri.toString())
                        importedIcons = ImportedIconsStore.getIcons(context)
                        onPick(fileUri)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("CustomIconsTab", "Failed to import image: ${e.message}", e)
                } finally {
                    isImporting = false
                }
            }
        }
    }
    
    // Exit selection mode function
    fun exitSelectionMode() {
        isSelectionMode = false
        selectedIcons = emptySet()
    }
    
    // Delete selected icons
    fun deleteSelectedIcons() {
        coroutineScope.launch {
            selectedIcons.forEach { iconUri ->
                ImportedIconsStore.removeIcon(context, iconUri)
                // Also delete the file from storage
                try {
                    val uri = iconUri.toUri()
                    if (uri.scheme == "file") {
                        File(uri.path ?: "").delete()
                    }
                } catch (e: Exception) {
                    android.util.Log.e("CustomIconsTab", "Failed to delete file: ${e.message}")
                }
            }
            importedIcons = ImportedIconsStore.getIcons(context)
            exitSelectionMode()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = dims.spacing.md)
    ) {
        // Selection mode header
        if (isSelectionMode) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = dims.spacing.sm),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(dims.spacing.sm)
                ) {
                    IconButton(onClick = { exitSelectionMode() }) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = "Cancel selection"
                        )
                    }
                    Text(
                        text = "${selectedIcons.size} selected",
                        style = MaterialTheme.typography.titleMedium
                    )
                }
                
                // Delete button
                IconButton(
                    onClick = { showDeleteDialog = true },
                    enabled = selectedIcons.isNotEmpty()
                ) {
                    Icon(
                        imageVector = Icons.Filled.Delete,
                        contentDescription = "Delete selected",
                        tint = if (selectedIcons.isNotEmpty()) 
                            MaterialTheme.colorScheme.error 
                        else 
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                    )
                }
            }
        } else {
            Spacer(Modifier.height(dims.spacing.md))
        }
        
        if (isImporting) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator()
                    Spacer(Modifier.height(dims.spacing.md))
                    Text("Importing icon...", style = MaterialTheme.typography.bodyMedium)
                }
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 100.dp),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 120.dp),
                horizontalArrangement = Arrangement.spacedBy(dims.spacing.md),
                verticalArrangement = Arrangement.spacedBy(dims.spacing.md)
            ) {
                // Add button only shown when not in selection mode
                if (!isSelectionMode) {
                    item {
                        AddIconCard(onClick = { imagePickerLauncher.launch("image/*") })
                    }
                }
                items(importedIcons) { iconUriString ->
                    val isSelected = selectedIcons.contains(iconUriString)
                    IconPreviewCard(
                        uri = iconUriString.toUri(),
                        isSelected = isSelected,
                        isSelectionMode = isSelectionMode,
                        onClick = {
                            if (isSelectionMode) {
                                // Toggle selection
                                selectedIcons = if (isSelected) {
                                    selectedIcons - iconUriString
                                } else {
                                    selectedIcons + iconUriString
                                }
                                // Exit selection mode if nothing selected
                                if (selectedIcons.isEmpty()) {
                                    isSelectionMode = false
                                }
                            } else {
                                onPick(iconUriString.toUri())
                            }
                        },
                        onLongClick = {
                            if (!isSelectionMode) {
                                isSelectionMode = true
                                selectedIcons = setOf(iconUriString)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // Delete confirmation dialog
    if (showDeleteDialog) {
        val dismissDialog = { showDeleteDialog = false }
        AlertDialog(
            onDismissRequest = dismissDialog,
            title = { Text("Delete Icons") },
            text = { 
                Text("Delete ${selectedIcons.size} selected icon${if (selectedIcons.size > 1) "s" else ""}? This cannot be undone.") 
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        dismissDialog()
                        deleteSelectedIcons()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = dismissDialog) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Copy an image from a content URI to internal storage
 * Returns the path to the saved file, or null if failed
 */
private suspend fun copyImageToInternalStorage(context: android.content.Context, sourceUri: Uri): String? = 
    kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
        try {
            val inputStream = context.contentResolver.openInputStream(sourceUri) ?: return@withContext null
            
            // Generate unique filename
            val fileName = "imported_${System.currentTimeMillis()}.png"
            val iconsDir = File(context.filesDir, "brand_logos")
            iconsDir.mkdirs()
            val outputFile = File(iconsDir, fileName)
            
            // Copy the file
            inputStream.use { input ->
                java.io.FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }
            
            android.util.Log.d("CustomIconsTab", "Imported icon saved to: ${outputFile.absolutePath}")
            return@withContext outputFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("CustomIconsTab", "Error copying image: ${e.message}", e)
            return@withContext null
        }
    }

@Composable
private fun AddIconCard(onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.aspectRatio(1f),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Filled.AddPhotoAlternate,
                contentDescription = "Add Icon",
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun IconPreviewCard(
    uri: Uri,
    isSelected: Boolean = false,
    isSelectionMode: Boolean = false,
    onClick: () -> Unit,
    onLongClick: () -> Unit = {}
) {
    Card(
        modifier = Modifier
            .aspectRatio(1f)
            .then(
                if (isSelected) {
                    Modifier.border(
                        width = 3.dp,
                        color = MaterialTheme.colorScheme.primary,
                        shape = MaterialTheme.shapes.medium
                    )
                } else Modifier
            )
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            AsyncImage(
                model = uri,
                contentDescription = "Imported Icon",
                modifier = Modifier.fillMaxSize()
            )
            
            // Selection checkbox overlay
            if (isSelectionMode) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(4.dp)
                        .size(24.dp)
                        .background(
                            color = if (isSelected) 
                                MaterialTheme.colorScheme.primary 
                            else 
                                MaterialTheme.colorScheme.surface.copy(alpha = 0.8f),
                            shape = androidx.compose.foundation.shape.CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (isSelected) {
                        Icon(
                            imageVector = Icons.Filled.Check,
                            contentDescription = "Selected",
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }
    }
}
