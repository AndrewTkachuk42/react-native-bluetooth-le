package com.bluetoothle

import com.bluetoothle.types.Error
import com.bluetoothle.types.PromiseType
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray

class PromiseManager(private val pendingPromises: HashMap<PromiseType, MutableList<Promise>>) {
  fun resolvePromise(promiseType: PromiseType, payload: WritableMap) {
    val nextPromise = getNextPromise(promiseType)

    nextPromise?.resolve(payload)
  }

  fun addPromise(promiseType: PromiseType, promise: Promise?) {
    if (promise == null) return

    if (pendingPromises[promiseType] == null) {
      pendingPromises[promiseType] = mutableListOf()
    }

    pendingPromises[promiseType]?.add(promise)
  }

  private fun getNextPromise(promiseType: PromiseType): Promise? {
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
      promiseList.forEach{promise ->
        promise.resolve(response)
      }
    }
  }
}
