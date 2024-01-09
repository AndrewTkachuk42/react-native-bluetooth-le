//
//  types.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 02.01.2024.
//


enum EventType: String {
    case CONNECTION_STATE, ADAPTER_STATE, DEVICE_FOUND, NOTIFICATION
}

enum ConnectionState: String {
    case DISCONNECTED,
         CONNECTING,
         CONNECTED,
         DISCONNECTING
}

enum AdapterState: String {
    case OFF,
         TURNING_OFF,
         TURNING_ON,
         ON,
         RESETTING,
         UNAUTHORIZED,
         UNSUPPORTED,
         UNKNOWN
}

enum ErrorMessage: String {
    case DEVICE_NOT_FOUND,
         BLE_IS_OFF,
         SCAN_ERROR,
         GATT_ERROR,
         IS_NOT_CONNECTED,
         IS_ALREADY_SCANNING,
         IS_NOT_SCANNING,
         SERVICE_NOT_FOUND,
         CHARACTERISTIC_NOT_FOUND,
         TRANSACTION_ERROR,
         READ_ERROR,
         WRITE_ERROR,
         NOTIFICATIONS_ERROR,
         CONNECTION_FAILED,
         DISCOVER_SERVICES_FAILED,
         DISCOVER_CHARACTERISTICS_FAILED,
         TIMEOUT
}
