package com.bluetoothle

import com.bluetoothle.GlobalOptions.Companion.keys.timeoutDuration
import com.bluetoothle.types.Error
import com.bluetoothle.types.PromiseType
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray

class PromiseManager(private val pendingPromises: HashMap<PromiseType, MutableList<Pair<Promise, Timeout?>>>) {
  fun resolvePromise(promiseType: PromiseType, payload: WritableMap) {
    val (promise, timeout) = getNextPromise(promiseType) ?: return

    timeout?.cancel()
    promise.resolve(payload)
  }

  fun addPromise(promiseType: PromiseType, promise: Promise?, timeout: Int?) {
    if (promise == null) return

    if (pendingPromises[promiseType] == null) {
      pendingPromises[promiseType] = mutableListOf()
    }

    val promiseTimeout = getTimeout(promiseType, timeout)
    pendingPromises[promiseType]?.add(Pair(promise, promiseTimeout))
  }

  private fun getTimeout (promiseType: PromiseType, duration: Int?): Timeout? {
    if (duration == null || duration <= 0) {
      return null
    }

    val onTimeout = Runnable {
      val response = Arguments.createMap().apply { putString(Strings.error, Error.TIMEOUT.toString()) }
      resolvePromise(promiseType, response)
    }

    val timeout = Timeout()
    timeout.set(onTimeout, duration)
    return timeout
  }

  private fun getNextPromise(promiseType: PromiseType): Pair<Promise, Timeout?>? {
    val list = pendingPromises[promiseType]

    if (list.isNullOrEmpty()) {
      return null
    }

    val nextPromise = list.first()
    list.removeFirst()

    return nextPromise
  }

  fun resolveAllWithError(error: Error) {
    val response = Arguments.createMap().apply {
      putString(Strings.error, error.toString())
    }

    pendingPromises.values.forEach(){ promiseList ->
      promiseList.forEach{item ->
        val (promise, timeout) = item
        timeout?.cancel()
        promise.resolve(response)
      }
    }
  }
}
