package com.oppwa.mobile.connect.demo.common

object Constants {

    const val MERCHANT_ID = "ff80808138516ef4013852936ec200f2"
    const val LOG_TAG = "msdk.demo"

    // the configuration values to change across the app
    object Config {
        // the default amount and currency
        const val AMOUNT = "49.99"
        const val CURRENCY = "EUR"

        // the default amount and currency for AFTERPAY_PACIFIC
        const val AFTERPAY_AMOUNT = "108.50"
        const val AFTERPAY_CURRENCY = "USD"
        const val AFTERPAY_PARAMETERS_FILE = "afterpayPacificParameters.txt"

        // the payment brands for Ready-to-Use UI and Payment Button
        val PAYMENT_BRANDS = linkedSetOf("VISA", "MASTER", "PAYPAL", "GOOGLEPAY")

        // the default payment brand for payment button
        const val PAYMENT_BUTTON_BRAND = "MASTER"

        // the default payment brand for COPYandPAY in mSDK payment button
        const val COPY_AND_PAY_IN_MSDK_PAYMENT_BUTTON_BRAND = "AFTERPAY_PACIFIC"

        // the card info for SDK & Your Own UI
        const val CARD_BRAND = "VISA"
        const val CARD_HOLDER_NAME = "JOHN DOE"
        const val CARD_NUMBER = "4200000000000000"
        const val CARD_EXPIRY_MONTH = "07"
        const val CARD_EXPIRY_YEAR = "28"
        const val CARD_CVV = "123"
    }
}