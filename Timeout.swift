//
//  Timeout.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 03.01.2024.
//

import Foundation

class Timeout {
    private var timeout: DispatchWorkItem?
    
    func set(callback: @escaping ()->Void, duration: Int?) {
        cancel()
        
        guard let timeoutDuration = duration, timeoutDuration > 0 else {return}
        
        timeout = DispatchWorkItem {
            callback()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeoutDuration), execute: timeout!)
    }
    
    func cancel () {
        timeout?.cancel()
    }
}
