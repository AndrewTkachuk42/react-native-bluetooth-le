package com.bluetoothle

import android.bluetooth.le.ScanFilter
import com.facebook.react.bridge.ReadableMap

class ScanOptions(options: ReadableMap?) {
  var filters: List<ScanFilter>? = null
  var scanDuration: Int = 0
  var shouldFindOne: Boolean = false

  init {
    if (options != null) {
      filters = getScanFilters(options)
      scanDuration = getScanDuration(options)
      shouldFindOne = getFindOne(options)
    }
  }

  private fun getFindOne(options: ReadableMap): Boolean {
    if (options.hasKey(findOne)) {
      return options.getBoolean(findOne)
    }

    return false
  }

  private fun getScanDuration(options: ReadableMap): Int {
    if (options.hasKey(duration)) {
      return options.getInt(duration)
    }

    return 0
  }

  private fun getScanFilters(options: ReadableMap): List<ScanFilter>? {
    val name = options.getString(name)
    val address = options.getString(address)

    if (name == null && address == null) {
      return null
    }

    val filter = ScanFilter.Builder()

    if (name != null) {
      filter.setDeviceName(name)
    }

    if (address != null) {
      filter.setDeviceAddress(address)
    }

    return listOf(filter.build())
  }

  companion object {
    const val name = "name"
    const val address = "address"
    const val duration = "duration"
    const val findOne = "findOne"
  }
}
