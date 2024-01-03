//
//  Timeout.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import Foundation

class Timeout {
    private var timeout: DispatchWorkItem?
    
    func set(callback: @escaping ()->Void, duration: Int = 0) {
        cancel()
        
        timeout = DispatchWorkItem {
            callback()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: timeout!)
    }
    
    func cancel () {
        timeout?.cancel()
    }
}
