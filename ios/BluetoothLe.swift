@objc(BluetoothLe)
class BluetoothLe: RCTEventEmitter {
    private var bluetoothCentral: BluetoothCentral!
    private var peripheral: Peripheral!
    private var events: Events!
    private let promiseManager = PromiseManager()
    private var hasListeners = false;
    
    override init() {
        super.init()
        
        events = Events(sendEvent: sendEvent)
        peripheral = Peripheral(promiseManager: promiseManager, events: events)
        bluetoothCentral = BluetoothCentral(peripheralManager: peripheral,promiseManager: promiseManager, events: events)
    }
    
    @objc
    func startScan(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        bluetoothCentral.startScan(options: options, resolve: resolve)
    }
    
    @objc
    func stopScan(_ resolve: @escaping RCTPromiseResolveBlock,
                  rejecter reject:  RCTPromiseRejectBlock) -> Void {
        bluetoothCentral.stopScan(resolve: resolve)
    }
    
    @objc
    func connect(_ address: NSString, options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        bluetoothCentral.connect(address: address, options: options, resolve: resolve)
    }
    
    @objc
    func disconnect(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        bluetoothCentral.disconnect(resolve: resolve)
    }
    
    @objc
    func discoverServices(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.discoverServices(options: options, resolve: resolve)
    }
    
    @objc
    func requestMtu(_ size: NSNumber, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.requestMtu(resolve: resolve)
    }
    
    @objc
    func writeString(_ serviceId: NSString, characteristicId: NSString, value: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.writeString(serviceId: serviceId, characteristicId: characteristicId, value: value, resolve: resolve)
    }
    
    @objc
    func writeStringWithoutResponse(_ serviceId: NSString, characteristicId: NSString, value: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.writeStringWithoutResponse(serviceId: serviceId, characteristicId: characteristicId, value: value, resolve: resolve)
    }
    
    @objc
    func write(_ serviceId: NSString, characteristicId: NSString, value: [UInt8], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.write(serviceId: serviceId, characteristicId: characteristicId, value: value, resolve: resolve)
    }
    
    @objc
    func writeWithoutResponse(_ serviceId: NSString, characteristicId: NSString, value: [UInt8], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.writeWithoutResponse(serviceId: serviceId, characteristicId: characteristicId, value: value, resolve: resolve)
    }
    
    @objc
    func read(_ serviceId: NSString, characteristicId: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.read(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve)
    }
    
    @objc
    func enableNotifications(_ serviceId: NSString, characteristicId: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.enableNotifications(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve)
    }
    
    @objc
    func disableNotifications(_ serviceId: NSString, characteristicId: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.disableNotifications(serviceId: serviceId, characteristicId: characteristicId, resolve: resolve)
    }
    
    @objc
    func setOptions(_ options: NSDictionary) -> Void {
        let globalOptions = GlobalOptions(options: options)
        peripheral.globalOptions = globalOptions
        bluetoothCentral.globalOptions = globalOptions
    }
    
    @objc
    func isEnabled(_ resolve: @escaping RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        resolve([Strings.isEnabled: bluetoothCentral.isAdapterEnabled] as NSDictionary)
    }
    
    @objc
    func isConnected(_ resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: RCTPromiseRejectBlock) {
        resolve([Strings.isConnected: peripheral.device?.state == .connected] as NSDictionary)
    }
    
    @objc
    func getConnectionState(_ resolve: @escaping RCTPromiseResolveBlock,
                            rejecter reject: RCTPromiseRejectBlock) {
        peripheral.getConnectionState(resolve: resolve)
    }
    
    @objc
    func destroy(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        bluetoothCentral.destroy(resolve: resolve)
    }
    
    override func supportedEvents() -> [String]! {
        return ["CONNECTION_STATE", "ADAPTER_STATE", "DEVICE_FOUND", "NOTIFICATION", "ERROR"]
    }
    
    override func startObserving() {
        hasListeners = true
    }
    
    override func stopObserving() {
        hasListeners = false
    }
    
    override func sendEvent(withName name: String!, body: Any!) {
        if (!hasListeners) {
            return
        }
        
        super.sendEvent(withName: name, body: body)
    }
}

