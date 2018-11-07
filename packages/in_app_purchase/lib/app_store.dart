import 'package:in_app_purchase/in_app_purchase.dart';

class AppStoreConnection implements InAppPurchaseConnection {
  @override
  Future<bool> isAvailable() => throw UnimplementedError;

  @override
  Future<bool> connect() => throw UnimplementedError;

  @override
  Future<List<ProductInformation>> queryProductInformation(List<String> productIds) => throw UnimplementedError;
}