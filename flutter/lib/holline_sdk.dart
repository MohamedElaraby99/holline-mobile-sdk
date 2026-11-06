import 'dart:async';

import 'package:flutter/services.dart';

/// Opens a company's Holline call screen inside the host app.
class Holline {
  Holline._();

  static const MethodChannel _channel = MethodChannel('holline_sdk');
  static final StreamController<String> _phases = StreamController<String>.broadcast(onListen: _listen);

  static void _listen() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPhase') _phases.add(call.arguments as String);
    });
  }

  /// The call's progress: flow, form, ringing, connected, ended, missed, callback,
  /// moved, mic-error.
  static Stream<String> get phases => _phases.stream;

  /// True while a call is ringing or connected, even if the call screen is hidden.
  static Future<bool> get isInCall async => await _channel.invokeMethod<bool>('isInCall') ?? false;

  /// Opens the call screen, or brings back the one that's already open. A call in
  /// progress is never replaced, even when the arguments differ.
  ///
  /// [company] is the slug from the company's Holline call link. [name] and [phone]
  /// fill in the form, and [source] shows as the call's source in analytics.
  static Future<void> open({
    required String company,
    String? name,
    String? phone,
    String source = 'mobile_app',
    String? baseUrl,
  }) {
    return _channel.invokeMethod<void>('open', <String, String?>{
      'company': company,
      'name': name,
      'phone': phone,
      'source': source,
      'baseUrl': baseUrl,
    });
  }
}
