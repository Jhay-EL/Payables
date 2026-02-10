# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Hide the original source file name
-renamesourcefileattribute SourceFile

# ==================== Kotlin Serialization ====================
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class com.app.payables.**$$serializer { *; }
-keepclassmembers class com.app.payables.** {
    *** Companion;
}
-keepclasseswithmembers class com.app.payables.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ==================== Ktor ====================
-keep class io.ktor.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn io.ktor.**
-dontwarn kotlinx.coroutines.**

# ==================== Room Database ====================
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# ==================== Gson ====================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }
-keep class com.app.payables.data.** { *; }

# ==================== Google APIs ====================
-keep class com.google.api.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.api.**
-dontwarn com.google.android.gms.**

# ==================== SLF4J (referenced by Google APIs) ====================
-dontwarn org.slf4j.**
-dontwarn org.slf4j.impl.StaticLoggerBinder
-dontwarn org.slf4j.impl.StaticMDCBinder

# ==================== Coil ====================
-dontwarn coil.**

# ==================== General ====================
-keep class com.app.payables.data.Payable { *; }
-keep class com.app.payables.data.Category { *; }
-keep class com.app.payables.data.BackupData { *; }
-keep class com.app.payables.data.ExchangeRate { *; }
-keep class com.app.payables.data.CustomPaymentMethod { *; }