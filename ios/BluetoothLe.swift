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
    func setMtu(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        peripheral.setMtu(resolve: resolve)
    }
    
    @objc
    func setOptions(_ options: NSDictionary) -> Void {
        // TODO: implement options
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

