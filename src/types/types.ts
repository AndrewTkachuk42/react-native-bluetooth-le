export type AnyCallback = (args: any) => any;

export enum BluetoothEvent {
  CONNECTION_STATE = 'CONNECTION_STATE',
  ADAPTER_STATE = 'ADAPTER_STATE',
  DEVICE_FOUND = 'DEVICE_FOUND',
  READ = 'READ',
  WRITE = 'WRITE',
  ERROR = 'ERROR',
  NOTIFICATION = 'NOTIFICATION',
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
  services?: string[];
};

export type AdapterStateEvent = {
  adapterState: string;
};
