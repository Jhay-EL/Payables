package com.app.payables.work

object BrandfetchService {
    private const val CLIENT_ID = "1idbp94_6NYbdBWW3yr" // Your provided API key
    private const val BASE_URL = "https://cdn.brandfetch.io"

    fun getLogoUrl(domain: String, type: String = "symbol"): String {
        // Constructs the URL for the logo, per Brandfetch docs.
        // e.g., https://cdn.brandfetch.io/spotify.com/symbol?c=YOUR_CLIENT_ID
        return "$BASE_URL/$domain/$type?c=$CLIENT_ID"
    }
}
