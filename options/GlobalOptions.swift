//
//  PeripheralOptions.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 08.01.2024.
//

class GlobalOptions: NSObject {
    var timeoutDuration: Int = Constants.DEFAULT_TIMEOUT
    var autoDecode = false
    
    init(options: NSDictionary?) {
        if (options == nil) {
            return
        }
        
        timeoutDuration = options?[keys.timeoutDuration] as? Int ?? Constants.DEFAULT_TIMEOUT
        autoDecode = options?[keys.autoDecodeBytes] as? Bool ?? false
    }
    
    struct keys {
        static let timeoutDuration = "timeoutDuration"
        static let autoDecodeBytes = "autoDecodeBytes"
    }
}
