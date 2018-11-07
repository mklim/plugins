import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/google_play.dart';
import 'package:in_app_purchase/app_store.dart';
import 'package:flutter/foundation.dart';

/// Called if the storefront needs the app to confirm the user's purchase.
///
/// When this is triggered the app should show a UI to the user allowing them
/// to specify the quantity of the item desired and to confirm their desire to
/// purchase the item. Call [confirmPurchase] with the given quantity and the
/// user's information once the user confirms their purchase through the app's
/// UI.
///
/// This will never be triggered by billing SDKs that show their own purchase
/// flow UI, like Google Play.
typedef void OnConfirmationRequested(Future<ConfirmPurchase> confirmPurchase);

/// Call to confirm that [hashedUsername] is purchasing [quantity].
typedef void ConfirmPurchase({@required int quantity, String hashedUsername});

/// This is called when the purchase flow has been completed.
typedef void OnPurchaseUpdated(Future<int> statusCode);

/// Directly communicates with an in app purchasing platform.
abstract class InAppPurchaseConnection {
  /// Returns true if the user can make in app purchases.
  Future<bool> isAvailable();

  /// Attempts to connect to the in app purchasing platform.
  ///
  /// Does nothing if the user is already connected and can already make in app
  /// purchases. Returns whether the user is connected.
  Future<bool> connect();

  /// Get [ProductInformation] for the corresponding identifiers.
  Future<List<ProductInformation>> queryProductInformation(List<String> productIds);

  /// Shows a purchase UI for the given [product].
  void launchPurchaseFlow({
    @required ProductInformation product,
    @required OnConfirmationRequested onConfirmationRequested,
    @required OnPurchaseUpdated onPurchaseUpdated});
}

/// Store listing information for a product.
///
/// This information needs to be manually created in each of the various
/// purchasing platform's app management consoles.
class ProductInformation {
  ProductInformation({
    this.id,
    this.description,
    this.title,
    this.price,
    this.priceCurrencyCode,
    this.introductoryPrice,
    this.subscriptionPeriod,
    this.productType,
  });

  /// A unique identifier.
  final String id;

  /// The localized, human-readable description.
  final String description;

  /// The localized, human-readable title.
  final String title;

  /// The formatted price, including localized currency. (Tax not included.)
  final String price;

  /// ISO 4217 currency code for the price.
  final String priceCurrencyCode;

  /// Formatted and localized introductory price.
  ///
  /// It's only possible to set this on subscriptions.
  final String introductoryPrice;

  /// Subscription period, specified in ISO 8601 format
  ///
  /// It's only possible to set this on subscriptions.
  final String subscriptionPeriod;

  /// See [ProductType].
  final ProductType productType;
}

/// Loose categorizations of products.
enum ProductType {
  /// Ownership is determined on other factors besides time.
  item,

  /// Ownership is determined based the current date, and may expire.
  subscription,
}

class InAppPurchasePlugin {
  /// The [InAppPurchaseConnection] implemented for this platform.
  ///
  /// Throws an [UnsupportedError] when ran on a platform other than Android or
  /// iOS.
  InAppPurchaseConnection connection = _createConnection();

  static InAppPurchaseConnection _createConnection() {
    if (Platform.isAndroid) {
      return GooglePlayConnection();
    } else if (Platform.isIOS) {
      return AppStoreConnection();
    }

    throw UnsupportedError('InAppPurchase plugin only works on Android and iOS.');
  }
}
