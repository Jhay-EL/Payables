# Payables App - AI Agent Project Rules

## Overview
These rules ensure consistent outputs for the Payables app that align with Material 3 Expressive Design principles and the established theme system in `app/src/main/java/com/app/payables/theme/`.

## 1. THEME SYSTEM COMPLIANCE

### 1.1 Always Use Theme Tokens
- **MANDATORY**: Use `LocalAppDimensions.current` for all spacing, sizing, and layout measurements
- **MANDATORY**: Use `LocalDashboardTheme.current` for dashboard-style screens
- **MANDATORY**: Use `MaterialTheme.colorScheme` for all colors
- **MANDATORY**: Use `MaterialTheme.typography` (AppTypography) for all text styles
- **MANDATORY**: Use `MaterialTheme.shapes` (AppShapes) for all corner radii

### 1.2 Dimension System Usage
```kotlin
val dims = LocalAppDimensions.current

// Spacing
dims.spacing.xs      // 4.dp
dims.spacing.sm      // 8.dp  
dims.spacing.md      // 16.dp
dims.spacing.lg      // 32.dp
dims.spacing.xl      // 64.dp
dims.spacing.card    // 20.dp
dims.spacing.section // 24.dp

// Title dimensions
dims.titleDimensions.payablesTitleTopPadding           // 16.dp
dims.titleDimensions.payablesTitleToOverviewSpacing    // 64.dp

// Menu dimensions
dims.menuDimensions.width                              // 150.dp
dims.menuDimensions.offsetX                           // -16.dp
```

### 1.3 Color System Usage
```kotlin
// Primary colors
MaterialTheme.colorScheme.primary
MaterialTheme.colorScheme.onPrimary
MaterialTheme.colorScheme.primaryContainer

// Surface colors
MaterialTheme.colorScheme.surface
MaterialTheme.colorScheme.onSurface
MaterialTheme.colorScheme.surfaceVariant
MaterialTheme.colorScheme.onSurfaceVariant

// Card backgrounds (dashboard style)
MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.15f)
```

### 1.4 Typography Usage
```kotlin
// Use AppTypography styles
MaterialTheme.typography.displayMedium    // Large titles
MaterialTheme.typography.headlineSmall    // Section headers
MaterialTheme.typography.titleMedium      // Card titles
MaterialTheme.typography.bodyLarge        // Primary body text
MaterialTheme.typography.bodyMedium       // Secondary body text
MaterialTheme.typography.labelLarge       // Button labels
```

## 2. MATERIAL 3 EXPRESSIVE DESIGN PRINCIPLES

### 2.1 Component Usage
- **Cards**: Use `Card` with `CardDefaults.cardColors()` and proper elevation
- **Buttons**: Use `TextButton`, `FilledButton`, `OutlinedButton` as appropriate
- **Text Fields**: Use `OutlinedTextField` with proper `leadingIcon` and `trailingIcon`
- **Navigation**: Use `TopAppBar` with `TopAppBarDefaults.topAppBarColors()`
- **Dialogs**: Use `AlertDialog` or `Dialog` with `DialogProperties`

### 2.2 Layout Patterns
- **Scaffold Structure**: Always wrap screens in `Scaffold` with proper `topBar` and `paddingValues`
- **Scrollable Content**: Use `Column` with `verticalScroll(rememberScrollState())`
- **Spacing**: Use `Spacer(Modifier.height())` with theme dimensions
- **System Bars**: Handle `WindowInsets.navigationBars` for bottom spacing

### 2.3 Interactive Elements
- **Pressable Cards**: Use `Modifier.pressableCard()` from theme for card interactions
- **State Management**: Use `remember { mutableStateOf() }` for local state
- **Animations**: Use `AnimatedContent` with `AppTransitions.materialSharedAxisHorizontal()`

## 3. SCREEN ARCHITECTURE PATTERNS

