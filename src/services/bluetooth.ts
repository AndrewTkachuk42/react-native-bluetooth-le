import { NativeModules, Platform, NativeEventEmitter } from 'react-native';
import {
  BluetoothEvent,
  ConnectionState,
  type AnyCallback,
  type StateEvent,
  type StartScan,
  type Connect,
  type Notification,
  type AdapterStateEvent,
  type ErrorEvent,
  type GlobalOptions,
} from '../types/types';
import { DEFAULT_MTU_SIZE, IS_ANDROID } from '../constants/constants';

const LINKING_ERROR =
  `The package 'react-native-bluetooth-le' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const getNativeModule = () =>
  NativeModules.BluetoothLe
    ? NativeModules.BluetoothLe
    : new Proxy(
        {},
        {
          get() {
            throw new Error(LINKING_ERROR);
          },
        }
      );

export class Bluetooth {
  private _bluetooth: typeof NativeModules.BluetoothLe;
  private _events: NativeEventEmitter;
  private _activeListeners: BluetoothEvent[] = [];
  private _onStateChangeCallback: AnyCallback | null = null;
  private _notificationCallbacks: Record<string, AnyCallback | null> = {};

  constructor() {
    this._bluetooth = getNativeModule();
    this._events = new NativeEventEmitter(this._bluetooth);
  }

  init(options?: GlobalOptions) {
    this.subscribeToConnectionState(null);

    options && this._bluetooth.setOptions(options);
  }

  private unsubscribe = (eventType: BluetoothEvent) => {
    this._events.removeAllListeners(eventType);

    this._activeListeners = this._activeListeners.filter(
      (type) => type !== eventType
    );
    console.log('listeners left: ', this._activeListeners);
  };

  private subscribe = (
    eventType: BluetoothEvent,
    callback: (event: any) => void
  ) => {
    this.unsubscribe(eventType);
    this._events.addListener(eventType, callback);

    this._activeListeners.push(eventType);

    console.log('subscribed to: ', this._activeListeners);
  };

  private removeAllListeners = () =>
    this._activeListeners.forEach((eventType) => this.unsubscribe(eventType));

  startScan: StartScan = (callback, options) => {
    if (callback) {
      this.subscribe(BluetoothEvent.DEVICE_FOUND, callback);
    }

    return this._bluetooth.startScan(options);
  };

  stopScan = () => this._bluetooth.stopScan();

  connect: Connect = (address, options) =>
    this._bluetooth.connect(address, options);

  disconnect = () => this._bluetooth.disconnect();

  isEnabled = () => this._bluetooth.isEnabled();

  isConnected = () => this._bluetooth.isConnected();

  getConnectionState = () => this._bluetooth.getConnectionState();

  writeString = (
    serviceId: string,
    characteristicId: string,
    payload: string
  ) => this._bluetooth.writeString(serviceId, characteristicId, payload);

  writeStringWithoutResponse = (
    serviceId: string,
    characteristicId: string,
    payload: string
  ) =>
    this._bluetooth.writeStringWithoutResponse(
      serviceId,
      characteristicId,
      payload
    );

  write = (serviceId: string, characteristicId: string, payload: number[]) =>
    this._bluetooth.write(serviceId, characteristicId, payload);

  writeWithoutResponse = (
    serviceId: string,
    characteristicId: string,
    payload: number[]
  ) => this._bluetooth.write(serviceId, characteristicId, payload);

  read = (serviceId: string, characteristicId: string) =>
    this._bluetooth.read(serviceId, characteristicId);

  private onNotification = (notification: Notification) => {
    const { characteristic } = notification;
    const callback = this._notificationCallbacks[characteristic];

    callback?.(notification);
  };

  enableNotifications = async (
    serviceId: string,
    characteristicId: string,
    callback: AnyCallback
  ) => {
    const response = this._bluetooth.enableNotifications(
      serviceId,
      characteristicId
    );

    if (!response?.error) {
      this._notificationCallbacks[this.formatUUID(characteristicId)] = callback;
      this.subscribe(BluetoothEvent.NOTIFICATION, this.onNotification);
    }

    console.log('cb: ', this._notificationCallbacks);
    return response;
  };

  disableNotifications = async (
    serviceId: string,
    characteristicId: string
  ) => {
    const response = this._bluetooth.disableNotifications(
      serviceId,
      characteristicId
    );

    if (!response?.error) {
      this._notificationCallbacks = this.removeNotificationCallback(
        this.formatUUID(characteristicId)
      );

      if (!Object.keys(this._notificationCallbacks).length) {
        this.unsubscribe(BluetoothEvent.NOTIFICATION);
      }
    }

    console.log('cb: ', this._notificationCallbacks);
    return response;
  };

  removeNotificationCallback = (characteristicId: string) =>
    Object.entries(this._notificationCallbacks).reduce<
      Record<string, AnyCallback | null>
    >((result, [characteristic, callback]) => {
      if (characteristic !== characteristicId) {
        result[characteristic] = callback;
      }
      return result;
    }, {});

  subscribeToConnectionState = (
    callback: ((event: StateEvent) => any) | null
  ) => {
    this._onStateChangeCallback = callback;

    this.subscribe(
      BluetoothEvent.CONNECTION_STATE,
      this.onConnectionStateChange
    );
  };

  subscribeToAdapterState = (callback: (event: AdapterStateEvent) => any) =>
    this.subscribe(BluetoothEvent.ADAPTER_STATE, callback);

  subscribeToErrors = (callback: (event: ErrorEvent) => any) => {
    this.subscribe(BluetoothEvent.ERROR, callback);
  };

  onScanCompleted = () => {
    this.unsubscribe(BluetoothEvent.DEVICE_FOUND);
  };

  setStateChangeCallback = (callback: AnyCallback) =>
    (this._onStateChangeCallback = callback);

  private onConnectionStateChange = (event: StateEvent) => {
    const { connectionState } = event;

    const actions = {
      [ConnectionState.CONNECTED]: () => {},
      [ConnectionState.CONNECTING]: () => {},
      [ConnectionState.DISCONNECTING]: () => {},
      [ConnectionState.DISCONNECTED]: () => {},
      [ConnectionState.SCANNING]: () => {},
      [ConnectionState.SCAN_COMPLETED]: this.onScanCompleted,
    };

    actions[connectionState]?.();

    this._onStateChangeCallback?.(event);
  };

  requestMtu = (size?: number): Promise<any> =>
    this._bluetooth.requestMtu(size || DEFAULT_MTU_SIZE);

  discoverServices = (options: {
    services?: Record<string, string[]> | null;
    duration?: number;
  }): Promise<any> | void => {
    return this._bluetooth.discoverServices(options);
  };

  unsubscribeFromAdapterState = () =>
    this.unsubscribe(BluetoothEvent.ADAPTER_STATE);

  reset = () => {
    this.removeAllListeners();
  };

  bytesToString = (bytes: number[] | null) =>
    bytes?.map?.((byte) => String.fromCharCode(byte)).join('') || '';

  stringToBytes = (str: string) =>
    Array.from(str, (char) => char.charCodeAt(0));

  destroy = () => {
    this.reset();
    this._bluetooth.destroy();
  };

  formatUUID = (uuid: string) => {
    if (!IS_ANDROID) {
      return uuid.toUpperCase();
    }

    return uuid.toLocaleLowerCase();
  };
}

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
