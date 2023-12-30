package com.bluetoothle

import com.facebook.react.bridge.ReadableMap

class ConnectionOptions(options: ReadableMap?) {
  var connectionDuration: Int = 0

  init {
    if (options != null) {
      connectionDuration = getDuration(options)
    }
  }

  private fun getDuration(options: ReadableMap): Int {
    if (options.hasKey(duration)) {
      return options.getInt(duration)
    }

    return 0
  }

  companion object {
    const val duration = "duration"
  }
}
