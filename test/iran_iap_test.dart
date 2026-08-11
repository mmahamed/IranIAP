import 'package:flutter_test/flutter_test.dart';
import 'package:iran_iap/iran_iap.dart';
import 'package:iran_iap/iran_iap_platform_interface.dart';
import 'package:iran_iap/iran_iap_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIranIapPlatform
    with MockPlatformInterfaceMixin
    implements IranIapPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IranIapPlatform initialPlatform = IranIapPlatform.instance;

  test('$MethodChannelIranIap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIranIap>());
  });

  test('getPlatformVersion', () async {
    IranIAP iranIapPlugin = IranIAP();
    MockIranIapPlatform fakePlatform = MockIranIapPlatform();
    IranIapPlatform.instance = fakePlatform;

    expect(await iranIapPlugin.getPlatformVersion(), '42');
  });
}
