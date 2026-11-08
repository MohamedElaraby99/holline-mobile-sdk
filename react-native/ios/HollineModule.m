#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(HollineModule, RCTEventEmitter)

RCT_EXTERN_METHOD(open:(NSString *)company
                  name:(NSString *)name
                  phone:(NSString *)phone
                  source:(NSString *)source
                  baseUrl:(NSString *)baseUrl
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(joinMeeting:(NSString *)link
                  name:(NSString *)name
                  baseUrl:(NSString *)baseUrl
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isMeetingLink:(NSString *)link
                  baseUrl:(NSString *)baseUrl
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isInCall:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
