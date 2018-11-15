#import "InAppPurchasePlugin.h"
#import <StoreKit/StoreKit.h>

@implementation InAppPurchasePlugin
NSMutableArray* skProductRequests;
NSMutableDictionary* skProductResults;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/in_app_purchase"
                                  binaryMessenger:[registrar messenger]];
  InAppPurchasePlugin* instance = [[InAppPurchasePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    skProductRequests = [[NSMutableArray alloc] init];
    skProductResults = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"-[SKPaymentQueue canMakePayments:]" isEqualToString:call.method]) {
      [self canMakePayments:result];
  } else if ([@"-[SkProductRequest init:productIdentifiers:]" isEqualToString:call.method]) {
      [self initializeSKProductsRequest:call.arguments[@"productIdentifiers"] result:result];
  } else if ([@"-[SkProductRequest start:]" isEqualToString:call.method]) {
      [self startSKProductsRequest:call.arguments[@"hash"] result:result];
  } else if ([@"-[SkProductRequest stop:]" isEqualToString:call.method]) {
      [self stopSKProductsRequest:call.arguments[@"hash"] result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)canMakePayments:(FlutterResult)result {
    result([NSNumber numberWithBool:[SKPaymentQueue canMakePayments]]);
}

- (void)initializeSKProductsRequest:(NSArray*)productIdentifiers result:(FlutterResult)result {
    NSSet* set = [NSSet setWithArray:productIdentifiers];
    SKProductsRequest* req = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    req.delegate = self;
    [skProductRequests addObject:req];
    result([NSNumber numberWithInt:[req hash]]);
}

- (void)startSKProductsRequest:(NSNumber*)hash result:(FlutterResult)result {
    int reqIndex = [skProductRequests indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SKProductsRequest* req = (SKProductsRequest*)obj;
        return [req hash] == [hash intValue];
    }];
    if (reqIndex == NSNotFound) {
        // TODO: log error, result error?
        result(@"Couldn't find a matching request.");
        return;
    }
    SKProductsRequest* req = skProductRequests[reqIndex];
    [skProductResults setValue:result forKey: [NSString stringWithFormat:@"%d", [req hash]]];
    [req start];
}

- (void)stopSKProductsRequest:(NSNumber*)hash result:(FlutterResult)result {
    int reqIndex = [skProductRequests indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SKProductsRequest* req = (SKProductsRequest*)obj;
        return [req hash] == [hash intValue];
    }];
    if (reqIndex == NSNotFound) {
        // TODO: log error, result error?
        return;
    }
    SKProductsRequest* req = skProductRequests[reqIndex];
    [skProductRequests removeObject:req];
    [skProductResults removeObjectForKey:hash];
    [req cancel];
    result(nil);
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSString* hash = [NSString stringWithFormat:@"%d", [request hash]];
    FlutterResult result = [skProductResults objectForKey:hash];
    if (result == nil) {
        // TODO: log error, result error?
        return;
    }

    int numProducts = [response.products count];
    int numInvalidProducts = [response.invalidProductIdentifiers count];
    for (NSString* invalidProduct in response.invalidProductIdentifiers) {
    }
    // TODO: return actual result
    result([NSString stringWithFormat:@"Got %d products and %d invalid ones", numProducts, numInvalidProducts]);

    [skProductResults removeObjectForKey:hash];
    [skProductRequests removeObject:request];
}

@end
