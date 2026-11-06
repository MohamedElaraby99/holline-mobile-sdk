import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holline_sdk/holline_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('holline_sdk');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'isInCall' ? true : null;
    });
  });

  test('open sends the arguments and the default source', () async {
    await Holline.open(company: 'acme', phone: '010');
    expect(calls.single.method, 'open');
    expect(calls.single.arguments, {
      'company': 'acme',
      'name': null,
      'phone': '010',
      'source': 'mobile_app',
      'baseUrl': null,
    });
  });

  test('isInCall reads the native state', () async {
    expect(await Holline.isInCall, isTrue);
  });

  test('phases streams what the native side reports', () async {
    final next = Holline.phases.first;
    await Future<void>.delayed(Duration.zero);
    await messenger.handlePlatformMessage(
      'holline_sdk',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('onPhase', 'ringing')),
      (_) {},
    );
    expect(await next, 'ringing');
  });
}