### 3.1 Screen Structure Template
```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YourScreen(
    onBack: () -> Unit = {},
    onNavigate: () -> Unit = {}
) {
    val dims = LocalAppDimensions.current
    
    // Fade-to-top-bar setup
    var titleInitialY by remember { mutableStateOf<Int?>(null) }
    var titleWindowY by remember { mutableIntStateOf(Int.MAX_VALUE) }
    val fade = rememberFadeToTopBarProgress(titleInitialY, titleWindowY)
    val topBarAlpha = computeTopBarAlphaFromContentFade(fade)
    val topBarColor = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp).copy(alpha = topBarAlpha)
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                scrollBehavior = scrollBehavior,
                title = { Text("Screen Title", modifier = Modifier.graphicsLayer(alpha = topBarAlpha)) },
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
                .padding(horizontal = dims.spacing.md)
                .verticalScroll(rememberScrollState())
        ) {
            // Y reporter for fade effect
            Box(Modifier.windowYReporter { y -> 
                if (titleInitialY == null) titleInitialY = y; titleWindowY = y 
            })
            
            // Content with fade transform
            Column(Modifier.fadeUpTransform(fade)) {
                Text(
                    text = "Screen Title",
                    style = LocalDashboardTheme.current.titleTextStyle,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 1f - fade),
                    modifier = Modifier.padding(
                        top = dims.titleDimensions.payablesTitleTopPadding,
                        bottom = dims.titleDimensions.payablesTitleToOverviewSpacing
                    )
                )
            }
            
            // Your content here
            
            // Bottom spacing for navigation bar
            val bottomInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            Spacer(Modifier.height(bottomInset + dims.spacing.navBarContentBottomMargin))
        }
    }
}
```

### 3.2 Dashboard-Style Screens
For screens similar to DashboardScreen, use:
```kotlin
val dashboardTheme = LocalDashboardTheme.current

// Section headers
Text(
    text = "Section Name",
    style = dashboardTheme.sectionHeaderTextStyle,
    color = MaterialTheme.colorScheme.onSurface
)

// Card groups with proper corner radius
Card(
    shape = RoundedCornerShape(
        topStart = dashboardTheme.groupTopCornerRadius,
        topEnd = dashboardTheme.groupTopCornerRadius,
        bottomStart = dashboardTheme.groupInnerCornerRadius,
        bottomEnd = dashboardTheme.groupInnerCornerRadius
    ),
    colors = CardDefaults.cardColors(
        containerColor = dashboardTheme.cardContainerColor
    )
)
```

## 4. COMPONENT PATTERNS

### 4.1 Form Fields
```kotlin
OutlinedTextField(
    value = fieldValue,
    onValueChange = { fieldValue = it },
    modifier = Modifier.fillMaxWidth(),
    label = { Text("Field Label") },
    leadingIcon = { Icon(Icons.Filled.IconName, contentDescription = null) },
    singleLine = true
)
```

### 4.2 Dropdown Fields
```kotlin
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
    leadingIcon: (@Composable () -> Unit)? = null
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
                DropdownMenuItem(
                    text = { Text(option) }, 
                    onClick = { onSelect(option); onExpandedChange(false) }
                )
            }
        }
    }
}
```

### 4.3 Segmented Buttons
```kotlin
SingleChoiceSegmentedButtonRow(
    modifier = Modifier.fillMaxWidth().height(56.dp)
) {
    SegmentedButton(
        selected = selectedOption == option1,
        onClick = { selectedOption = option1 },
        shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
        label = { Text("Option 1") }
    )
    SegmentedButton(
        selected = selectedOption == option2,
        onClick = { selectedOption = option2 },
        shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
        label = { Text("Option 2") }
    )
}
```

## 5. NAVIGATION & ROUTING

### 5.1 Navigation Pattern
- Use `BackHandler` for custom back behavior
- Pass navigation callbacks as parameters: `onBack: () -> Unit`, `onNavigate: () -> Unit`
- Use `AppTransitions.materialSharedAxisHorizontal()` for screen transitions
- Follow the routing depth pattern from MainActivity.kt

### 5.2 Route Management
```kotlin
// In MainActivity.kt pattern
fun navigateTo(route: AppRoute) {
    if (backStack.last() != route) backStack.add(route)
}

fun back() {
    if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) 
    else showExitDialog = true
}
```

