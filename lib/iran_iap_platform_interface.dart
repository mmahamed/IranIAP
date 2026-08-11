import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iran_iap_method_channel.dart';

abstract class IranIapPlatform extends PlatformInterface {
  /// Constructs a IranIapPlatform.
  IranIapPlatform() : super(token: _token);

  static final Object _token = Object();

  static IranIapPlatform _instance = MethodChannelIranIap();

  /// The default instance of [IranIapPlatform] to use.
  ///
  /// Defaults to [MethodChannelIranIap].
  static IranIapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IranIapPlatform] when
  /// they register themselves.
  static set instance(IranIapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
