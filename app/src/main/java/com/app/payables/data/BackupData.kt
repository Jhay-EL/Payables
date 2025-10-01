package com.app.payables.data

data class BackupData(
    val payables: List<Payable>,
    val categories: List<Category>,
    val customPaymentMethods: List<CustomPaymentMethod>
)
