package com.bluetoothle

import android.bluetooth.BluetoothGattCharacteristic
import com.bluetoothle.Strings.characteristic
import com.bluetoothle.Utils.getTransactionResponse
import com.bluetoothle.types.AdapterState
import com.bluetoothle.types.ConnectionState
import com.bluetoothle.types.Error
import com.bluetoothle.types.EventType
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule

class Events (private val reactContext: ReactApplicationContext) {

  private fun sendEvent(eventName: EventType, params: WritableMap?) {
    reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName.toString(), params)
  }

  fun emitStateChangeEvent(newState: ConnectionState) {
    val params = Arguments.createMap().apply {
      putString(Strings.connectionState, newState.toString())
    }

    sendEvent(EventType.CONNECTION_STATE, params)
  }

  fun emitAdapterStateChangeEvent(newState: AdapterState) {
    val params = Arguments.createMap().apply {
      putString(Strings.adapterState, newState.toString())
    }

    sendEvent(EventType.ADAPTER_STATE, params)
  }

  fun emitDeviceFoundEvent(deviceScanData: WritableMap) {
    sendEvent(EventType.DEVICE_FOUND, deviceScanData)
  }

  fun emitErrorEvent(error: Error) {
    val params = Arguments.createMap().apply {
      putString(Strings.error, error.toString())
    }

    sendEvent(EventType.ERROR, params)
  }

  private fun prepareTransactionParams(characteristic: BluetoothGattCharacteristic):  WritableMap {
    var message = ""
    val charset = Charsets.UTF_8

    val value = characteristic.value

    if (value !== null) {
      message = value.toString(charset)
    }

    val params = Arguments.createMap().apply {
      putString(Strings.value,  message)
      putString(Strings.service, characteristic.service.uuid.toString())
      putString(Strings.characteristic, characteristic.uuid.toString())
    }

    return params
  }

  fun emitNotificationEvent(data: WritableMap) {
    sendEvent(EventType.NOTIFICATION, data)
  }
}
