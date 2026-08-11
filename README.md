# Iran IAP 🇮🇷

A Flutter plugin that provides a unified API for **in-app purchases** on **CafeBazaar** and **Myket**.

[![pub package](https://img.shields.io/pub/v/iran_iap.svg)](https://pub.dev/packages/iran_iap)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 📖 Overview

CafeBazaar and Myket are two of the most widely used Android app stores in Iran. Many Flutter developers want to publish their applications on both stores and support in-app purchases on each platform.

However, using the official IAP libraries of both stores in the same Android project can lead to **dependency conflicts**, especially because both libraries include different Billing dependencies.

**Iran IAP** was created to make this process easier.

The plugin provides a unified Flutter API over the existing CafeBazaar and Myket IAP libraries and uses **Android Product Flavors** to isolate the dependencies of each store.

This allows you to maintain a single Flutter codebase while building separate versions of your application for CafeBazaar and Myket. 🚀

## ✨ Features

* ✅ Unified API for CafeBazaar and Myket
* ✅ In-app purchases
* ✅ Query purchased products
* ✅ Consume purchased products
* ✅ Subscription support for CafeBazaar
* ✅ Automatic market detection based on the active Flutter flavor
* ✅ Separate Android dependencies using Product Flavors
* ✅ A single `IranIAPPurchase` model for both stores
* ✅ Support for payloads
* ✅ Support for Bazaar dynamic price tokens

## 🏪 Supported Markets

| Market     | In-App Purchase | Subscriptions |
| ---------- | --------------- | ------------- |
| CafeBazaar | ✅               | ✅             |
| Myket      | ✅               | ❌             |

> **Note:** Subscription support is currently available for CafeBazaar only.

---

# 📦 Installation

Add `iran_iap` to your `pubspec.yaml`:

```yaml
dependencies:
  iran_iap: ^VERSION
```

Then run:

```bash
flutter pub get
```

Replace `VERSION` with the latest version available on pub.dev.

---

# ⚠️ Important: Product Flavors

`Iran IAP` uses **Android Product Flavors** to separate CafeBazaar and Myket dependencies.

Your project **must** have the following two flavors:

```text
bazaar
myket
```

The names must be exactly `bazaar` and `myket`.

The plugin uses the active Flutter flavor to determine which market is currently being used. `IranIAP.currentMarket` returns `bazaar`, `myket`, or `unknown` based on `appFlavor`.

---

# ⚙️ Android Configuration

After adding the package, configure the Android Product Flavors.

Open:

```text
android/app/build.gradle.kts
```

If your project uses Groovy instead:

```text
android/app/build.gradle
```

## 1. Configure Product Flavors

### Kotlin DSL — `build.gradle.kts`

Add the following **inside the `android { ... }` block**:

```kotlin
android {

    // Other Android configurations...

    flavorDimensions += "market"

    productFlavors {
        create("bazaar") {
            dimension = "market"
        }

        create("myket") {
            dimension = "market"

            manifestPlaceholders += mapOf(
                "marketApplicationId" to "ir.mservices.market",
                "marketBindAddress" to "ir.mservices.market.InAppBillingService.BIND",
                "marketPermission" to "ir.mservices.market.BILLING"
            )
        }
    }
}
```

### Groovy — `build.gradle`

If you are using Groovy:

```groovy
android {

    // Other Android configurations...

    flavorDimensions "market"

    productFlavors {
        bazaar {
            dimension "market"
        }

        myket {
            dimension "market"

            manifestPlaceholders = [
                marketApplicationId: "ir.mservices.market",
                marketBindAddress: "ir.mservices.market.InAppBillingService.BIND",
                marketPermission: "ir.mservices.market.BILLING"
            ]
        }
    }
}
```

---

# 🔧 Resolve Dependency Conflicts

Because CafeBazaar and Myket use different Billing libraries, you also need to exclude the dependency belonging to the other market.

Add the following configuration **outside the `android { ... }` block** in:

```text
android/app/build.gradle.kts
```

### Kotlin DSL

```kotlin
configurations.configureEach {
    when {
        name.startsWith("bazaar") -> {
            exclude(
                group = "com.github.myketstore",
                module = "myket-billing-client"
            )
        }

        name.startsWith("myket") -> {
            exclude(
                group = "com.github.cafebazaar.Poolakey",
                module = "poolakey"
            )
        }
    }
}
```

Your file should therefore have a structure similar to:

```kotlin
android {
    // Android configuration...

    flavorDimensions += "market"

    productFlavors {
        create("bazaar") {
            dimension = "market"
        }

        create("myket") {
            dimension = "market"

            manifestPlaceholders += mapOf(
                "marketApplicationId" to "ir.mservices.market",
                "marketBindAddress" to "ir.mservices.market.InAppBillingService.BIND",
                "marketPermission" to "ir.mservices.market.BILLING"
            )
        }
    }
}

configurations.configureEach {
    when {
        name.startsWith("bazaar") -> {
            exclude(
                group = "com.github.myketstore",
                module = "myket-billing-client"
            )
        }

        name.startsWith("myket") -> {
            exclude(
                group = "com.github.cafebazaar.Poolakey",
                module = "poolakey"
            )
        }
    }
}
```

If you are using Groovy, add the following **outside the `android { ... }` block**:

```groovy
configurations.configureEach {
        when {
        name.startsWith("bazaar") -> {
            exclude(
                group = "com.github.myketstore",
                module = "myket-billing-client"
            )
        }
        name.startsWith("myket") -> {
            exclude(
                group = "com.github.cafebazaar.Poolakey",
                module = "poolakey"
            )
        }
    }
}
```
> **Important:** `productFlavors` belongs inside `android {}`, while `configurations.configureEach` must be placed outside it.

---

# 🔑 Initialize Iran IAP

Before making purchases or querying products, initialize the IAP service.

You need to provide the **RSA key for each market**.

```dart
import 'package:iran_iap/iran_iap.dart';

Future<void> initializeIAP() async {
  await IranIAP.initialize(
    bazaarKey: 'YOUR_BAZAAR_RSA_KEY',
    myketKey: 'YOUR_MYKET_RSA_KEY',
    onDisconnected: () {
      print('IAP service disconnected');
    },
    onFailed: (error) {
      print('IAP initialization failed: $error');
    },
  );
}
```

Only the key corresponding to the active flavor is required. The plugin automatically detects whether the application was built with `bazaar` or `myket`.

For example, when running the `bazaar` flavor, the Bazaar RSA key is used. When running the `myket` flavor, the Myket RSA key is used.

You can also check the current market:

```dart
final market = IranIAP.currentMarket;

print(market);
```

Possible values:

```dart
IranIAPMarket.bazaar
IranIAPMarket.myket
IranIAPMarket.unknown
```

---

# 💳 Purchase a Product

Use `IranIAP.purchase()` to start an in-app purchase.

```dart
Future<void> purchaseProduct() async {
  final purchase = await IranIAP.purchase(
    'premium_product',
    payload: 'user_123',
    onError: (error) {
      print('Purchase failed: $error');
    },
  );

  if (purchase != null) {
    print('Purchase successful!');
    print('Product ID: ${purchase.productId}');
    print('Purchase Token: ${purchase.purchaseToken}');
    print('Order ID: ${purchase.orderId}');
  }
}
```

The method returns an `IranIAPPurchase` object containing common purchase information such as:

* `productId`
* `purchaseToken`
* `orderId`
* `payload`
* `packageName`
* `purchaseTime`

The plugin converts the native purchase response from both stores into this common model.

---

# 🏷️ Bazaar Dynamic Pricing

For CafeBazaar, you can optionally provide a dynamic price token:

```dart
final purchase = await IranIAP.purchase(
  'premium_product',
  payload: 'user_123',
  bazaarDynamicPriceToken: 'YOUR_DYNAMIC_PRICE_TOKEN',
);
```

The `bazaarDynamicPriceToken` is passed to the Bazaar purchase API and is ignored for Myket.

---

# 🔄 Query Purchased Products

You can retrieve all purchased products using:

```dart
Future<void> loadPurchases() async {
  final purchases = await IranIAP.queryPurchases(
    onError: (error) {
      print('Failed to query purchases: $error');
    },
  );

  for (final purchase in purchases) {
    print('Product: ${purchase.productId}');
    print('Token: ${purchase.purchaseToken}');
  }
}
```

This API works with both Bazaar and Myket and returns a unified `List<IranIAPPurchase>`.

A common use case is restoring a user's purchases after reinstalling the application or signing in on another device.

---

# 🗑️ Consume a Purchase

Consumable products can be consumed after the purchase has been successfully processed.

```dart
final success = await IranIAP.consume(
  purchaseToken,
  null,
  onError: (error) {
    print('Failed to consume purchase: $error');
  },
);

if (success) {
  print('Purchase consumed successfully');
}
```

The parameters differ slightly between the two stores:

* **Bazaar:** pass the `purchaseToken`
* **Myket:** pass the native Myket `Purchase` object

The current API therefore accepts both:

```dart
IranIAP.consume(
  String? bazaarPurchaseToken,
  Purchase? myketPurchaseObject,
)
```

and internally calls the appropriate store API based on the active flavor.

> **Note:** Because the current API exposes the Myket native `Purchase` type, Myket consumption requires access to the corresponding Myket purchase object.

---

# 📅 Query Subscriptions

Subscriptions are currently supported for **CafeBazaar only**.

```dart
Future<void> loadSubscriptions() async {
  final subscriptions = await IranIAP.querySubscriptions(
    onError: (error) {
      print('Failed to query subscriptions: $error');
    },
  );

  for (final subscription in subscriptions) {
    print('Subscription: ${subscription.productId}');
    print('Token: ${subscription.purchaseToken}');
  }
}
```

For the `myket` flavor, calling this method currently results in an exception because Myket subscription support is not implemented in the plugin.

---

# 🧹 Dispose

When the IAP service is no longer needed, you can release its resources:

```dart
await IranIAP.dispose(
  onError: (error) {
    print('Failed to dispose IAP: $error');
  },
);
```

The plugin disconnects from the appropriate service based on the active market.

---

# 🏗️ Build for Each Market

After configuring the flavors, you can build a version for each store.

### CafeBazaar

```bash
flutter build apk --flavor bazaar --release
```

Or:

```bash
flutter build appbundle --flavor bazaar --release
```

### Myket

```bash
flutter build apk --flavor myket --release
```

Or:

```bash
flutter build appbundle --flavor myket --release
```

The selected flavor determines which IAP implementation is used at runtime.

---

# 🧩 Complete Example

A simple purchase flow can look like this:

```dart
import 'package:flutter/material.dart';
import 'package:iran_iap/iran_iap.dart';

class IAPExample extends StatefulWidget {
  const IAPExample({super.key});

  @override
  State<IAPExample> createState() => _IAPExampleState();
}

class _IAPExampleState extends State<IAPExample> {
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    initializeIAP();
  }

  Future<void> initializeIAP() async {
    await IranIAP.initialize(
      bazaarKey: 'YOUR_BAZAAR_RSA_KEY',
      myketKey: 'YOUR_MYKET_RSA_KEY',
      onFailed: (error) {
        debugPrint('IAP error: $error');
      },
      onDisconnected: () {
        debugPrint('IAP disconnected');
      },
    );

    if (mounted) {
      setState(() {
        initialized = IranIAP.isInitialized;
      });
    }
  }

  Future<void> buyPremium() async {
    if (!IranIAP.isInitialized) return;

    final purchase = await IranIAP.purchase(
      'premium_product',
      payload: 'user_123',
      onError: (error) {
        debugPrint('Purchase error: $error');
      },
    );

    if (purchase == null) return;

    debugPrint('Purchase successful');
    debugPrint('Product: ${purchase.productId}');
    debugPrint('Token: ${purchase.purchaseToken}');
    debugPrint('Order: ${purchase.orderId}');
  }

  Future<void> restorePurchases() async {
    final purchases = await IranIAP.queryPurchases();

    for (final purchase in purchases) {
      debugPrint('Purchased: ${purchase.productId}');
    }
  }

  @override
  void dispose() {
    IranIAP.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: initialized ? buyPremium : null,
          child: const Text('Buy Premium'),
        ),
        ElevatedButton(
          onPressed: initialized ? restorePurchases : null,
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }
}
```

---

# 🔐 RSA Keys

Both markets require their own RSA key during initialization.

```dart
await IranIAP.initialize(
  bazaarKey: 'YOUR_BAZAAR_RSA_KEY',
  myketKey: 'YOUR_MYKET_RSA_KEY',
);
```

You should obtain these keys from the developer console of the corresponding market.

Do not hard-code sensitive server-side credentials or private keys in your application.

---

# 📋 API Reference

| API                    | Bazaar | Myket |
| ---------------------- | :----: | :---: |
| `initialize()`         |    ✅   |   ✅   |
| `purchase()`           |    ✅   |   ✅   |
| `queryPurchases()`     |    ✅   |   ✅   |
| `consume()`            |    ✅   |   ✅   |
| `querySubscriptions()` |    ✅   |   ❌   |
| `dispose()`            |    ✅   |   ✅   |
| Dynamic price token    |    ✅   |   —   |

---

# ⚠️ Important Notes

### Flavor names are required

The following names must be used exactly:

```text
bazaar
myket
```

Do not rename them.

### Product Flavors are required

The plugin determines the current market using the Flutter `appFlavor`. If no supported flavor is detected, the market will be `unknown`.

### Initialize before using IAP

Call `IranIAP.initialize()` before calling:

* `purchase()`
* `consume()`
* `queryPurchases()`
* `querySubscriptions()`

The plugin checks its initialization state before performing these operations.

### Subscription support

Subscription querying is currently implemented for Bazaar only. Myket subscription support is not currently available in this plugin.

---

# 🤝 Contributing

Contributions, bug reports, feature requests, and pull requests are welcome.

If you find a bug or have an idea that could improve the plugin, please open an issue or submit a pull request.

---

# 📄 License

This project is licensed under the **MIT License**.

See the [LICENSE](LICENSE) file for details.
