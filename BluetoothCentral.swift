//
//  Scanner.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 02.01.2024.
//

import CoreBluetooth

class BluetoothCentral: NSObject {
    private var centralManager: CBCentralManager!
    private let peripheralManager: Peripheral!
    private let events: Events!
    private let timeout: Timeout = Timeout();
    
    private var isAdapterEnabled: Bool = false
    private var devices: [CBPeripheral] = []
    private var scanOptions: ScanOptions = ScanOptions(options: nil)
    
    init(peripheral: Peripheral, events: Events) {
        self.events = events
        self.peripheralManager = peripheral
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        isAdapterEnabled = centralManager.state == .poweredOn
    }
    
    func startScan(options: NSDictionary?) {
        if (!isAdapterEnabled) {
            return
        }
        if (centralManager.isScanning) {
            return
        }
        
        scanOptions = ScanOptions(options: options)
        devices.removeAll()
        
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        timeout.set(callback: stopScan, duration: scanOptions.scanDuration)
        events.emitStateChangeEvent(newState: ConnectionState.SCANNING)
    }
    
    func stopScan() {
        timeout.cancel()
        centralManager?.stopScan()
        
        events.emitStateChangeEvent(newState: ConnectionState.SCAN_COMPLETED)
    }
    
    
    func prepareDeviceData (device: CBPeripheral, rssi: NSNumber) -> NSDictionary {
        return [Strings.name: device.name as Any, Strings.address: device.identifier.uuidString, Strings.rssi: rssi]
    }
    
    func satisfiesFilters (peripheral: CBPeripheral) -> Bool {
        if !scanOptions.hasFilters {return true}
        
        let address = scanOptions.address
        let name = scanOptions.name
        
        var addressFilter = address == nil ? true : address == peripheral.identifier.uuidString
        var nameFilter = name == nil ? true : name == peripheral.name
        
        return addressFilter && nameFilter
    }
}

extension BluetoothCentral: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (!satisfiesFilters(peripheral: peripheral)) {
            return
        }
        
        if scanOptions.shouldFindOne {stopScan()}
        
        events.emitDeviceFoundEvent(deviceData: prepareDeviceData(device: peripheral, rssi: RSSI))
        devices.append(peripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isAdapterEnabled = central.state == .poweredOn
        
        switch central.state {
        case .poweredOn:
            events.emitAdapterStateChangeEvent(newState: AdapterState.ON)
            break
        case .poweredOff:
            events.emitAdapterStateChangeEvent(newState: AdapterState.OFF)
            break
        case .resetting:
            events.emitAdapterStateChangeEvent(newState: AdapterState.RESETTING)
            break
        case .unauthorized:
            events.emitAdapterStateChangeEvent(newState: AdapterState.UNAUTHORIZED)
            break
        case .unsupported:
            events.emitAdapterStateChangeEvent(newState: AdapterState.UNSUPPORTED)
            break
        default:
            events.emitAdapterStateChangeEvent(newState: AdapterState.UNKNOWN)
            break
        }
    }
}


