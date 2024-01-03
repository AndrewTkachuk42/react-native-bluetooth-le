@objc(BluetoothLe)
class BluetoothLe: RCTEventEmitter {
    private var bluetoothCentral: BluetoothCentral!
    private var peripheral: Peripheral!
    private var events: Events!

    override init() {
        super.init()

        events = Events(sendEvent: sendEvent)
        peripheral = Peripheral(events: events)
        bluetoothCentral = BluetoothCentral(peripheral: peripheral, events: events)
    }

    @objc
    func setOptions(_ options: NSDictionary) -> Void {
        // TODO: implement options
    }

    @objc
    func startScan(_ options: NSDictionary) -> Void {
        bluetoothCentral.startScan(options: options)
    }

    @objc
    func stopScan() -> Void {
        bluetoothCentral.stopScan()
    }

    override func supportedEvents() -> [String]! {
        return ["CONNECTION_STATE", "ADAPTER_STATE", "DEVICE_FOUND", "NOTIFICATION", "ERROR"]
    }
}

