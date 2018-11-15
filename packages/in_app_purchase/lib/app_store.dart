import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

const MethodChannel _channel = MethodChannel('plugins.flutter.io/in_app_purchase');

class AppStoreConnection implements InAppPurchaseConnection {
  @override
  Future<bool> isAvailable() => SKPaymentQueueWrapper.canMakePayments;

  @override
  // There's no such thing as "connecting" to the App Store like there is for
  // the Play Billing service. Always just return whether or not the user can
  // make payments here.
  Future<bool> connect() => isAvailable();

  @override
  Future<List<ProductInformation>> queryProductInformation(List<String> productIds) async {
    final SKProductsResponseWrapper response = await (await SKProductsRequestWrapper.start(productIds)).value;
    return Future<List<ProductInformation>>.value(<ProductInformation>[]);
  }

  @override
  void launchPurchaseFlow({
    @required ProductInformation product,
    @required OnConfirmationRequested onConfirmationRequested,
    @required OnPurchaseUpdated onPurchaseUpdated}) => throw UnimplementedError;
}

/// Wraps https://developer.apple.com/documentation/storekit/skpaymentqueue
class SKPaymentQueueWrapper {
  static Future<bool> get canMakePayments async => await _channel.invokeMethod('-[SKPaymentQueue canMakePayments:]');
}

/// Wraps https://developer.apple.com/documentation/storekit/skproduct
class SKProductWrapper { }

/// Wraps https://developer.apple.com/documentation/storekit/skproductsresponse
class SKProductsResponseWrapper {
  SKProductsResponseWrapper(this.products, this.invalidProductIdentifiers);

  final List<SKProductWrapper> products;
  final List<String> invalidProductIdentifiers;
}

/// Wraps https://developer.apple.com/documentation/storekit/skproductsrequest
///
/// This is more of a spiritual than literal translation, in keeping with Dart's
/// support for async/await and the desire to avoid managing native object
/// lifecycles from dart.
class SKProductsRequestWrapper {
  /// Initializes an `SkProductsRequest` and calls `start()` to fetch an
  /// [SkProductResponse]. Calling [CancelableOperation#cancel()] is
  /// equivalent to calling `.stop()` on a started request in the native API.
  static Future<CancelableOperation<SKProductsResponseWrapper>> start(List<String> productIdentifiers) async {
    final int id = await _channel.invokeMethod('-[SkProductRequest init:productIdentifiers:]', <String, dynamic>{'productIdentifiers': productIdentifiers});
    final dynamic start = await _channel.invokeMethod('-[SkProductRequest start:]', <String, dynamic>{'hash': id});
    // TODO: return actual result
    return CancelableOperation<SKProductsResponseWrapper>.fromFuture(
      Future<SKProductsResponseWrapper>.value(null),
      onCancel: () => _channel.invokeMethod('-[SkProductRequest stop:]', <String, dynamic>{'hash': id}));
  }
}