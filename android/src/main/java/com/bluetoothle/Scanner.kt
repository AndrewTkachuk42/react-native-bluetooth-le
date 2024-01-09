package com.bluetoothle

import android.annotation.SuppressLint
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import com.bluetoothle.types.ConnectionState
import com.bluetoothle.types.Error
import com.bluetoothle.types.PromiseType
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray

@SuppressLint("MissingPermission")
class Scanner(
  private val adapter: Adapter,
  private val promiseManager: PromiseManager,
  private val events: Events,
) {
  private var isScanning = false
  private val timeout = Timeout()
  private lateinit var scanOptions: ScanOptions
  private var devices: HashMap<String, ScanResult> = HashMap()
  var globalOptions = GlobalOptions(null)

  fun startScan(options: ReadableMap?, promise: Promise) {
    if (isScanning) {
      promise.resolve(
        Arguments.createMap().apply { putString( Strings.error, Error.IS_ALREADY_SCANNING.toString()) })
      return
    }

    if (!adapter.isEnabled()) {
      onAdapterDisabled(promise)
      return
    }

    scanOptions = ScanOptions(options)
    devices.clear()
    isScanning = true
    events.emitStateChangeEvent(ConnectionState.SCANNING)

    promiseManager.addPromise(PromiseType.SCAN, promise, null)
    adapter.startScan(scanOptions.filters, scanCallback)
    setScanTimeout()
  }

  private val scanCallback = object : ScanCallback() {
    override fun onScanResult(callbackType: Int, result: ScanResult) {
      if (devices[result.device.address] != null) return

      events.emitDeviceFoundEvent(prepareDiscoveredData(result))
      devices[result.device.address] = result

      if (scanOptions.shouldFindOne) {
        stopScan(null)
      }
    }

    override fun onScanFailed(errorCode: Int) {
      events.emitErrorEvent(Error.SCAN_ERROR)

      onScanStopped()
    }
  }

  fun stopScan(promise: Promise?) {
    cancelErrorTimeout()

    if (!isScanning) {
      promise?.resolve(Arguments.createMap().apply {
        putString(Strings.error, Error.IS_NOT_SCANNING.toString())
        putBoolean(Strings.isScanning, isScanning)
      })
      return
    }

    promiseManager.addPromise(PromiseType.STOP_SCAN, promise, globalOptions.timeoutDuration)
    adapter.stopScan(scanCallback)

    onScanStopped()
  }

  fun onScanStopped() {
    isScanning = false
    events.emitStateChangeEvent(ConnectionState.SCAN_COMPLETED)

    val scanResponse = WritableNativeArray()

    devices.forEach { entry ->
      scanResponse.pushMap(prepareDiscoveredData(entry.value))
    }

    val scanResult = Arguments.createMap().apply {
      putArray(Strings.devices, scanResponse)
      putNull(Strings.error)
    }

    promiseManager.resolvePromise(PromiseType.SCAN, scanResult)

    val stopScanResponse = Arguments.createMap().apply {
      putBoolean(Strings.isScanning, isScanning)
      putNull(Strings.error)
    }
    promiseManager.resolvePromise(PromiseType.STOP_SCAN, stopScanResponse)
  }

  private fun onAdapterDisabled(promise: Promise) {
    val response = Arguments.createMap().apply { putString( Strings.error, Error.BLE_IS_OFF.toString()) }
    promise.resolve(response)
  }

  private fun setScanTimeout() {
    val callback = Runnable {
      stopScan(null)
    }

    timeout.set(callback, scanOptions.scanDuration)
  }

  private fun cancelErrorTimeout() {
    timeout.cancel()
  }

  private fun prepareDiscoveredData(result: ScanResult): WritableMap {
    return Arguments.createMap().apply {
      putString(Strings.name, result.device.name)
      putString(Strings.address, result.device.address)
      putString(Strings.rssi, result.rssi.toString())
    }
  }
}


