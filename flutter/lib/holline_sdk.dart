import 'dart:async';

import 'package:flutter/services.dart';

/// Opens a company's Holline call screen, or one of its meetings, inside the host app.
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
  /// moved, mic-error. A meeting reports meeting-ready, meeting-lobby,
  /// meeting-joined, meeting-left, meeting-ended, meeting-removed, meeting-denied,
  /// meeting-full and meeting-missing.
  static Stream<String> get phases => _phases.stream;

  /// True while a call is ringing or connected, or a meeting is joined, even if the screen is hidden.
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

  /// Opens a Holline meeting from its [link] (https://holline.cloud/m/abcd-efgh-ijkl,
  /// or /a/<company>/m/… when your app opens your company's links) or its bare code.
  /// [name] fills in the person's name so they only tap to join. Returns false when
  /// [link] isn't a Holline meeting link. A meeting in progress is never replaced.
  static Future<bool> joinMeeting(String link, {String? name, String? baseUrl}) async {
    return await _channel.invokeMethod<bool>('joinMeeting', <String, String?>{
          'link': link,
          'name': name,
          'baseUrl': baseUrl,
        }) ??
        false;
  }

  /// Whether [link] is a Holline meeting link, for routing links your app receives.
  static Future<bool> isMeetingLink(String link, {String? baseUrl}) async {
    return await _channel.invokeMethod<bool>('isMeetingLink', <String, String?>{'link': link, 'baseUrl': baseUrl}) ?? false;
  }
}
