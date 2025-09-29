package com.app.payables.data

data class Currency(
    val code: String,
    val name: String,
    val symbol: String
)

object CurrencyList {
    val all: List<Currency> = listOf(
        Currency("USD", "United States Dollar", "$"),
        Currency("EUR", "Euro", "€"),
        Currency("JPY", "Japanese Yen", "¥"),
        Currency("GBP", "British Pound", "£"),
        Currency("AUD", "Australian Dollar", "$"),
        Currency("CAD", "Canadian Dollar", "$"),
        Currency("CHF", "Swiss Franc", "CHF"),
        Currency("CNY", "Chinese Yuan", "¥"),
        Currency("HKD", "Hong Kong Dollar", "$"),
        Currency("NZD", "New Zealand Dollar", "$"),
        Currency("SEK", "Swedish Krona", "kr"),
        Currency("KRW", "South Korean Won", "₩"),
        Currency("SGD", "Singapore Dollar", "$"),
        Currency("NOK", "Norwegian Krone", "kr"),
        Currency("MXN", "Mexican Peso", "$"),
        Currency("INR", "Indian Rupee", "₹"),
        Currency("RUB", "Russian Ruble", "₽"),
        Currency("ZAR", "South African Rand", "R"),
        Currency("TRY", "Turkish Lira", "₺"),
        Currency("BRL", "Brazilian Real", "R$"),
        Currency("TWD", "New Taiwan Dollar", "$"),
        Currency("DKK", "Danish Krone", "kr"),
        Currency("PLN", "Polish Zloty", "zł"),
        Currency("THB", "Thai Baht", "฿"),
        Currency("IDR", "Indonesian Rupiah", "Rp"),
        Currency("HUF", "Hungarian Forint", "Ft"),
        Currency("CZK", "Czech Koruna", "Kč"),
        Currency("ILS", "Israeli New Shekel", "₪"),
        Currency("AED", "United Arab Emirates Dirham", "د.إ"),
        Currency("SAR", "Saudi Riyal", "﷼"),
        Currency("MYR", "Malaysian Ringgit", "RM"),
        Currency("PHP", "Philippine Peso", "₱"),
        Currency("CLP", "Chilean Peso", "$"),
        Currency("PKR", "Pakistani Rupee", "₨"),
        Currency("EGP", "Egyptian Pound", "£"),
        Currency("NGN", "Nigerian Naira", "₦"),
        Currency("ARS", "Argentine Peso", "$"),
        Currency("COP", "Colombian Peso", "$"),
        Currency("PEN", "Peruvian Sol", "S/."),
        Currency("BDT", "Bangladeshi Taka", "৳"),
        Currency("UAH", "Ukrainian Hryvnia", "₴"),
        Currency("KZT", "Kazakhstani Tenge", "₸"),
        Currency("RON", "Romanian Leu", "lei"),
        Currency("BGN", "Bulgarian Lev", "лв"),
        Currency("HRK", "Croatian Kuna", "kn"),
        Currency("MAD", "Moroccan Dirham", "د.م."),
        Currency("KES", "Kenyan Shilling", "KSh"),
        Currency("GHS", "Ghanaian Cedi", "₵"),
        Currency("DOP", "Dominican Peso", "RD$"),
        Currency("RSD", "Serbian Dinar", "дин."),
    )

    fun search(query: String): List<Currency> {
        if (query.isBlank()) return all
        val q = query.trim().lowercase()
        return all.filter { c ->
            c.code.lowercase().contains(q) ||
            c.name.lowercase().contains(q) ||
            c.symbol.lowercase().contains(q)
        }
    }
}


