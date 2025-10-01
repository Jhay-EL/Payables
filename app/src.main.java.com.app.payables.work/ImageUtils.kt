package com.app.payables.work

import android.content.Context
import android.net.Uri
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.cio.*
import io.ktor.client.request.*
import java.io.File
import java.util.UUID

object ImageUtils {
    private val client = HttpClient(CIO)

    suspend fun saveImageFromUrl(context: Context, url: String): Uri? {
        return try {
            val response: ByteArray = client.get(url).body()
            val fileName = "logo_${UUID.randomUUID()}.png"
            val file = File(context.filesDir, fileName)
            file.writeBytes(response)
            Uri.fromFile(file)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
