import 'dart:async';

import 'package:flutter/services.dart';
import 'Contact.dart';

class FlutterCallPlugin {
  static const MethodChannel _channel = const MethodChannel('plugins.flutter.io/flutter_call_plugin');

  // initialize
  static Future<bool> initialize(config, void Function(MethodCall) callback) async {
    _channel.setMethodCallHandler(callback);

    return await _channel.invokeMethod("initialize", config);
  }

  /// Make a call
  static Future<String> makeCall(dynamic handle) async {
    Contact contact;

    if (handle is String) {
      contact = Contact.fromJson({"handle": handle});
    } else {
      contact = handle;
    }

    return await _channel.invokeMethod('makeCall', contact.toJson());
  }

  /// End a call with uuid
  static Future<void> endCall(dynamic uuid) async {
    if (uuid is Contact) {
      uuid = uuid.uuid;
    }

    return await _channel.invokeMethod('endCall', uuid);
  }

  /// Test an incoming call
  static Future<dynamic> reportIncomingCall(dynamic handle) async {
    Contact contact;

    if (handle is String) {
      contact = Contact.fromJson({"handle": handle});
    } else {
      contact = handle;
    }

    return await _channel.invokeMethod('reportIncomingCall', contact.toJson());
  }

}
