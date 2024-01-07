//
//  Promises.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 04.01.2024.
//

import Foundation

class PromiseManager: NSObject {
    var pendingPromises = [PromiseType : [RCTPromiseResolveBlock]]()
    
    override init() {
    }
    
    func resolvePromise(promiseType: PromiseType, payload: NSDictionary) {
        let nextPromise = getNextPromise(promiseType: promiseType)
        
        nextPromise?(payload)
    }
    
    func addPromise (promiseType: PromiseType, promise: RCTPromiseResolveBlock?) {
        if (promise == nil) {
            return
        }
        
        if (pendingPromises[promiseType] == nil) {
            pendingPromises[promiseType] = []
        }
        
        pendingPromises[promiseType]?.append(promise!)
    }
    
    private func getNextPromise(promiseType: PromiseType) -> RCTPromiseResolveBlock? {
        guard var list = pendingPromises[promiseType], let nextPromise = list.first else {return nil}
        
        list.removeFirst()
        pendingPromises[promiseType] = list
        
        return nextPromise
    }
}

enum PromiseType {
    case SCAN,
         STOP_SCAN,
         CONNECT,
         DISCONNECT,
         DISCOVER_SERVICES,
         READ,
         WRITE,
         NOTIFICATIONS,
         CONNECTION_STATE,
         IS_CONNECTED,
         IS_ENABLED
}
