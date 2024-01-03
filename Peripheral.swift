//
//  Peripheral.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import CoreBluetooth

class Peripheral: NSObject {
    private var events: Events
    var device: CBPeripheral?

    init(events: Events) {
        self.events = events
    }

}

extension Peripheral: CBPeripheralDelegate {

}
