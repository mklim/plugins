import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';

/// An [InAppPurchaseConnection] that wraps Google Play Billing.
///
/// This translates various [BillingClientManager] calls and responses into the
/// common plugin API.
class GooglePlayConnection implements InAppPurchaseConnection {
  BillingClientManager _billingClient = BillingClientManager();

  @override
  Future<bool> isAvailable() async {
    return await _billingClient.isReady;
  }

  @override
  Future<bool> connect() async {
    final bool alreadyConnected = await isAvailable();
    if (alreadyConnected) {
      return true;
    }

    final int responseCode = await _billingClient.startConnection(onBillingServiceDisconnected: () {
        print('Billing service disconnected');
      }
    );
    final bool finishedSuccessfully = responseCode == BillingClientManager.kBillingResponseOK;
    if (!finishedSuccessfully) {
      print('Failed to connect to Play Billing, code $responseCode');
    }

    if (finishedSuccessfully) {
      return await _billingClient.isReady;
    } else {
      return false;
    }
  }

  @override
  Future<List<ProductInformation>> queryProductInformation(List<String> productIds) async {
    final List<ProductInformation> productInformation = <ProductInformation>[];
    for (SkuType type in SkuType.values) {
      final SkuDetailsResponse response = await _billingClient.querySkuDetailsAsync(type: type, skus: productIds);
      if (response.responseCode == BillingClientManager.kBillingResponseOK) {
        productInformation.addAll(response.skuDetailsList.map((SkuDetails skuDetail) => skuDetail.toProductInformation()));
      }
    }
    return productInformation;
  }


  @override
  void launchPurchaseFlow({
    @required ProductInformation product,
    @required OnConfirmationRequested onConfirmationRequested, // Deliberately unused, Play Billing shows its own Purchase Flow UI.
    @required OnPurchaseUpdated onPurchaseUpdated}) {
      final SkuType type = skuTypeFromProductType(product.productType);
      onPurchaseUpdated(_billingClient.launchBillingFlow(type, product.id));
    }
}

/// Dart equivalent of `com.android.billingclient.api.BillingClient.SkuType`.
enum SkuType {
  inapp,
  subs,
}

/// Translates a string constant into the equivalent [SkuType].
///
/// Returns null if the description isn't a matching SkuType.
SkuType skuTypeFromDescription(String description) {
  return SkuType.values.firstWhere((SkuType type) => describeEnum(type) == description);
}

ProductType productTypeFromSkuType(SkuType type) {
  switch (type) {
    case SkuType.inapp:
      return ProductType.item;
    case SkuType.subs:
      return ProductType.subscription;
    default:
      throw UnimplementedError;
  }
}

SkuType skuTypeFromProductType(ProductType type) {
  switch (type) {
    case ProductType.item:
      return SkuType.inapp;
    case ProductType.subscription:
      return SkuType.subs;
    default:
      throw UnimplementedError;
  }
}

/// Dart wrapper around `com.android.billingclient.api.SkuDetails`.
class SkuDetails {
  SkuDetails(
    this.description,
    this.freeTrialPeriod,
    this.introductoryPrice,
    this.introductoryPriceMicros,
    this.introductoryPriceCycles,
    this.introductoryPricePeriod,
    this.price,
    this.priceAmountMicros,
    this.priceCurrencyCode,
    this.sku,
    this.subscriptionPeriod,
    this.title,
    this.type,
    this.isRewarded,
  );

  /// Constructs an instance of this from a key value map of data.
  ///
  /// The map needs to have string keys with values matching all of the instance
  /// fields on this class.
  static SkuDetails fromMap(Map<dynamic, dynamic> map) =>
    SkuDetails(
      map['description'],
      map['freeTrialPeriod'],
      map['introductoryPrice'],
      map['introductoryPriceMicros'],
      map['introductoryPriceCycles'],
      map['introductoryPricePeriod'],
      map['price'],
      map['priceAmountMicros'],
      map['priceCurrencyCode'],
      map['sku'],
      map['subscriptionPeriod'],
      map['title'],
      skuTypeFromDescription(map['type']),
      map['isRewarded']);