## 6. STATE MANAGEMENT

### 6.1 Local State
```kotlin
// Form fields
var title by remember { mutableStateOf(TextFieldValue("")) }
var amount by remember { mutableStateOf(TextFieldValue("")) }

// UI state
var expanded by remember { mutableStateOf(false) }
var showDialog by remember { mutableStateOf(false) }

// Colors and selections
var selectedColor by remember { mutableStateOf(Color(0xFF2196F3)) }
var selectedOption by remember { mutableStateOf("Default") }
```

### 6.2 Effect Handling
```kotlin
// Sync state changes
LaunchedEffect(dependency) {
    // Side effects here
}

// Handle back navigation
BackHandler(enabled = condition) { 
    // Custom back behavior
}
```

## 7. ACCESSIBILITY & UX

### 7.1 Content Descriptions
- Always provide `contentDescription` for icons used as buttons
- Use `null` for decorative icons
- Provide meaningful labels for interactive elements

### 7.2 Keyboard Support
```kotlin
keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
```

### 7.3 Loading States
- Use `enabled` parameter on buttons for form validation
- Show loading indicators for async operations

## 8. PERFORMANCE GUIDELINES

### 8.1 Remember Usage
- Use `remember` for expensive calculations
- Use `rememberSaveable` for state that should survive configuration changes
- Use `derivedStateOf` for computed values

### 8.2 Recomposition Optimization
- Keep state as low as possible in the composition tree
- Use stable parameters in Composables
- Avoid creating new objects in Composable bodies

## 9. CODE STYLE

### 9.1 Imports
```kotlin
// Standard order
import androidx.compose.foundation.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import com.app.payables.theme.*
```

### 9.2 Function Structure
- Use `@OptIn(ExperimentalMaterial3Api::class)` when needed
- Mark internal functions as `private`
- Use descriptive parameter names
- Provide default values for optional parameters

### 9.3 Preview Functions
```kotlin
@Preview(showBackground = true)
@Composable
private fun YourScreenPreview() {
    AppTheme {
        YourScreen()
    }
}
```

## 10. VALIDATION RULES

### 10.1 Before Submitting Code
- [ ] Uses theme dimensions instead of hardcoded dp values
- [ ] Uses MaterialTheme.colorScheme for all colors
- [ ] Uses MaterialTheme.typography for all text
- [ ] Follows the established screen architecture pattern
- [ ] Handles system bars and navigation insets properly
- [ ] Includes proper accessibility support
- [ ] Uses consistent naming conventions
- [ ] Includes preview functions

### 10.2 Component Checklist
- [ ] Proper Material 3 component usage
- [ ] Consistent interaction patterns
- [ ] Appropriate elevation and shadows
- [ ] Correct color contrast ratios
- [ ] Responsive layout behavior

## 11. FORBIDDEN PATTERNS

### 11.1 Never Use
- Hardcoded dp values (use theme dimensions)
- Hardcoded colors (use MaterialTheme.colorScheme)
- Custom fonts without theme integration
- Non-Material 3 components
- Direct pixel values
- Deprecated Compose APIs

### 11.2 Always Avoid
- Breaking Material Design guidelines
- Inconsistent spacing patterns
- Custom animations that don't follow Material motion
- Accessibility violations
- Performance anti-patterns

---

## Quick Reference

**Theme Access:**
- `LocalAppDimensions.current` - All dimensions
- `LocalDashboardTheme.current` - Dashboard-specific tokens
- `MaterialTheme.colorScheme` - All colors
- `MaterialTheme.typography` - All text styles

**Common Patterns:**
- Screen structure with fade-to-top-bar
- Form fields with proper validation
- Card groups with theme corner radius
- Navigation with BackHandler
- System bar inset handling

**Key Files:**
- `theme/Theme.kt` - Main theme setup
- `theme/Dimensions.kt` - Spacing and sizing
- `theme/Type.kt` - Typography scale
- `theme/Color.kt` - Color definitions
- `theme/Effects.kt` - Animation helpers
- `MainActivity.kt` - Navigation patterns

