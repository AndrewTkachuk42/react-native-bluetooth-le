//
//  Peripheral.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import CoreBluetooth

class Peripheral: NSObject {
    var device: CBPeripheral?
    var globalOptions: GlobalOptions!
    private let promiseManager: PromiseManager!
    private let events: Events!
    private var serviceMap = [NSString : [NSString: CBCharacteristic]]()
    private var servicesToDiscover = NSDictionary()
    private var discoverServicesOptions = DiscoverServicesOptions(options: nil)
    
    let PeripheralStateMap: [CBPeripheralState : ConnectionState] = [.disconnected : .DISCONNECTED, .connecting : .CONNECTING, .connected : .CONNECTED, .disconnecting : .DISCONNECTING]
    
    init(promiseManager: PromiseManager, events: Events) {
        self.events = events
        self.promiseManager = promiseManager
        self.globalOptions = GlobalOptions(options: nil)
    }
    
    func setPeripheral (peripheral: CBPeripheral) {
        device = peripheral
        device?.delegate = self
    }
    
    func discoverServices(options: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock){
        guard device?.state == .connected else {
            resolve([Strings.error: ErrorMessage.IS_NOT_CONNECTED, Strings.services: NSNull()] as NSDictionary)
            return
        }
        
        promiseManager.addPromise(promiseType: .DISCOVER_SERVICES, promise: resolve, timeout: 5)
        serviceMap.removeAll()
        discoverServicesOptions = DiscoverServicesOptions(options: options)
        
        var serviceUUIDs: [CBUUID]?
        if let serviceList = discoverServicesOptions.services?.keys { serviceUUIDs = Array(serviceList)}
        
        device?.discoverServices(serviceUUIDs)
    }
    
    func discoverCharacteristics() {
        guard let peripheralServices = device?.services else {
            promiseManager.resolvePromise(promiseType: .DISCOVER_SERVICES, payload: [Strings.error: ErrorMessage.DISCOVER_SERVICES_FAILED, Strings.services: NSNull()] as NSDictionary)
            return
        }
        
        for service in peripheralServices {
            let characteristicsUUIDs = discoverServicesOptions.services?[service.uuid]
            device?.discoverCharacteristics(characteristicsUUIDs, for: service)
        }
    }
    
