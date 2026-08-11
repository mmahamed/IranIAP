
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:myket_iap/myket_iap.dart';
import 'package:myket_iap/util/iab_result.dart';
import 'package:myket_iap/util/inventory.dart';
import 'package:myket_iap/util/purchase.dart';

import 'iran_iap_platform_interface.dart';

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
  Future<String?> getPlatformVersion() {
    return IranIapPlatform.instance.getPlatformVersion();
  }

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
      try {
        if (bazaarKey == null) throw ArgumentError('Bazaar RSA Key is required for Bazaar flavor');

        final completer = Completer<void>();

        await FlutterPoolakey.connect(
          bazaarKey,
          onSucceed: () {
            debugPrint('IranIap: Connected to Bazaar successfully');
            _isInitialized = true;
            if (!completer.isCompleted) completer.complete();
          },
          onFailed: () {
            debugPrint('IranIap: Failed to connect to Bazaar');
            _isInitialized = false;
            onFailed?.call('Failed to connect to Bazaar');
            if (!completer.isCompleted) completer.completeError('Failed to connect to Bazaar');
          },
          onDisconnected: () {
            debugPrint('IranIap: Disconnected from Bazaar service');
            _isInitialized = false;
            onDisconnected?.call();
          },
        );

        return completer.future;
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        onFailed?.call(e.toString());
      }
    } else if (market == IranIAPMarket.myket) {
      try {
        if (myketKey == null) throw ArgumentError('Myket RSA Key is required for Myket flavor');

        final result = await MyketIAP.init(
          rsaKey: myketKey,
          enableDebugLogging: kDebugMode,
        );

        if (result?.isSuccess() ?? false) {
          debugPrint('IranIap: Myket IAP initialized successfully: ${result?.mMessage}');
          _isInitialized = true;
        } else {
          debugPrint('IranIap: Myket IAP Setup failed: ${result?.mMessage}');
          _isInitialized = false;
          onFailed?.call(result?.mMessage ?? '');
        }
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        onFailed?.call(e.toString());
      }
    } else {
      throw Exception('Unsupported market');
    }
  }

  /// Initiates a purchase for the given [productId].
  static Future<IranIAPPurchase?> purchase(String productId,
      {String payload = '', String bazaarDynamicPriceToken = '', void Function(String error)? onError}) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;

    if (market == IranIAPMarket.bazaar) {
      try {
        final purchaseInfo =
        await FlutterPoolakey.purchase(productId, payload: payload, dynamicPriceToken: bazaarDynamicPriceToken);
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
        onError?.call(e.toString());
        return null;
      }
    } else if (market == IranIAPMarket.myket) {
      try {
        final response = await MyketIAP.launchPurchaseFlow(sku: productId, payload: payload);
        final result = response[MyketIAP.RESULT] as IabResult;
        if (result.isFailure()) {
          onError?.call(result.mMessage);
          return null;
        }
        final purchase = response[MyketIAP.PURCHASE] as Purchase;
        return IranIAPPurchase(
          productId: purchase.mSku,
          purchaseToken: purchase.mToken,
          orderId: purchase.mOrderId,
          payload: purchase.mDeveloperPayload,
          packageName: purchase.mPackageName,
          purchaseTime: DateTime.fromMillisecondsSinceEpoch(purchase.mPurchaseTime),
        );
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        onError?.call(e.toString());
        return null;
      }
    } else {
      throw Exception('Unsupported market');
    }
  }

  /// Consumes a purchase given the [purchaseToken].
  static Future<bool> consume(String? bazaarPurchaseToken, Purchase? myketPurchaseObject,
      {void Function(String error)? onError}) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;
    if (market == IranIAPMarket.bazaar && bazaarPurchaseToken == null) {
      onError?.call('purchaseToken is required');
      return false;
    }
    if (market == IranIAPMarket.myket && myketPurchaseObject == null) {
      onError?.call('purchase object is required');
      return false;
    }

    try {
      if (market == IranIAPMarket.bazaar) {
        return await FlutterPoolakey.consume(bazaarPurchaseToken!);
      } else if (market == IranIAPMarket.myket) {
        final response = await MyketIAP.consume(purchase: myketPurchaseObject!);
        final result = response[MyketIAP.RESULT] as IabResult;
        // final purchase = response[MyketIAP.PURCHASE] as Purchase;
        if (result.isFailure()) {
          onError?.call(result.mMessage);
          return false;
        }
        return true;
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      onError?.call(e.toString());
    }
    return false;
  }

  /// Queries all owned (purchased) items.
  static Future<List<IranIAPPurchase>> queryPurchases({void Function(String error)? onError}) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    final market = currentMarket;

    try {
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
        if (result.isFailure()) {
          onError?.call(result.mMessage);
          return [];
        }

        final inventory = response[MyketIAP.INVENTORY] as Inventory;
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
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      onError?.call(e.toString());
    }
    return [];
  }

  /// Subscription support (Bazaar only).
  static Future<List<IranIAPPurchase>> querySubscriptions({void Function(String error)? onError}) async {
    if (!_isInitialized) throw Exception('IranIap is not initialized');

    if (currentMarket == IranIAPMarket.bazaar) {
      try {
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
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        onError?.call(e.toString());
        return [];
      }
    } else {
      throw Exception('Myket currently does not support subscription.');
    }
  }

  /// Disconnects and cleans up resources.
  static Future<void> dispose({void Function(String error)? onError}) async {
    final market = currentMarket;
    try {
      if (market == IranIAPMarket.bazaar) {
        await FlutterPoolakey.disconnect();
      } else if (market == IranIAPMarket.myket) {
        await MyketIAP.dispose();
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      onError?.call(e.toString());
    } finally {
      _isInitialized = false;
    }
  }

}
