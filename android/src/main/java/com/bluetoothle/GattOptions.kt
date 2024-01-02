package com.bluetoothle

import com.facebook.react.bridge.ReadableMap

class GattOptions(options: ReadableMap?) {
  var autoDecode = false

  init {
    if (options != null) {
      autoDecode = getAutoDecode(options)
    }
  }

  private fun getAutoDecode(options: ReadableMap): Boolean {
    if (options.hasKey(autoDecodeBytes)) {
      return options.getBoolean(autoDecodeBytes)
    }

    return false
  }

  companion object {
    const val autoDecodeBytes = "autoDecodeBytes"
  }
}
