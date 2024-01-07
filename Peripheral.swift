//
//  Peripheral.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import CoreBluetooth

class Peripheral: NSObject {
    private let promiseManager: PromiseManager!
    private let events: Events!
    var device: CBPeripheral?
    private var serviceMap = [CBUUID : [CBUUID: CBCharacteristic]]()
    private var servicesToDiscover = NSDictionary()
    private var discoverServicesOptions = DiscoverServicesOptions(options: nil)
    private var discoverServicesTimer = Timeout()
    
    init(promiseManager: PromiseManager, events: Events) {
        self.events = events
        self.promiseManager = promiseManager
    }
    
    func setPeripheral (peripheral: CBPeripheral) {
        device = peripheral
        device?.delegate = self
    }
    
    func discoverServices(options: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock){
        if (device?.state != .connected) {
            resolve([Strings.error: ErrorMessage.IS_NOT_CONNECTED, Strings.services: NSNull()] as NSDictionary)
            return
        }
        
        promiseManager.addPromise(promiseType: .DISCOVER_SERVICES, promise: resolve)
        serviceMap.removeAll()
        discoverServicesOptions = DiscoverServicesOptions(options: options)
        
        var serviceUUIDs: [CBUUID]?
        if let serviceList = discoverServicesOptions.services?.keys { serviceUUIDs = Array(serviceList)}
        
        func onTimeout () {
            resolve([Strings.error: ErrorMessage.DISCOVER_SERVICES_FAILED, Strings.services: NSNull()] as NSDictionary)
        }
        
        discoverServicesTimer.set(callback: onTimeout, duration: discoverServicesOptions.duration)
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
    
    func read(){}
    
    func write(){}
    
    func setMtu(resolve: @escaping RCTPromiseResolveBlock){
        resolve([Strings.mtu: NSNull()] as NSDictionary)
    }
    
    func prepareServicesResponse() -> NSDictionary {
        let servicesMap: NSMutableDictionary = [:]
        
        guard let services = device?.services else {
            return [Strings.services: servicesMap]
        }
        
        for service in services {
            if let characteristics = service.characteristics {
                let characteristicsMap = NSMutableDictionary()
                
                for characteristic in service.characteristics! {
                    var properties = characteristic.properties
                    characteristicsMap[characteristic.uuid.uuidString] = [Strings.read: properties.contains(CBCharacteristicProperties.read),  Strings.write: properties.contains(CBCharacteristicProperties.write), Strings.writeWithoutResponse: properties.contains(CBCharacteristicProperties.writeWithoutResponse), Strings.notify: properties.contains(CBCharacteristicProperties.notify)] as NSDictionary
                }
                servicesMap[service.uuid.uuidString] = characteristicsMap
            }
        }
        
        return [Strings.services: servicesMap]
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
        
        var characteristicsMap = [CBUUID: CBCharacteristic]()
        
        for characteristic in characteristics {
            characteristicsMap[characteristic.uuid] = characteristic
        }
        
        serviceMap[service.uuid] = characteristicsMap
        
        if (serviceMap.keys.count >= device?.services?.count ?? 0) {
            discoverServicesTimer.cancel()
            promiseManager.resolvePromise(promiseType: .DISCOVER_SERVICES, payload: prepareServicesResponse())
        }
    }
}
