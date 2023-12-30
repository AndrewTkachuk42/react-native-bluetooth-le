package com.bluetoothle

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import com.bluetoothle.types.AdapterState
import com.bluetoothle.types.Error
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext

class AdapterStateReceiver(
  private val reactContext: ReactApplicationContext,
  gatt: Gatt,
  scanner: Scanner,
  private val promiseManager: PromiseManager,
  events: Events
) {
  private val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
  private var isRegistered = false

  private val broadCastReceiver = object : BroadcastReceiver() {
    override fun onReceive(contxt: Context?, intent: Intent?) {
      if (intent?.action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
        when (intent?.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
          BluetoothAdapter.STATE_OFF -> {
            events.emitAdapterStateChangeEvent(AdapterState.OFF)
            gatt.destroyGatt()

            promiseManager.resolveAllWithError(Error.BLE_IS_OFF)
          }

          BluetoothAdapter.STATE_TURNING_OFF -> {
            events.emitAdapterStateChangeEvent(AdapterState.TURNING_OFF)
            gatt.disconnect(null)
            scanner.stopScan(null)
          }

          BluetoothAdapter.STATE_TURNING_ON -> {
            events.emitAdapterStateChangeEvent(AdapterState.TURNING_ON)
          }

          BluetoothAdapter.STATE_ON -> {
            events.emitAdapterStateChangeEvent(AdapterState.ON)
          }
        }
      }
    }
  }

  fun start() {
    if (isRegistered) return

    reactContext.registerReceiver(broadCastReceiver, filter)
  }

  fun stop() {
    if (!isRegistered) return

    reactContext.unregisterReceiver(broadCastReceiver)
  }
}


