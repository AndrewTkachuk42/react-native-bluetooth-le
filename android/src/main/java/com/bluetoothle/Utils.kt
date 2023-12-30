package com.bluetoothle

import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import com.bluetoothle.types.Error
import com.facebook.react.bridge.Arguments
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
          val properties = characteristic.properties
          characteristicsMap.putString(
            CharacteristicProperties.uuid,
            characteristic.uuid.toString()
          )
          characteristicsMap.putBoolean(
            CharacteristicProperties.read,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_READ)
          )
          characteristicsMap.putBoolean(
            CharacteristicProperties.writeWithoutResponse,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE)
          )
          characteristicsMap.putBoolean(
            CharacteristicProperties.write,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE)
          )
          characteristicsMap.putBoolean(
            CharacteristicProperties.notify,
            hasProperty(properties, BluetoothGattCharacteristic.PROPERTY_WRITE)
          )
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
    if (characteristic?.value != null) response.putString(
      Strings.value,
      decodeBytes(characteristic.value)
    )
    if (error != null) response.putString(Strings.error, error.toString())

    return response
  }
}
