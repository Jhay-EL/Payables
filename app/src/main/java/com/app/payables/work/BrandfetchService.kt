package com.app.payables.work

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.cio.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class Brand(
    val logos: List<Logo>
)

@Serializable
data class Logo(
    val type: String,
    val formats: List<LogoFormat>
)

@Serializable
data class LogoFormat(
    val src: String,
    val format: String
)

object BrandfetchService {
    private const val API_KEY = "1idbp94_6NYbdBWW3yr"
    private const val BASE_URL = "https://api.brandfetch.io/v2/brands/"

    private val client = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                prettyPrint = true
                isLenient = true
            })
        }
    }

    suspend fun fetchBestLogoUrl(domain: String): String? {
        return try {
            val response: Brand = client.get("$BASE_URL$domain") {
                header("Authorization", "Bearer $API_KEY")
            }.body()

            val symbol = response.logos.find { it.type == "symbol" }
            val icon = response.logos.find { it.type == "icon" }

            // Prioritize symbol, fallback to icon
            (symbol?.formats?.firstOrNull()?.src ?: icon?.formats?.firstOrNull()?.src)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
