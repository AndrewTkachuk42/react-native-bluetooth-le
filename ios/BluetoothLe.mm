#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(BluetoothLe, NSObject)

RCT_EXTERN_METHOD(setOptions:(NSDictionary) options
                  )

//RCT_EXTERN_METHOD(setupOptions:(NSDictionary) value
//    (RCTPromiseResolveBlock)resolve
//    rejecter:(RCTPromiseRejectBlock)reject
//)

RCT_EXTERN_METHOD(startScan:(NSDictionary *)options)
RCT_EXTERN_METHOD(stopScan)


+ (BOOL)requiresMainQueueSetup
{
    return NO;
}


@end


