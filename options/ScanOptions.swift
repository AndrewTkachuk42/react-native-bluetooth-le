//
//  ScanOptions.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

class ScanOptions: NSObject {
    var address: String?
    var name: String?
    var hasFilters: Bool = false
    var shouldFindOne: Bool = false
    var scanDuration: Int = Constants.DEFAULT_TIMEOUT
    
    init(options: NSDictionary?) {
        if (options == nil) {
            return
        }
        
        address = options?[keys.address] as? String
        name = options?[keys.name] as? String
        scanDuration = options?[keys.duration] as? Int ?? Constants.DEFAULT_TIMEOUT
        shouldFindOne = options?[keys.findOne] as? Bool ?? false
        
        if (address != nil || name != nil) {
            hasFilters = true
        }
    }
    
    struct keys {
        static let address = "address"
        static let name = "name"
        static let duration = "duration"
        static let findOne = "findOne"
    }
}
