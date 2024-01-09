package com.bluetoothle

import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import com.bluetoothle.Strings.characteristic
import com.bluetoothle.Strings.value
import com.bluetoothle.types.Error
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap


object Utils {
  object CharacteristicProperties {
    const val uuid = Strings.uuid
    const val read = Strings.read
    const val write = Strings.write
    const val writeWithoutResponse = Strings.writeWithoutResponse
    const val notify = Strings.notify
  }


  fun prepareServicesForJS(services: List<BluetoothGattService>): WritableMap {
    val jsResponse = Arguments.createMap().apply {
      putNull(Strings.error)
    }

    val servicesMap = Arguments.createMap()

    services.forEach { service ->
      with(service) {
        val characteristicsMap = Arguments.createMap()
        characteristics.forEach { characteristic ->
          val propertiesMap = Arguments.createMap()
          val properties = characteristic.properties

          propertiesMap.putBoolean(
            CharacteristicProperties.read,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_READ)
          )
          propertiesMap.putBoolean(
            CharacteristicProperties.writeWithoutResponse,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE)
          )
          propertiesMap.putBoolean(
            CharacteristicProperties.write,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE)
          )
          propertiesMap.putBoolean(
            CharacteristicProperties.notify,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE)
          )
          characteristicsMap.putMap(characteristic.uuid.toString(), propertiesMap)
        }
        servicesMap.putMap(service.uuid.toString(), characteristicsMap)
      }
    }

    jsResponse.putMap(Strings.services, servicesMap)

    return jsResponse
  }

  private fun hasProperty(properties: Int, property: Int): Boolean {
    return (properties and property) > 0
  }

  private fun decodeBytes(bytes: ByteArray): String {
    val charset = Charsets.UTF_8

    return bytes.toString(charset)
  }

  fun getTransactionResponse(
    characteristic: BluetoothGattCharacteristic?,
    error: Error?,
    shouldDecodeBytes: Boolean
  ): WritableMap {
    val response = Arguments.createMap().apply {
      putNull(Strings.service)
      putNull(Strings.characteristic)
      putNull(Strings.value)
      putNull(Strings.error)
    }

    val service = characteristic?.service
    if (service != null) response.putString(Strings.service, service.uuid.toString())
    if (characteristic != null) response.putString(
      Strings.characteristic,
      characteristic.uuid.toString()
    )

    putDecodedValue(characteristic?.value, response, shouldDecodeBytes)

    if (error != null) response.putString(Strings.error, error.toString())

    return response
  }

  private fun putDecodedValue(value: ByteArray?, response: WritableMap, shouldDecodeBytes: Boolean) {
    if (value == null) {
      response.putNull(
        Strings.value,
      )
      return
    }

    if (shouldDecodeBytes) {
      response.putString(
        Strings.value,
        decodeBytes(value)
      )
      return
    }

    response.putArray(
      Strings.value,
      bytesToWritableArray(value)
    )
  }

  fun arrayToBytes(payload: ReadableArray): ByteArray {
    val bytes = ByteArray(payload.size())
    for (i in 0 until payload.size()) {
      bytes[i] = Integer.valueOf(payload.getInt(i)).toByte()
    }
    return bytes
  }

  private fun bytesToWritableArray(bytes: ByteArray): WritableArray? {
    val value = Arguments.createArray()
    for (i in bytes.indices) value.pushInt(bytes[i].toInt() and 0xFF)
    return value
  }
}
