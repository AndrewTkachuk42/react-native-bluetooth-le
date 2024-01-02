package com.bluetoothle

import com.bluetoothle.Strings.address
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap

class BluetoothLeModule(
  reactContext: ReactApplicationContext,
) :
  ReactContextBaseJavaModule(reactContext) {
  private val adapter: Adapter
  private val events: Events
  private val promiseManager = PromiseManager(HashMap())
  private val scanner: Scanner
  private val gatt: Gatt
  private val adapterStateReceiver: AdapterStateReceiver

  init {
    adapter = Adapter(reactContext)
    events = Events(reactContext)
    gatt = Gatt(reactContext, adapter, promiseManager, events)
    scanner = Scanner(adapter, promiseManager, events)
    adapterStateReceiver = AdapterStateReceiver(reactContext, gatt, scanner, promiseManager, events)

    //
    adapterStateReceiver.start()
  }

  @ReactMethod
  private fun setOptions(options: ReadableMap?) {
    gatt.setOptions(options)
  }

  @ReactMethod
  private fun startScan(options: ReadableMap?, promise: Promise) {
    scanner.startScan(options, promise)
  }

  @ReactMethod
  private fun stopScan(promise: Promise) {
    scanner.stopScan(promise)
  }

  @ReactMethod
  private fun connect(address: String, options: ReadableMap?, promise: Promise) {
    gatt.connect(address, options, promise)
  }

  @ReactMethod
  private fun disconnect(promise: Promise) {
    gatt.disconnect(promise)
  }

  @ReactMethod
  private fun requestMtu(size: Int?, promise: Promise) {
    gatt.requestMtu(size, promise)
  }

  @ReactMethod
  private fun discoverServices(services: ReadableArray?, promise: Promise) {
    gatt.discoverServices(promise)
  }

  @ReactMethod
  private fun writeString(
    service: String,
    characteristic: String,
    payload: String,
    promise: Promise
  ) {
    gatt.writeString(service, characteristic, payload, promise)
  }

  @ReactMethod
  private fun writeStringWithoutResponse(
    service: String,
    characteristic: String,
    payload: String,
    promise: Promise
  ) {
    gatt.writeStringWithoutResponse(service, characteristic, payload, promise)
  }

  @ReactMethod
  private fun write(
    service: String,
    characteristic: String,
    payload: ReadableArray,
    promise: Promise
  ) {
    gatt.write(service, characteristic, payload, promise)
  }

  @ReactMethod
  private fun writeWithoutResponse(
    service: String,
    characteristic: String,
    payload: ReadableArray,
    promise: Promise
  ) {
    gatt.writeWithoutResponse(service, characteristic, payload, promise)
  }

  @ReactMethod
  private fun read(service: String, characteristic: String, promise: Promise) {
    gatt.read(service, characteristic, promise)
  }

  @ReactMethod
  private fun enableNotifications(service: String, characteristic: String, promise: Promise) {
    gatt.enableNotifications(service, characteristic, promise)
  }

  @ReactMethod
  private fun disableNotifications(service: String, characteristic: String, promise: Promise) {
    gatt.disableNotifications(service, characteristic, promise)
  }

  @ReactMethod
  private fun isEnabled(promise: Promise) {
    gatt.isEnabled(promise)
  }

  @ReactMethod
  private fun getConnectionState(promise: Promise) {
    gatt.getConnectionState(promise)
  }

  @ReactMethod
  private fun isConnected(promise: Promise) {
    gatt.isConnected(promise)
  }

  @ReactMethod
  private fun destroy() {
    adapterStateReceiver.stop()
    gatt.destroyGatt()
  }

  @ReactMethod
  fun addListener(eventName: String?) {
  }

  @ReactMethod
  fun removeListeners(count: Int?) {
  }

  override fun getName(): String {
    return NAME
  }

  companion object {
    const val NAME = "BluetoothLe"
  }
}
