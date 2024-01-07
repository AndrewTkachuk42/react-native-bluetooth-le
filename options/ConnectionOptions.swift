//
//  ScanOptions.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 05.01.2024.
//

class ConnectionOptions: NSObject {
    var duration: Int = 0
    
    init(options: NSDictionary?) {
        if (options == nil) {
            return
        }
        
        duration = options?[keys.duration] as? Int ?? 0
    }
    
    struct keys {
        static let duration = "duration"
    }
}
