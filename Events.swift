//
//  Events.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 02.01.2024.
//



class Events: NSObject {
    var emitEvent: (_ eventType: String, _ body: Any)->Void
    
    init(sendEvent: @escaping (_ eventType: String, _ body: Any)->Void) {
        emitEvent = sendEvent
    }
    
    func emitStateChangeEvent(newState: ConnectionState){
        emitEvent(EventType.CONNECTION_STATE.rawValue, [Strings.connectionState: newState.rawValue])
    }
    
    func emitAdapterStateChangeEvent(newState: AdapterState){
        emitEvent(EventType.ADAPTER_STATE.rawValue, [Strings.adapterState: newState.rawValue])
    }
    
    func emitDeviceFoundEvent(deviceData: NSDictionary){
        emitEvent(EventType.DEVICE_FOUND.rawValue, deviceData)
    }
}
