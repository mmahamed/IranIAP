import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:myket_iap/myket_iap.dart';
import 'dart:async';
import 'dart:developer';

import 'package:myket_iap/util/iab_result.dart';
import 'package:myket_iap/util/inventory.dart';
import 'package:myket_iap/util/purchase.dart';

enum IranIAPMarket { bazaar, myket, unknown }

class IranIAPPurchase {
  final String productId;
  final String purchaseToken;
  final String? orderId;
  final String? payload;
  final String? packageName;
  final DateTime? purchaseTime;

  IranIAPPurchase({
    required this.productId,
    required this.purchaseToken,
    this.orderId,
    this.payload,
    this.packageName,
    this.purchaseTime,
  });
}

class IranIAP {
  static IranIAPMarket get currentMarket {
    final flavor = appFlavor?.toLowerCase();
    if (flavor == 'bazaar') return IranIAPMarket.bazaar;
    if (flavor == 'myket') return IranIAPMarket.myket;
    return IranIAPMarket.unknown;
  }

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initializes the IAP service based on the detected market flavor.
  /// [bazaarKey] is required if the flavor is 'bazaar'.
  /// [myketKey] is required if the flavor is 'myket'.
  static Future<void> initialize({
    String? bazaarKey,
    String? myketKey,
    VoidCallback? onDisconnected,
    Function(String error)? onFailed,
  }) async {
    final market = currentMarket;

    if (market == IranIAPMarket.bazaar) {
      if (bazaarKey == null) throw ArgumentError('bazaarKey is required for Bazaar flavor');

      final completer = Completer<void>();

      await FlutterPoolakey.connect(
        bazaarKey,
        onSucceed: () {
          log('IranIap: Connected to Bazaar successfully');
          _isInitialized = true;
          if (!completer.isCompleted) completer.complete();
        },
        onFailed: () {
          log('IranIap: Failed to connect to Bazaar');
          _isInitialized = false;
          if (onFailed != null) onFailed('Failed to connect to Bazaar');
          if (!completer.isCompleted) completer.completeError('Failed to connect to Bazaar');
        },
        onDisconnected: () {
          log('IranIap: Disconnected from Bazaar service');
          _isInitialized = false;
          if (onDisconnected != null) onDisconnected();
        },
      );

      return completer.future;
    } else if (market == IranIAPMarket.myket) {
      if (myketKey == null) throw ArgumentError('myketKey is required for Myket flavor');

      final result = await MyketIAP.init(
        rsaKey: myketKey,
        enableDebugLogging: kDebugMode,
      );

      if (result?.isSuccess() ?? false) {
        log('IranIap: Myket IAP initialized successfully: ${result?.mMessage}');
        _isInitialized = true;
      } else {
        log('IranIap: Myket IAP Setup failed: ${result?.mMessage}');
        _isInitialized = false;
        if (onFailed != null) onFailed(result?.mMessage ?? '');
        throw Exception('Myket IAP Setup failed: ${result?.mMessage}');
      }
    } else {
      log('IranIap: Unknown market flavor. IAP will not work.');
    }
  }

  /// Initiates a purchase for the given [productId].
  static Future<IranIAPPurchase?> purchase(String productId, {String payload = ''}) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;

