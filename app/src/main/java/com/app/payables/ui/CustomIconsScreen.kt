package com.app.payables.ui

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddPhotoAlternate
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
    var cachedFilePath by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = dims.spacing.md)
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(Modifier.height(dims.spacing.md))

        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Brand domain") },
            placeholder = { Text("e.g., nike.com") },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            singleLine = true
        )

        Spacer(Modifier.height(dims.spacing.sm))

        Button(
            onClick = {
                if (searchQuery.isNotBlank()) {
                    isLoading = true
                    errorMessage = null
                    cachedFilePath = null
                    coroutineScope.launch {
                        val filePath = LogoKitService.fetchAndCacheLogo(context, searchQuery)
                        cachedFilePath = filePath
                        isLoading = false
                        if (filePath == null) {
                            errorMessage = "Failed to fetch logo. Check domain and try again."
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

        Text(
            text = "Preview",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(Modifier.height(dims.spacing.sm))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            )
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                when {
                    errorMessage != null -> {
                        Text(
                            text = errorMessage!!,
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(dims.spacing.md)
                        )
                    }
                    isLoading -> CircularProgressIndicator()
                    cachedFilePath != null -> {
                        AsyncImage(
                            model = File(cachedFilePath!!),
                            contentDescription = "Brand logo preview",
                            modifier = Modifier.padding(dims.spacing.md)
                        )
                    }
                    else -> {
                        Text(
                            text = "Search for a brand to see a preview",
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(dims.spacing.md)
                        )
                    }
                }
            }
        }

        if (cachedFilePath != null) {
            Spacer(Modifier.height(dims.spacing.sm))
            Button(
                onClick = { onPick(File(cachedFilePath!!).toUri()) },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Use This Logo")
            }
        }
        val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
        Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
    }
}


@Composable
private fun CustomIconsTab(onPick: (Uri) -> Unit) {
    val dims = LocalAppDimensions.current
    val context = LocalContext.current
    var importedIcons by remember { mutableStateOf(ImportedIconsStore.getIcons(context)) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            ImportedIconsStore.addIcon(context, it.toString())
            importedIcons = ImportedIconsStore.getIcons(context)
            onPick(it)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = dims.spacing.md)
    ) {
        Spacer(Modifier.height(dims.spacing.md))
        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize = 100.dp),
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 120.dp),
            horizontalArrangement = Arrangement.spacedBy(dims.spacing.md),
            verticalArrangement = Arrangement.spacedBy(dims.spacing.md)
        ) {
            item {
                AddIconCard(onClick = { imagePickerLauncher.launch("image/*") })
            }
            items(importedIcons) { iconUriString ->
                IconPreviewCard(uri = iconUriString.toUri(), onClick = { onPick(iconUriString.toUri()) })
            }
        }
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

@Composable
private fun IconPreviewCard(uri: Uri, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.aspectRatio(1f)
    ) {
        AsyncImage(
            model = uri,
            contentDescription = "Imported Icon",
            modifier = Modifier.fillMaxSize()
        )
    }
}
