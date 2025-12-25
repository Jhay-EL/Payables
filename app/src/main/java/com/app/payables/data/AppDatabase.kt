package com.app.payables.data

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import androidx.compose.ui.graphics.Color
class Migration5To6 : Migration(5, 6) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // No schema changes needed, just removing destructive migration fallback
        // This migration preserves all existing data
    }
}

class Migration6To7 : Migration(6, 7) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Create a new table with the desired schema (without cardName)
        db.execSQL("""
            CREATE TABLE new_custom_payment_methods (
                id TEXT NOT NULL,
                name TEXT NOT NULL,
                lastFourDigits TEXT NOT NULL,
                iconName TEXT NOT NULL,
                customIconUri TEXT,
                colorValue INTEGER NOT NULL,
                createdAt INTEGER NOT NULL,
                updatedAt INTEGER NOT NULL,
                PRIMARY KEY(id)
            )
        """.trimIndent())

        // Copy data from the old table to the new table
        db.execSQL("""
            INSERT INTO new_custom_payment_methods (id, name, lastFourDigits, iconName, customIconUri, colorValue, createdAt, updatedAt)
            SELECT id, name, lastFourDigits, iconName, customIconUri, colorValue, createdAt, updatedAt FROM custom_payment_methods
        """.trimIndent())

        // Drop the old table
        db.execSQL("DROP TABLE custom_payment_methods")

        // Rename the new table to the original table name
        db.execSQL("ALTER TABLE new_custom_payment_methods RENAME TO custom_payment_methods")
    }
}

class Migration7To8 : Migration(7, 8) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Add indices for performance optimization
        db.execSQL("CREATE INDEX IF NOT EXISTS index_payables_currency_isRecurring_billingCycle ON payables(currency, isRecurring, billingCycle)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_payables_category ON payables(category)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_payables_isPaused_isFinished ON payables(isPaused, isFinished)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_payables_billingDateMillis ON payables(billingDateMillis)")
    }
}

@Database(
    entities = [Category::class, Payable::class, CustomPaymentMethod::class],
    version = 8,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun categoryDao(): CategoryDao
    abstract fun payableDao(): PayableDao
    abstract fun customPaymentMethodDao(): CustomPaymentMethodDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "payables_database"
                )
                .addCallback(DatabaseCallback())
                .addMigrations(Migration5To6(), Migration6To7(), Migration7To8()) // Add new migration
                .build() // Removed fallbackToDestructiveMigration for production stability
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        populateDatabase(database.categoryDao())
                    }
                }
            }
        }

        private suspend fun populateDatabase(categoryDao: CategoryDao) {
            // Create default categories that will always be present
            val defaultCategories = listOf(
                Category(id = "default_entertainment", name = "Entertainment", colorValue = Color(0xFFff6859).value.toLong(), iconName = "PlayArrow", count = "0", isDefault = true),
                Category(id = "default_retail_ecommerce", name = "Retail and E-commerce", colorValue = Color(0xFFffcf44).value.toLong(), iconName = "ShoppingCart", count = "0", isDefault = true),
                Category(id = "default_food_drink", name = "Food & Drink", colorValue = Color(0xFF72deff).value.toLong(), iconName = "Restaurant", count = "0", isDefault = true),
                Category(id = "default_software_productivity", name = "Software & Productivity", colorValue = Color(0xFFb15dff).value.toLong(), iconName = "Work", count = "0", isDefault = true),
                Category(id = "default_health_wellness", name = "Health & Wellness", colorValue = Color(0xFF1eb980).value.toLong(), iconName = "FitnessCenter", count = "0", isDefault = true)
            )
            categoryDao.insertCategories(defaultCategories)
        }
    }
}
