package com.oppwa.mobile.connect.demo.common

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader

private const val GROUP = "group"
private const val NAME = "name"
private const val VALUE = "value"


class Utils {

    fun getParametersFromFile(context: Context, fileName: String): Map<String, String> {
        val parameters: MutableMap<String, String> = HashMap()
        var jsonObject: JSONObject
        var jsonArray: JSONArray
        try {
            context.assets.open(fileName).use { inputStream ->
                jsonArray = JSONArray(readInputStream(inputStream))
                for (i in 0 until jsonArray.length()) {
                    jsonObject = jsonArray.getJSONObject(i)
                    val group = jsonObject.getString(GROUP)
                    val name = jsonObject.getString(NAME)
                    val value = jsonObject.getString(VALUE)
                    parameters[constructName(name, group)] = value
                }
            }
        } catch (e: java.lang.Exception) {
            Log.e(Constants.LOG_TAG, "Unable to read parameters data from file.", e)
        }

        return parameters
    }

    private fun constructName(name: String, group: String): String {
        val stringBuilder = java.lang.StringBuilder()
        if (group != "") {
            stringBuilder.append(group)
            stringBuilder.append(".")
        }
        stringBuilder.append(name)
        return stringBuilder.toString()
    }

    private fun readInputStream(inputStream: InputStream): String {
        val stringBuilder = StringBuilder()
        var reader: BufferedReader? = null
        var line: String?
        try {
            reader = BufferedReader(InputStreamReader(inputStream))
            while (reader.readLine().also { line = it } != null) {
                stringBuilder.append(line)
            }
        } catch (e: Exception) {
            Log.e(Constants.LOG_TAG, "Unable to read input stream.", e)
        } finally {
            if (reader != null) {
                try {
                    reader.close()
                } catch (e: IOException) {
                    Log.e(Constants.LOG_TAG, "Unable to close reader.", e)
                }
            }
        }

        return stringBuilder.toString()
    }
}