//
//  DiscoverServicesOptoions.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 07.01.2024.
//

import Foundation

//
//  ScanOptions.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import CoreBluetooth

class DiscoverServicesOptions: NSObject {
    var services: [CBUUID: [CBUUID]]?
    var duration: Int = 0
    
    init(options: NSDictionary?) {
        super.init()
        
        if (options == nil) {
            return
        }
        
        duration = options?[keys.duration] as? Int ?? 0
        services = getServices(options: options!)
    }
    
    func getServices (options: NSDictionary) -> [CBUUID: [CBUUID]]? {
        guard let servicesMap = options[keys.services] as? NSDictionary else {return nil}
        guard let serviceList = servicesMap.allKeys as? [String] else {return nil}
        
        var servicesToDiscover = [CBUUID: [CBUUID]]()
        for service in serviceList {
            guard let characteristics = servicesMap[service] as? [String] else {continue}
            
            if (characteristics.count == 0) {
                servicesToDiscover[CBUUID.init(string: service)] = nil
                continue
            }
            
            servicesToDiscover[CBUUID.init(string: service)] = characteristics.map{CBUUID.init(string: $0)}
        }
        
        return servicesToDiscover
    }
    
    struct keys {
        static let services = "services"
        static let duration = "duration"
    }
}
