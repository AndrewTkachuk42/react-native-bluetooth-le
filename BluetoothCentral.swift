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
    private let promiseManager: PromiseManager!
    private let scanTimeout: Timeout = Timeout();
    private let connectionTimeout: Timeout = Timeout();
    
    private var isAdapterEnabled: Bool = false
    private var scanResponse: [NSDictionary] = []
    private var devices = [UUID : CBPeripheral]()
    private var scanOptions: ScanOptions = ScanOptions(options: nil)
    private var connectionOptions: ConnectionOptions = ConnectionOptions(options: nil)
    
    init(peripheralManager: Peripheral, promiseManager: PromiseManager, events: Events) {
        self.events = events
        self.promiseManager = promiseManager
        self.peripheralManager = peripheralManager
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        isAdapterEnabled = centralManager.state == .poweredOn
    }
    
    func startScan(options: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock) {
        if (!isAdapterEnabled) {
            let response: NSDictionary = [Strings.error: ErrorMessage.BLE_IS_OFF.rawValue, Strings.devices: NSArray()]
            resolve(response)
            return
        }
        
        if (centralManager.isScanning) {
            let response: NSDictionary = [Strings.error: ErrorMessage.IS_ALREADY_SCANNING.rawValue, Strings.devices: NSArray()]
            resolve(response)
            return
        }
        
        promiseManager.addPromise(promiseType: .SCAN,promise: resolve)
        scanOptions = ScanOptions(options: options)
        devices.removeAll()
        scanResponse = []
        
        setScanTimeout()
        centralManager?.scanForPeripherals(withServices: nil)
        
        
        events.emitStateChangeEvent(newState: ConnectionState.SCANNING)
    }
    
    func stopScan(resolve: RCTPromiseResolveBlock?) {
        scanTimeout.cancel()
        
        if (!centralManager.isScanning) {
            let response: NSDictionary = [Strings.error: ErrorMessage.IS_NOT_SCANNING.rawValue, Strings.isScaning: centralManager.isScanning]
            resolve?(response)
            return
        }
        
        promiseManager.addPromise(promiseType: .STOP_SCAN, promise: resolve)
        centralManager?.stopScan()
        events.emitStateChangeEvent(newState: .SCAN_COMPLETED)
        
        promiseManager.resolvePromise(promiseType: .SCAN, payload: prepareScanResopnse())
        promiseManager.resolvePromise(promiseType: .STOP_SCAN, payload: [Strings.isScaning: centralManager.isScanning, Strings.error: NSNull()])
    }
    
    func connect(address: NSString, options: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock) {
        let isConnected = peripheralManager.device?.state == .connected
        
        if (!isAdapterEnabled) {
            let response: NSDictionary = [Strings.error: ErrorMessage.BLE_IS_OFF.rawValue, Strings.isConnected: false]
            resolve(response)
            return
        }
        
        if (isConnected) {
            let response: NSDictionary = [Strings.error: NSNull(), Strings.isConnected: isConnected]
            resolve(response)
            return
        }
        
        
        
        guard let uuid = UUID(uuidString: address as String), let device =  devices[uuid] else {
            let response: NSDictionary = [Strings.error: ErrorMessage.DEVICE_NOT_FOUND.rawValue, Strings.isConnected: isConnected]
            resolve(response)
            return
        }
        
        promiseManager.addPromise(promiseType: .CONNECT, promise: resolve)
        connectionOptions = ConnectionOptions(options: options)
        setConnectionTimeout()
        peripheralManager.setPeripheral(peripheral: device)
        
        centralManager.connect(device)
    }
    
    func disconnect (resolve: RCTPromiseResolveBlock?) {
        connectionTimeout.cancel()
        
        let state = peripheralManager.device?.state
        let isConnected = state == .connected
        let isConnectedOrConnecting =  isConnected || state == .connecting
        
        if (!isConnectedOrConnecting) {
            resolve?([Strings.error: NSNull(), Strings.isConnected: isConnected] as NSDictionary)
        } else {promiseManager.addPromise(promiseType: .DISCONNECT, promise: resolve)}
        
        guard let device = peripheralManager.device else {return}
        centralManager.cancelPeripheralConnection(device)
    }
    
    func prepareScanResopnse () -> NSDictionary {
        return [Strings.error: NSNull(), Strings.devices: scanResponse]
    }
    
    func prepareDeviceData (device: CBPeripheral, rssi: NSNumber) -> NSDictionary {
        return [Strings.name: device.name as Any, Strings.address: device.identifier.uuidString, Strings.rssi: rssi]
    }
    
    func resolveConnectionPromise (error: ErrorMessage?) {
        let response: NSDictionary = [Strings.error: error ?? NSNull(), Strings.isConnected: peripheralManager.device?.state == .connected]
        promiseManager.resolvePromise(promiseType: .CONNECT, payload: response)
    }
    
    func resoveDisconnectPromise () {
        let response: NSDictionary = [Strings.error: NSNull() ,Strings.isConnected: peripheralManager.device?.state == .connected]
        promiseManager.resolvePromise(promiseType: .DISCONNECT, payload: response)
    }
    
    func setConnectionTimeout () {
        func onTimeout () {
            disconnect(resolve: nil)
            resolveConnectionPromise(error: .DEVICE_NOT_FOUND)
        }
        
        connectionTimeout.set(callback: onTimeout, duration: connectionOptions.duration)
    }
    
    func setScanTimeout () {
        func onTimeout () {
            stopScan(resolve: nil)
        }
        
        scanTimeout.set(callback: onTimeout, duration: scanOptions.scanDuration)
    }
    
    
    func satisfiesFilters (peripheral: CBPeripheral) -> Bool {
        if !scanOptions.hasFilters {return true}
        
        let address = scanOptions.address
        let name = scanOptions.name
        
        let addressFilter = address == nil ? true : address == peripheral.identifier.uuidString
        let nameFilter = name == nil ? true : name == peripheral.name
        
        return addressFilter && nameFilter
    }
}

extension BluetoothCentral: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (!satisfiesFilters(peripheral: peripheral) || devices[peripheral.identifier] != nil) {
            return
        }
        
        let deviceData = prepareDeviceData(device: peripheral, rssi: RSSI)
        events.emitDeviceFoundEvent(deviceData: deviceData)
        scanResponse.append(deviceData)
        
        devices[peripheral.identifier] = peripheral
        
        if scanOptions.shouldFindOne {stopScan(resolve: nil)}
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionTimeout.cancel()
        resolveConnectionPromise(error: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        resolveConnectionPromise(error: .CONNECTION_FAILED)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        resolveConnectionPromise(error: nil)
        resoveDisconnectPromise()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isAdapterEnabled = central.state == .poweredOn
        
        switch central.state {
        case .poweredOn:
            events.emitAdapterStateChangeEvent(newState: .ON)
            break
        case .poweredOff:
            events.emitAdapterStateChangeEvent(newState: .OFF)
            break
        case .resetting:
            events.emitAdapterStateChangeEvent(newState: .RESETTING)
            break
        case .unauthorized:
            events.emitAdapterStateChangeEvent(newState: .UNAUTHORIZED)
            break
        case .unsupported:
            events.emitAdapterStateChangeEvent(newState: .UNSUPPORTED)
            break
        default:
            events.emitAdapterStateChangeEvent(newState: AdapterState.UNKNOWN)
            break
        }
    }
}


