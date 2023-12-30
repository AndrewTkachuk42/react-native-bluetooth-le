package com.bluetoothle

import android.os.Handler
import android.os.Looper
import kotlin.reflect.KFunction

class Timeout {
  private var handler: Handler? = null

  fun cancel() {
    handler?.removeCallbacksAndMessages(null)
  }

  fun set(callback: Runnable, duration: Int = 0) {
    if (handler == null) {
      handler = Handler(Looper.getMainLooper())
    }

    cancel()

    if (duration == 0) {
      return
    }

    val durationInMilliseconds = duration * 1000
    handler?.postDelayed(callback, durationInMilliseconds.toLong())
  }
}
