//
//  Promises.swift
//  react-native-bluetooth-le
//
//  Created by Andrew Tkachuk on 04.01.2024.
//

import Foundation

class PromiseManager: NSObject {
    var pendingPromises = [PromiseType : [(RCTPromiseResolveBlock, Timeout?)]]()
    
    override init() {
    }
    
    func resolvePromise(promiseType: PromiseType, payload: NSDictionary) {
        guard let (resolve, timeout) = getNextPromise(promiseType: promiseType) else {return}
        
        timeout?.cancel()
        resolve(payload)
    }
    
    func addPromise (promiseType: PromiseType, promise: RCTPromiseResolveBlock?, timeout: Int?) {
        if (promise == nil) {
            return
        }
        
        if (pendingPromises[promiseType] == nil) {
            pendingPromises[promiseType] = []
        }
        
        let promiseTimeout = getTimeout(promiseType: promiseType, duration: timeout)
        pendingPromises[promiseType]?.append((promise!, promiseTimeout))
    }
    
    private func getTimeout (promiseType: PromiseType, duration: Int?) -> Timeout? {
        guard let timeoutDuration = duration, timeoutDuration > 0 else {return nil}
        
        func onTimeout () {
            resolvePromise(promiseType: promiseType, payload: [Strings.error: ErrorMessage.TIMEOUT.rawValue] as NSDictionary)
        }
        
        let timeout = Timeout()
        timeout.set(callback: onTimeout, duration: timeoutDuration)
        return timeout
    }
    
    
    private func getNextPromise(promiseType: PromiseType) -> (RCTPromiseResolveBlock, Timeout?)? {
        guard var list = pendingPromises[promiseType], let nextPromise = list.first else {return nil}
        
        list.removeFirst()
        pendingPromises[promiseType] = list
        
        return nextPromise
    }
    
    func resolveAllWithError (error: ErrorMessage) {
        let response = [Strings.error: error.rawValue]
        
        for items in pendingPromises.values {
            for item in items {
                let (promise, timeout) = item
                timeout?.cancel()
                promise(response)
            }
        }
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
         IS_ENABLED,
         DESTROY
}