  /// Creates an instance of [ProductInformation] that's equivalent to this.
  ///
  /// This conversion can only happen one way, since [ProductInformation] holds
  /// much less information than this.
  ProductInformation toProductInformation() =>
    ProductInformation(
      id: sku,
      description: description,
      introductoryPrice: introductoryPrice,
      price: price,
      priceCurrencyCode: priceCurrencyCode,
      subscriptionPeriod: subscriptionPeriod,
      title: title,
      productType: productTypeFromSkuType(type));

  final String description;
  final String freeTrialPeriod;
  final String introductoryPrice;
  final String introductoryPriceMicros;
  final String introductoryPriceCycles;
  final String introductoryPricePeriod;
  final String price;
  final int priceAmountMicros;
  final String priceCurrencyCode;
  final String sku;
  final String subscriptionPeriod;
  final String title;
  final SkuType type;
  final bool isRewarded;
}

/// Return value for [BillingClientManager.querySkuDetailsAsync]
class SkuDetailsResponse {
  SkuDetailsResponse(this.responseCode, this.skuDetailsList);
  final int responseCode;
  final List<SkuDetails> skuDetailsList;
}

/// Wraps `com.android.billingclient.api.BillingClientStateListener.onServiceDisconnected()`.
typedef void OnBillingServiceDisconnected();


/// Wraps a Java `com.android.billingclient.api.BillingClient` instance.
///
/// This class can be used directly instead of [GooglePlayConnection] to
/// directly call Play-specific APIs.
///
/// In general this API conforms to the Java
/// `com.android.billingclient.api.BillingClient` API as much as possible, with
/// some minor changes to account for language differences. Callbacks have been
/// converted to futures where appropriate.
class BillingClientManager {
  BillingClientManager() {
    _channel.setMethodCallHandler(_callHandler);
  }
  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/in_app_purchase');
  List<Map<String, Function>> _callbacks = <Map<String, Function>>[];

  /// `BillingClient.BillingResponse.OK`
  static const int kBillingResponseOK = 0;

  /// Wraps `BillingClient#isReady()`.
  Future<bool> get isReady async {
    return await _channel.invokeMethod('isReady');
  }

  /// Wraps `BillingClient#startConnection(BillingClientStateListener)`.
  ///
  /// [onBillingServiceConnected] has been converted from a callback parameter
  /// to the Future result returned by this function. This returns the
  /// `BillingClient.BillingResponse` `responseCode` of the connection result.
  Future<int> startConnection({@required OnBillingServiceDisconnected onBillingServiceDisconnected}) async {
    final Map<String, Function> callbacks = <String, Function> {
      'OnBillingServiceDisconnected': onBillingServiceDisconnected,
    };
    _callbacks.add(callbacks);
    return await _channel.invokeMethod("startConnection", <String, dynamic>{'handle': _callbacks.length - 1});
  }

  /// Wraps `BillingClient#querySkuDetailsAsync(SkuDetailsParams, SkuDetailsResponseListener)`.
  ///
  /// The [listener] callback parameter has been converted to the Future output
  /// of this function.
  Future<SkuDetailsResponse> querySkuDetailsAsync({SkuType type, List<String> skus}) async {
    final Map<dynamic, dynamic> response = await _channel.invokeMethod("querySkuDetailsAsync", <String, dynamic>{'skuType': describeEnum(type), 'skusList': skus});
    final int responseCode = response['responseCode'];
    final List<Map<dynamic, dynamic>> skuDetailsMap = response['skuDetailsList'].cast<Map<dynamic, dynamic>>().toList();
    final List<SkuDetails> skuDetailsList = skuDetailsMap.map((Map<dynamic, dynamic> skuDetailsInfo) => SkuDetails.fromMap(skuDetailsInfo)).toList();
    return SkuDetailsResponse(responseCode, skuDetailsList);
  }

  Future<int> launchBillingFlow(SkuType type, String skuId) async {
    final Map<dynamic, dynamic> response = await _channel.invokeMethod('launchBillingFlow', <String, dynamic>{'skuType': type, 'skuId': skuId});
    return response['statusCode'];
  }

  Future<void> _callHandler(MethodCall call) async {
    switch (call.method) {
      case 'onBillingServiceDisconnected':
        final int handle = call.arguments['handle'];
        await _callbacks[handle]['OnBillingServiceDisconnected']();
        break;
    }
  }
}