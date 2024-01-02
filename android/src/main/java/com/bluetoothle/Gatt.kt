package com.bluetoothle

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import com.bluetoothle.Utils.arrayToBytes
import com.bluetoothle.Utils.getTransactionResponse
import com.bluetoothle.types.ConnectionState
import com.bluetoothle.types.Error
import com.bluetoothle.types.PromiseType
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import java.util.UUID


@SuppressLint("MissingPermission")
class Gatt(
  private val reactContext: ReactApplicationContext,
  private val adapter: Adapter,
  private val promiseManager: PromiseManager,
  private val events: Events
) {
  private var connectionState: ConnectionState = ConnectionState.DISCONNECTED

  private val timeout = Timeout()
  private var bluetoothGatt: BluetoothGatt? = null
  private lateinit var connectionOptions: ConnectionOptions
  private var options = GattOptions(null)

  fun setOptions(gattOptions: ReadableMap?) {
    options = GattOptions(gattOptions)
  }

  fun isEnabled(promise: Promise) {
    promiseManager.addPromise(PromiseType.IS_ENABLED, promise)

    val response = Arguments.createMap().apply {
      putBoolean(Strings.isEnabled, adapter.isEnabled())
    }

    promiseManager.resolvePromise(PromiseType.IS_ENABLED, response)
  }

  fun getConnectionState(promise: Promise) {
    promiseManager.addPromise(PromiseType.CONNECTION_STATE, promise)

    val response = Arguments.createMap().apply {
      putString(Strings.state, connectionState.toString())
    }

    promiseManager.resolvePromise(PromiseType.CONNECTION_STATE, response)
  }

  fun isConnected(promise: Promise) {
    promiseManager.addPromise(PromiseType.IS_CONNECTED, promise)

    val isConnected = connectionState == ConnectionState.CONNECTED

    val response = Arguments.createMap().apply {
      putBoolean(Strings.isConnected, isConnected)
    }

    promiseManager.resolvePromise(PromiseType.IS_CONNECTED, response)
  }

  private fun getDevice(address: String): BluetoothDevice? {
    val gattDevice = bluetoothGatt?.device
    val isDeviceFound = gattDevice != null && gattDevice.address.toString() == address

    if (!isDeviceFound) {
      destroyGatt()
    }

    val device = if (isDeviceFound) gattDevice else adapter.getDevice(address)

    if (device == null) {
      events.emitErrorEvent(Error.DEVICE_NOT_FOUND)
      resolveConnectionPromise()
      return null
    }

    return device
  }

  fun connect(address: String, options: ReadableMap?, promise: Promise) {
    promiseManager.addPromise(PromiseType.CONNECT, promise)

    if (!adapter.isEnabled()) {
      onAdapterDisabled(PromiseType.CONNECT)
      return
    }

    if (connectionState != ConnectionState.DISCONNECTED) {
      resolveConnectionPromise()
      return
    }

    connectionOptions = ConnectionOptions(options)

    setConnectionTimeout()

    val device = getDevice(address) ?: return

    if (bluetoothGatt != null) {
      bluetoothGatt?.connect()
      return
    }

    bluetoothGatt = device.connectGatt(reactContext, false, gattCallback)
  }

  private fun setConnectionTimeout() {
    val onTimeout = Runnable {
      disconnect(null)
      resolveConnectionPromise()
      destroyGatt()
    }

    timeout.set(onTimeout, connectionOptions.connectionDuration)
  }

  private fun onAdapterDisabled(promiseType: PromiseType) {
    val response =
      Arguments.createMap().apply { putString(Strings.error, Error.BLE_IS_OFF.toString()) }
    promiseManager.resolvePromise(promiseType, response)
  }

  private fun onGattError() {
    events.emitErrorEvent(Error.GATT_ERROR)
  }

  private fun onConnected() {
    timeout.cancel()
    resolveConnectionPromise()
  }

  private fun onDisconnected() {
    resolveDisconnectPromise()
    promiseManager.resolveAllWithError(Error.IS_NOT_CONNECTED)
  }

  private val gattCallback = object : BluetoothGattCallback() {
    override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
      if (status != BluetoothGatt.GATT_SUCCESS) {
        onGattError()
      }

      connectionState = ConnectionStateMap[newState] ?: ConnectionState.DISCONNECTED

      events.emitStateChangeEvent(connectionState)

      if (connectionState == ConnectionState.CONNECTED) onConnected()
      if (connectionState == ConnectionState.DISCONNECTED) onDisconnected()
    }

    override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
      val payload = Arguments.createMap().apply {
        putInt(Strings.mtu, mtu)
        putNull(Strings.error)
      }
      promiseManager.resolvePromise(PromiseType.MTU, payload)
    }

    override fun onCharacteristicRead(
      gatt: BluetoothGatt,
      characteristic: BluetoothGattCharacteristic,
      status: Int
    ) {
      if (status == BluetoothGatt.GATT_SUCCESS) {
        promiseManager.resolvePromise(
          PromiseType.READ,
          getTransactionResponse(characteristic, null, options.autoDecode)
        )
        return
      }

      promiseManager.resolvePromise(
        PromiseType.READ,
        getTransactionResponse(characteristic, Error.READ_ERROR, options.autoDecode)
      )

    }

    override fun onCharacteristicWrite(
      gatt: BluetoothGatt,
      characteristic: BluetoothGattCharacteristic,
      status: Int
    ) {
      if (status != BluetoothGatt.GATT_SUCCESS) {
        events.emitErrorEvent(Error.TRANSACTION_ERROR)

        promiseManager.resolvePromise(
          PromiseType.WRITE, getTransactionResponse(
            characteristic,
            Error.WRITE_ERROR, options.autoDecode
          )
        )
        return
      }

      promiseManager.resolvePromise(
        PromiseType.WRITE, getTransactionResponse(
          characteristic,
          null, options.autoDecode
        )
      )
    }

    override fun onDescriptorWrite(
      gatt: BluetoothGatt?,
      descriptor: BluetoothGattDescriptor?,
      status: Int
    ) {
      if (status == BluetoothGatt.GATT_SUCCESS) {
        promiseManager.resolvePromise(
          PromiseType.NOTIFICATIONS,
          getTransactionResponse(descriptor?.characteristic, null, options.autoDecode)
        )
        return
      }

      promiseManager.resolvePromise(
        PromiseType.NOTIFICATIONS,
        getTransactionResponse(
          descriptor?.characteristic,
          Error.NOTIFICATIONS_ERROR,
          options.autoDecode
        )
      )
    }

    override fun onCharacteristicChanged(
      gatt: BluetoothGatt,
      characteristic: BluetoothGattCharacteristic
    ) {
      events.emitNotificationEvent(getTransactionResponse(characteristic, null, options.autoDecode))
    }

    override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
      sendServicesToJS(gatt.services)
    }
  }

  private fun getCharacteristicAndCheckConnection(
    serviceId: String,
    characteristicId: String,
    promiseType: PromiseType,
  ): BluetoothGattCharacteristic? {

    if (!adapter.isEnabled()) {
      onAdapterDisabled(promiseType)
      return null
    }

    if (connectionState != ConnectionState.CONNECTED) {
      val response = Arguments.createMap().apply {
        putString(Strings.service, serviceId)
        putString(Strings.characteristic, characteristicId)
        putString(Strings.error, Error.IS_NOT_CONNECTED.toString())
      }

      promiseManager.resolvePromise(
        promiseType,
        response
      )

      return null
    }

    return getCharacteristic(serviceId, characteristicId, promiseType)
  }

  fun writeString(serviceId: String, characteristicId: String, payload: String, promise: Promise) {
    promiseManager.addPromise(PromiseType.WRITE, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.WRITE
    ) ?: return

    writeCharacteristic(characteristic, payload.toByteArray(), null)
  }

  fun writeStringWithoutResponse(
    serviceId: String,
    characteristicId: String,
    payload: String,
    promise: Promise
  ) {
    promiseManager.addPromise(PromiseType.WRITE, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.WRITE
    ) ?: return

    writeCharacteristic(
      characteristic,
      payload.toByteArray(),
      BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
    )
  }

  fun write(serviceId: String, characteristicId: String, payload: ReadableArray, promise: Promise) {
    promiseManager.addPromise(PromiseType.WRITE, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.WRITE
    ) ?: return

    writeCharacteristic(characteristic, arrayToBytes(payload), null)
  }

  fun writeWithoutResponse(
    serviceId: String,
    characteristicId: String,
    payload: ReadableArray,
    promise: Promise
  ) {
    promiseManager.addPromise(PromiseType.WRITE, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.WRITE
    ) ?: return

    writeCharacteristic(
      characteristic,
      arrayToBytes(payload),
      BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
    )
  }

  private fun writeCharacteristic(
    characteristic: BluetoothGattCharacteristic,
    value: ByteArray,
    writeType: Int?
  ) {
    characteristic.value = value
    characteristic.writeType = writeType ?: BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
    try {
      bluetoothGatt?.writeCharacteristic(characteristic)
    } catch (error: Throwable) {
      promiseManager.resolvePromise(
        PromiseType.WRITE, getTransactionResponse(
          characteristic,
          Error.WRITE_ERROR, options.autoDecode
        )
      )
    }
  }

  fun read(serviceId: String, characteristicId: String, promise: Promise) {
    promiseManager.addPromise(PromiseType.READ, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.READ
    ) ?: return

    try {
      bluetoothGatt?.readCharacteristic(characteristic)
    } catch (error: Throwable) {
      promiseManager.resolvePromise(
        PromiseType.READ, getTransactionResponse(
          characteristic,
          Error.READ_ERROR,
          options.autoDecode
        )
      )
    }
  }

  fun enableNotifications(serviceId: String, characteristicId: String, promise: Promise) {
    toggleNotifications(serviceId, characteristicId, true, promise)
  }

  fun disableNotifications(serviceId: String, characteristicId: String, promise: Promise) {
    toggleNotifications(serviceId, characteristicId, false, promise)
  }

  private fun toggleNotifications(
    serviceId: String,
    characteristicId: String,
    enable: Boolean,
    promise: Promise
  ) {
    promiseManager.addPromise(PromiseType.NOTIFICATIONS, promise)

    val characteristic = getCharacteristicAndCheckConnection(
      serviceId,
      characteristicId,
      PromiseType.NOTIFICATIONS
    ) ?: return

    val descriptorUUID = characteristic.descriptors?.firstOrNull()?.uuid
    val payload =
      if (enable) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE

    try {
      characteristic.getDescriptor(descriptorUUID).let { cccDescriptor ->
        if (bluetoothGatt?.setCharacteristicNotification(characteristic, true) == false) {

          promiseManager.resolvePromise(
            PromiseType.NOTIFICATIONS,
            getTransactionResponse(characteristic, Error.NOTIFICATIONS_ERROR, options.autoDecode)
          )
          return
        }

        cccDescriptor.value = payload
        bluetoothGatt?.writeDescriptor(cccDescriptor)
      }
    } catch (error: Throwable) {
      promiseManager.resolvePromise(
        PromiseType.NOTIFICATIONS,
        getTransactionResponse(characteristic, Error.NOTIFICATIONS_ERROR, options.autoDecode)
      )
    }
  }

  fun requestMtu(size: Int?, promise: Promise) {
    promiseManager.addPromise(PromiseType.MTU, promise)

    if (connectionState != ConnectionState.CONNECTED) {
      val response = Arguments.createMap().apply {
        putString(Strings.error, Error.IS_NOT_CONNECTED.toString())
        putNull(Strings.mtu)
      }

      promiseManager.resolvePromise(PromiseType.MTU, response)
      return
    }


    bluetoothGatt?.requestMtu(size ?: GATT_MAX_MTU_SIZE)
  }

  fun discoverServices(promise: Promise) {
    promiseManager.addPromise(PromiseType.DISCOVER_SERVICES, promise)

    if (connectionState != ConnectionState.CONNECTED) {
      val response = Arguments.createMap().apply {
        putString(Strings.error, Error.IS_NOT_CONNECTED.toString())
        putNull(Strings.services)
      }

      promiseManager.resolvePromise(PromiseType.DISCOVER_SERVICES, response)
      return
    }


    bluetoothGatt?.discoverServices()
  }

  private fun resolveConnectionPromise() {
    val payload = Arguments.createMap().apply {
      putBoolean(Strings.isConnected, connectionState == ConnectionState.CONNECTED)
    }

    promiseManager.resolvePromise(PromiseType.CONNECT, payload)
  }

  private fun resolveDisconnectPromise() {
    val payload = Arguments.createMap().apply {
      putBoolean(Strings.isConnected, connectionState == ConnectionState.CONNECTED)
    }

    promiseManager.resolvePromise(PromiseType.DISCONNECT, payload)
  }

  private fun getCharacteristic(
    serviceId: String,
    characteristicId: String,
    promiseType: PromiseType,
  ): BluetoothGattCharacteristic? {
    val service = bluetoothGatt?.getService(UUID.fromString(serviceId.lowercase()))
    if (service == null) {
      promiseManager.resolvePromise(
        promiseType, getTransactionResponse(
          null,
          Error.SERVICE_NOT_FOUND,
          options.autoDecode
        )
      )
    }
    val characteristic = service?.getCharacteristic(UUID.fromString(characteristicId.lowercase()))
    if (characteristic == null) {
      promiseManager.resolvePromise(
        promiseType, getTransactionResponse(
          null, Error.CHARACTERISTIC_NOT_FOUND, options.autoDecode
        )
      )
      return null
    }

    return characteristic
  }

  private fun sendServicesToJS(services: List<BluetoothGattService>) {
    val jsResponse = Utils.prepareServicesForJS(services)

    promiseManager.resolvePromise(PromiseType.DISCOVER_SERVICES, jsResponse)
  }

  fun disconnect(promise: Promise?) {
    promiseManager.addPromise(PromiseType.DISCONNECT, promise)

    bluetoothGatt?.disconnect()

    if (connectionState != ConnectionState.CONNECTED) {
      resolveDisconnectPromise()
      return
    }
  }

  fun destroyGatt() {
    bluetoothGatt?.disconnect()
    bluetoothGatt?.close()
    bluetoothGatt = null
    connectionState = ConnectionState.DISCONNECTED
  }

  companion object {
    private const val GATT_MAX_MTU_SIZE = 517

    private val ConnectionStateMap = hashMapOf(
      BluetoothProfile.STATE_DISCONNECTED to ConnectionState.DISCONNECTED,
      BluetoothProfile.STATE_CONNECTING to ConnectionState.CONNECTING,
      BluetoothProfile.STATE_CONNECTED to ConnectionState.CONNECTED,
      BluetoothProfile.STATE_DISCONNECTING to ConnectionState.DISCONNECTING,
    )

  }
}