    if (market == IranIAPMarket.bazaar) {
      try {
        final purchaseInfo = await FlutterPoolakey.purchase(productId, payload: payload);
        return IranIAPPurchase(
          productId: purchaseInfo.productId,
          purchaseToken: purchaseInfo.purchaseToken,
          orderId: purchaseInfo.orderId,
          payload: purchaseInfo.payload,
          packageName: purchaseInfo.packageName,
          purchaseTime: DateTime.fromMillisecondsSinceEpoch(purchaseInfo.purchaseTime),
        );
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        return null;
      }
    } else if (market == IranIAPMarket.myket) {
      final response = await MyketIAP.launchPurchaseFlow(sku: productId, payload: payload);
      final result = response[MyketIAP.RESULT] as IabResult;
      final purchase = response[MyketIAP.PURCHASE] as Purchase;
      if (result.isFailure()) {
        throw Exception('Myket Purchase failed: ${result.mMessage}');
      }
      return IranIAPPurchase(
        productId: purchase.mSku,
        purchaseToken: purchase.mToken,
        orderId: purchase.mOrderId,
        payload: purchase.mDeveloperPayload,
        packageName: purchase.mPackageName,
        purchaseTime: DateTime.fromMillisecondsSinceEpoch(purchase.mPurchaseTime),
      );
    } else {
      throw Exception('Unsupported market');
    }
  }

  /// Consumes a purchase given the [purchaseToken].
  static Future<bool> consume(String? bazaarPurchaseToken, Purchase? myketPurchaseObject) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;
    if (market == IranIAPMarket.bazaar && bazaarPurchaseToken == null) throw Exception('purchaseToken is required');
    if (market == IranIAPMarket.myket && myketPurchaseObject == null) throw Exception('purchase object is required');
    if (market == IranIAPMarket.bazaar) {
      return await FlutterPoolakey.consume(bazaarPurchaseToken!);
    } else if (market == IranIAPMarket.myket) {
      final response = await MyketIAP.consume(purchase: myketPurchaseObject!);
      final result = response[MyketIAP.RESULT] as IabResult;
      // final purchase = response[MyketIAP.PURCHASE] as Purchase;
      return result.isSuccess();
      // if (!result.isSuccess()) {
      //   throw Exception('Myket Consume failed: ${result.mMessage}');
      // }
    }
    return false;
  }

  /// Queries all owned (purchased) items.
  static Future<List<IranIAPPurchase>> queryPurchases() async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;

    if (market == IranIAPMarket.bazaar) {
      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      return purchases
          .map((p) => IranIAPPurchase(
                productId: p.productId,
                purchaseToken: p.purchaseToken,
                orderId: p.orderId,
                payload: p.payload,
                packageName: p.packageName,
                purchaseTime: DateTime.fromMillisecondsSinceEpoch(p.purchaseTime),
              ))
          .toList();
    } else if (market == IranIAPMarket.myket) {
      final response = await MyketIAP.queryInventory(querySkuDetails: true);
      final result = response[MyketIAP.RESULT] as IabResult;
      final inventory = response[MyketIAP.INVENTORY] as Inventory;

      if (!result.isSuccess()) {
        throw Exception('Myket Query failed: ${result.mMessage}');
      }
      return inventory.mPurchaseMap.values
          .map((p) => IranIAPPurchase(
                productId: p.mSku,
                purchaseToken: p.mToken,
                orderId: p.mOrderId,
                payload: p.mDeveloperPayload,
                packageName: p.mPackageName,
                purchaseTime: DateTime.fromMillisecondsSinceEpoch(p.mPurchaseTime),
              ))
          .toList();
    } else {
      return [];
    }
  }

  /// Subscription support (Bazaar only).
  static Future<List<IranIAPPurchase>> querySubscriptions() async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    if (currentMarket == IranIAPMarket.bazaar) {
      final subs = await FlutterPoolakey.getAllSubscribedProducts();
      return subs
          .map((p) => IranIAPPurchase(
                productId: p.productId,
                purchaseToken: p.purchaseToken,
                orderId: p.orderId,
                payload: p.payload,
                packageName: p.packageName,
                purchaseTime: DateTime.fromMillisecondsSinceEpoch(p.purchaseTime),
              ))
          .toList();
    }
    return [];
  }

  /// Disconnects and cleans up resources.
  static Future<void> dispose() async {
    final market = currentMarket;
    if (market == IranIAPMarket.bazaar) {
      await FlutterPoolakey.disconnect();
    } else if (market == IranIAPMarket.myket) {
      await MyketIAP.dispose();
    }
    _isInitialized = false;
  }
}
