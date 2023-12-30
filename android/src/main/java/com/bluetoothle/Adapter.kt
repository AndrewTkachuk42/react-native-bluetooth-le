package com.bluetoothle

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanSettings
import android.content.Context
import com.facebook.react.bridge.ReactApplicationContext

@SuppressLint("MissingPermission")
class Adapter (reactContext: ReactApplicationContext) {
  private val bluetoothManager: BluetoothManager by lazy {
      reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
  }

  private val bluetoothAdapter: BluetoothAdapter by lazy {
    bluetoothManager.adapter
  }

  private val bleScanner by lazy {
    bluetoothAdapter.bluetoothLeScanner
  }

  private val scanSettings = ScanSettings.Builder()
    .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
    .build()

  fun startScan (filter: List<ScanFilter>?, callback: ScanCallback) {
    bleScanner.startScan(filter, scanSettings, callback)
  }

  fun stopScan (callback: ScanCallback) {
    bleScanner.stopScan(callback)
  }

  fun isEnabled (): Boolean {
    return bluetoothAdapter.isEnabled
  }

  fun getDevice(address: String): BluetoothDevice? {
    return bluetoothAdapter.getRemoteDevice(address)
  }
}
