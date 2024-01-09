import { useAdapterState as useAdapterStateHook } from './hooks/useAdapterState';
import { useConnectionState as useConnectionStateHook } from './hooks/useConnectionState';
import { useScaner as useScanerHook } from './hooks/useScanner';
import { Bluetooth } from './services/bluetooth';
import { type ScanOptions, type AnyCallback } from './types/types';

class BluetoothManager {
  private _instance?: Bluetooth;

  getInstance() {
    if (!this._instance) {
      this._instance = new Bluetooth();
    }

    return this._instance;
  }
}

const bluetoothManager = new BluetoothManager();

export default bluetoothManager;

export const useScaner = (options?: ScanOptions) =>
  useScanerHook(bluetoothManager.getInstance(), options);
export const useConnectionState = () =>
  useConnectionStateHook(bluetoothManager.getInstance());
export const useAdapterState = (callback?: AnyCallback) =>
  useAdapterStateHook(bluetoothManager.getInstance(), callback);
