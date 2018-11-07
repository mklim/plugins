import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _storeReady = false;
  List<ProductInformation> _products = <ProductInformation>[];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final InAppPurchasePlugin plugin = InAppPurchasePlugin();
    final bool connected = await plugin.connection.connect();
    final List<ProductInformation> products = await plugin.connection.queryProductInformation(<String>['consumable', 'upgrade', 'subscription']);
    setState(() {
      _storeReady = connected;
      _products = products;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final Widget storeHeader = ListTile(title: Card(child: ListTile(
      leading: Icon(_storeReady ? Icons.check : Icons.block),
      title: Text('The store is ' + (_storeReady ? 'open' :  'closed') + '.'))));
    final List<Widget> children = _products.map((ProductInformation product) =>
      ListTile(trailing: Text(product.price), title: Text(product.title), subtitle: Text(product.description))).toList();
    children.insert(0, storeHeader);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('In app purchase plugin example app'),
        ),
        body: Center(
          child: ListView(children: children)
        ),
      ),
    );
  }
}
