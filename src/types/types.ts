export type AnyCallback = (args: any) => any;

export type GlobalOptions = {
  autoDecodeBytes?: boolean;
  timeoutDuration?: number;
};

export enum BluetoothEvent {
  CONNECTION_STATE = 'CONNECTION_STATE',
  ADAPTER_STATE = 'ADAPTER_STATE',
  DEVICE_FOUND = 'DEVICE_FOUND',
  ERROR = 'ERROR',
  NOTIFICATION = 'NOTIFICATION',
}

export enum BluetoothError {
  DEVICE_NOT_FOUND = 'DEVICE_NOT_FOUND',
  BLE_IS_OFF = 'BLE_IS_OFF',
  SCAN_ERROR = 'SCAN_ERROR',
  GATT_ERROR = 'GATT_ERROR',
  IS_NOT_CONNECTED = 'IS_NOT_CONNECTED',
  IS_ALREADY_SCANNING = 'IS_ALREADY_SCANNING',
  IS_NOT_SCANNING = 'IS_NOT_SCANNING',
  SERVICE_NOT_FOUND = 'SERVICE_NOT_FOUND',
  CHARACTERISTIC_NOT_FOUND = 'CHARACTERISTIC_NOT_FOUND',
  TRANSACTION_ERROR = 'TRANSACTION_ERROR',
  READ_ERROR = 'READ_ERROR',
  WRITE_ERROR = 'WRITE_ERROR',
  NOTIFICATIONS_ERROR = 'NOTIFICATIONS_ERROR',
  CONNECTION_FAILED = 'CONNECTION_FAILED',
  DISCOVER_SERVICES_FAILED = 'DISCOVER_SERVICES_FAILED',
  DISCOVER_CHARACTERISTICS_FAILED = 'DISCOVER_CHARACTERISTICS_FAILED',
  TIMEOUT = 'TIMEOUT',
}

export enum ConnectionState {
  DISCONNECTED = 'DISCONNECTED',
  SCANNING = 'SCANNING',
  SCAN_COMPLETED = 'SCAN_COMPLETED',
  CONNECTING = 'CONNECTING',
  CONNECTED = 'CONNECTED',
  DISCONNECTING = 'DISCONNECTING',
}

export type Notification = {
  characteristic: string;
  service: string;
  value: string | null;
  error: string | null;
};

export type StateEvent = {
  connectionState: ConnectionState;
};

export type ErrorEvent = {
  error: BluetoothError;
};

export type DeviceData = {
  address: string;
  name: string;
  rssi: string;
};

export type ScanCallback = (device: DeviceData) => void;

export type StartScan = (
  callback: ScanCallback | null,
  options?: ScanOptions
) => Promise<any>;

export type Connect = (address: string, options?: ConnectOptions) => void;

export type ScanOptions = {
  address?: string;
  name?: string;
  duration?: number;
  findOne?: boolean;
};

export type ConnectOptions = {
  duration?: number;
};

export type SetupOptions = {
  size?: number;
  services?: Record<string, string[]>;
};

export type AdapterStateEvent = {
  adapterState: string;
};
