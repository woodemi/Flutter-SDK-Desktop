import 'package:flutter/services.dart';

class AgoraRtcEngine {
  static const MethodChannel _channel = const MethodChannel('agora_rtc_engine');

  // Core Methods
  /// Creates an RtcEngine instance.
  ///
  /// The Agora SDK only supports one RtcEngine instance at a time, therefore the app should create one RtcEngine object only.
  /// Only users with the same App ID can join the same channel and call each other.
  static Future<void> create(String appid) async {
    await _channel.invokeMethod('create', {'appId': appid});
  }
}