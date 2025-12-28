package com.app.payables.data

/**
 * Data class representing the complete backup of app data.
 * @param payables List of all payable records
 * @param categories List of custom categories
 * @param customPaymentMethods List of custom payment methods
 * @param iconFiles Map of icon filename to Base64 encoded file content (for BrandFetch logos and custom icons)
 * @param importedIconsList List of icon URIs from ImportedIconsStore (for tracking which icons to restore)
 */
data class BackupData(
    val payables: List<Payable>,
    val categories: List<Category>,
    val customPaymentMethods: List<CustomPaymentMethod>,
    val iconFiles: Map<String, String> = emptyMap(), // filename -> Base64 encoded content
    val importedIconsList: List<String> = emptyList() // List of icon URIs from ImportedIconsStore
)
