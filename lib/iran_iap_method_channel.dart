import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iran_iap_platform_interface.dart';

/// An implementation of [IranIapPlatform] that uses method channels.
class MethodChannelIranIap extends IranIapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('iran_iap');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
