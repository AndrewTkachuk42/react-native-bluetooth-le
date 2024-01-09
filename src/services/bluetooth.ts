import { NativeModules, Platform, NativeEventEmitter } from 'react-native';
import {
  BluetoothEvent,
  type AnyCallback,
  type StateEvent,
  type StartScan,
  type Connect,
  type Notification,
  type AdapterStateEvent,
  type ErrorEvent,
  type GlobalOptions,
  type isEnabled,
  type isConnected,
  type getConnectionState,
  type TransactionResponse,
  type DiscoverServices,
  type RequestMtu,
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
  private _notificationCallbacks: Record<string, AnyCallback | null> = {};

  constructor() {
    this._bluetooth = getNativeModule();
    this._events = new NativeEventEmitter(this._bluetooth);
  }

  init(options?: GlobalOptions) {
    options && this._bluetooth.setOptions(options);
  }

  private unsubscribe = (eventType: BluetoothEvent) => {
    this._events.removeAllListeners(eventType);

    this._activeListeners = this._activeListeners.filter(
      (type) => type !== eventType
    );
  };

  private subscribe = (eventType: BluetoothEvent, callback: AnyCallback) => {
    this.unsubscribe(eventType);
    this._events.addListener(eventType, callback);

    this._activeListeners.push(eventType);
  };

  private removeAllListeners = () =>
    this._activeListeners.forEach((eventType) => this.unsubscribe(eventType));

  startScan: StartScan = async (callback, options) => {
    if (callback) {
      this.subscribe(BluetoothEvent.DEVICE_FOUND, callback);
    }

    const result = await this._bluetooth.startScan(options);
    this.unsubscribe(BluetoothEvent.DEVICE_FOUND);

    return result;
  };

  stopScan = () => this._bluetooth.stopScan();

  connect: Connect = (address, options) =>
    this._bluetooth.connect(address, options);

  disconnect = () => this._bluetooth.disconnect();

  isEnabled: isEnabled = () => this._bluetooth.isEnabled();

  isConnected: isConnected = () => this._bluetooth.isConnected();

  getConnectionState: getConnectionState = () =>
    this._bluetooth.getConnectionState();

  writeString = (
    serviceId: string,
    characteristicId: string,
    payload: string
  ): Promise<TransactionResponse> =>
    this._bluetooth.writeString(serviceId, characteristicId, payload);

  writeStringWithoutResponse = (
    serviceId: string,
    characteristicId: string,
    payload: string
  ): Promise<TransactionResponse> =>
    this._bluetooth.writeStringWithoutResponse(
      serviceId,
      characteristicId,
      payload
    );

  write = (
    serviceId: string,
    characteristicId: string,
    payload: number[]
  ): Promise<TransactionResponse> =>
    this._bluetooth.write(serviceId, characteristicId, payload);

  writeWithoutResponse = (
    serviceId: string,
    characteristicId: string,
    payload: number[]
  ): Promise<TransactionResponse> =>
    this._bluetooth.write(serviceId, characteristicId, payload);

  read = (
    serviceId: string,
    characteristicId: string
  ): Promise<TransactionResponse> =>
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

  subscribeToConnectionState = (callback: (event: StateEvent) => any) => {
    this.subscribe(BluetoothEvent.CONNECTION_STATE, (event: StateEvent) =>
      callback?.(event)
    );

    return () => this.unsubscribe(BluetoothEvent.CONNECTION_STATE);
  };

  subscribeToAdapterState = (callback: (event: AdapterStateEvent) => any) => {
    this.subscribe(BluetoothEvent.ADAPTER_STATE, callback);

    return () => this.unsubscribe(BluetoothEvent.ADAPTER_STATE);
  };

  subscribeToErrors = (callback: (event: ErrorEvent) => any) => {
    this.subscribe(BluetoothEvent.ERROR, callback);
  };

  requestMtu: RequestMtu = (size?: number) =>
    this._bluetooth.requestMtu(size || DEFAULT_MTU_SIZE);

  discoverServices: DiscoverServices = (options) =>
    this._bluetooth.discoverServices(options);

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
