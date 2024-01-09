export type AnyCallback = (args: any) => any;

export type GlobalOptions = {
  autoDecodeBytes?: boolean;
  timeoutDuration?: number;
};

export enum AdapterState {
  OFF = 'OFF',
  TURNING_OFF = 'TURNING_OFF',
  TURNING_ON = 'TURNING_ON',
  ON = 'ON',
}

export enum BluetoothEvent {
  CONNECTION_STATE = 'CONNECTION_STATE',
  ADAPTER_STATE = 'ADAPTER_STATE',
  DEVICE_FOUND = 'DEVICE_FOUND',
  ERROR = 'ERROR',
  NOTIFICATION = 'NOTIFICATION',
  SCAN_STATE = 'SCAN_STATE',
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

export type ScanEvent = {
  isScanning: boolean;
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

export type ScanResult = {
  error: BluetoothError | null;
  devices: DeviceData[];
};

export type StartScan = (
  callback: ScanCallback | null,
  options?: ScanOptions
) => Promise<ScanResult>;

export type Connect = (address: string, options?: ConnectOptions) => void;

export type isEnabled = () => Promise<{ isEnabled: boolean }>;
export type isConnected = () => Promise<{ isConnected: boolean }>;
export type getConnectionState = () => Promise<{ state: ConnectionState }>;

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
  adapterState: AdapterState;
};

export type TransactionResponse = {
  error: BluetoothError | null;
  service: string | null;
  characteristic: string | null;
  value: number[] | string | null;
  isNotifying?: boolean;
};

export type Characteristic = {
  read: boolean;
  write: boolean;
  writeWithoutResponse: boolean;
  notify: boolean;
};

type UUID = string;

type Services = Record<UUID, Record<UUID, Characteristic>>;

export type DiscoverServices = (options: {
  services?: Record<UUID, UUID[]> | null;
  duration?: number;
}) => Promise<{
  error: BluetoothError | null;
  services: Services;
}>;

export type RequestMtu = (size?: number) => Promise<{
  error: BluetoothError | null;
  mtu: number;
}>;