    func writeString(serviceId: NSString, characteristicId: NSString, value: NSString, resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        let byteData = (value as String).data(using: .utf8)!
        promiseManager.addPromise(promiseType: .WRITE, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.writeValue(byteData, for: characteristic, type: .withResponse)
    }
    
    func writeStringWithoutResponse(serviceId: NSString, characteristicId: NSString, value: NSString, resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        let byteData = (value as String).data(using: .utf8)!
        promiseManager.addPromise(promiseType: .WRITE, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.writeValue(byteData, for: characteristic, type: .withResponse)
    }
    
    func write(serviceId: NSString, characteristicId: NSString, value: [UInt8], resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        promiseManager.addPromise(promiseType: .WRITE, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.writeValue(Data(value), for: characteristic, type: .withResponse)
    }
    
    func writeWithoutResponse(serviceId: NSString, characteristicId: NSString, value: [UInt8], resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        promiseManager.addPromise(promiseType: .WRITE, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.writeValue(Data(value), for: characteristic, type: .withoutResponse)
    }
    
    func read(serviceId: NSString, characteristicId: NSString, resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        promiseManager.addPromise(promiseType: .READ, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.readValue(for: characteristic)
    }
    
    func enableNotifications(serviceId: NSString, characteristicId: NSString, resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        promiseManager.addPromise(promiseType: .NOTIFICATIONS, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.setNotifyValue(true, for: characteristic)
    }
    
    func disableNotifications(serviceId: NSString, characteristicId: NSString, resolve: @escaping RCTPromiseResolveBlock) {
        guard let characteristic = getCharacteristic(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve) else {
            return
        }
        
        promiseManager.addPromise(promiseType: .NOTIFICATIONS, promise: resolve, timeout: globalOptions.timeoutDuration)
        device?.setNotifyValue(false, for: characteristic)
    }
    
    func getCharacteristic (serviceId: NSString, characteristicId: NSString, resolve: @escaping RCTPromiseResolveBlock) -> CBCharacteristic? {
        guard device?.state == .connected else {
            resolve([Strings.error: ErrorMessage.IS_NOT_CONNECTED.rawValue] as NSDictionary)
            return nil
        }
        
        guard let service = serviceMap[serviceId] else {
            resolve([Strings.error: ErrorMessage.SERVICE_NOT_FOUND.rawValue] as NSDictionary)
            return nil
        }
        
        guard let characteristic = service[characteristicId] else {
            resolve([Strings.error: ErrorMessage.CHARACTERISTIC_NOT_FOUND.rawValue] as NSDictionary)
            return nil
        }
        
        return characteristic
    }
    
    func requestMtu(resolve: @escaping RCTPromiseResolveBlock){
        let errorMessage: Any = device?.state == .connected ? NSNull() : ErrorMessage.IS_NOT_CONNECTED.rawValue
        resolve([Strings.mtu: device?.maximumWriteValueLength(for: .withResponse) ?? 0, Strings.error: errorMessage] as NSDictionary)
    }
    
    func prepareServicesResponse() -> NSDictionary {
        let servicesMap: NSMutableDictionary = [:]
        
        guard let services = device?.services else {
            return [Strings.services: servicesMap]
        }
        
        for service in services {
            if (service.characteristics != nil) {
                let characteristicsMap = NSMutableDictionary()
                
                for characteristic in service.characteristics! {
                    let properties = characteristic.properties
                    characteristicsMap[characteristic.uuid.uuidString] = [Strings.read: properties.contains(CBCharacteristicProperties.read),  Strings.write: properties.contains(CBCharacteristicProperties.write), Strings.writeWithoutResponse: properties.contains(CBCharacteristicProperties.writeWithoutResponse), Strings.notify: properties.contains(CBCharacteristicProperties.notify)] as NSDictionary
                }
                servicesMap[service.uuid.uuidString] = characteristicsMap
            }
        }
        
        return [Strings.services: servicesMap]
    }
    
    func decodeBytes (data: Data?) -> Any? {
        guard let value = data else {return nil}
        return globalOptions.autoDecode ? String(bytes: value, encoding: .utf8) as Any : Array(value)
    }
    
    func getTransactionResponse (characteristic: CBCharacteristic, error: ErrorMessage?) -> NSDictionary {
        return [Strings.error: error?.rawValue ?? NSNull(), Strings.service: characteristic.service?.uuid.uuidString ?? NSNull(), Strings.characteristic: characteristic.uuid.uuidString, Strings.value : decodeBytes(data: characteristic.value) ?? NSNull(), Strings.isNotifying: characteristic.isNotifying] as NSDictionary
    }
    
    func getConnectionState (resolve: @escaping RCTPromiseResolveBlock) {
        let state = PeripheralStateMap[device?.state ?? .disconnected]
        resolve([Strings.connectionState: state!.rawValue] as NSDictionary)
    }
}

extension Peripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (peripheral.services == nil) {
            promiseManager.resolvePromise(promiseType: .DISCOVER_SERVICES, payload: [Strings.error: ErrorMessage.DISCOVER_SERVICES_FAILED, Strings.services: NSNull()] as NSDictionary)
            return
        }
        
        discoverCharacteristics()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            promiseManager.resolvePromise(promiseType: .DISCOVER_SERVICES, payload: [Strings.error: ErrorMessage.DISCOVER_CHARACTERISTICS_FAILED, Strings.services: NSNull()] as NSDictionary)
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        var characteristicsMap = [NSString: CBCharacteristic]()
        
        for characteristic in characteristics {
            characteristicsMap[characteristic.uuid.uuidString as NSString] = characteristic
        }
        
        serviceMap[service.uuid.uuidString as NSString] = characteristicsMap
        
        if (serviceMap.keys.count >= device?.services?.count ?? 0) {
            promiseManager.resolvePromise(promiseType: .DISCOVER_SERVICES, payload: prepareServicesResponse())
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let errorMessage = error != nil ? ErrorMessage.WRITE_ERROR: nil
        promiseManager.resolvePromise(promiseType: .WRITE, payload: getTransactionResponse(characteristic: characteristic, error: errorMessage))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let errorMessage = error != nil ? ErrorMessage.READ_ERROR: nil
        let data = getTransactionResponse(characteristic: characteristic, error: errorMessage)
        promiseManager.resolvePromise(promiseType: .READ, payload: data)
        
        if (characteristic.isNotifying) {
            events.emitNotificationEvent(data: data)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let errorMessage = error != nil ? ErrorMessage.NOTIFICATIONS_ERROR: nil
        promiseManager.resolvePromise(promiseType: .NOTIFICATIONS, payload: getTransactionResponse(characteristic: characteristic, error: errorMessage))
    }
}
