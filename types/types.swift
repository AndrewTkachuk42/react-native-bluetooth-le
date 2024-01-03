//
//  types.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 02.01.2024.
//


enum EventType: String {
    case CONNECTION_STATE, ADAPTER_STATE, DEVICE_FOUND, NOTIFICATION, ERROR
}

enum ConnectionState: String {
    case DISCONNECTED,
         SCANNING,
         SCAN_COMPLETED,
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
