import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'src/base.dart';

export 'src/base.dart';

class AgoraRtcEngine {
  static const MethodChannel _channel = const MethodChannel('agora_rtc_engine');

  // FIXME Windows `EventChannel` not implemented yet
  static final BasicMessageChannel _eventChannel = const BasicMessageChannel(
      'agora_rtc_engine_message_channel', StandardMessageCodec());

  static StreamSubscription<dynamic> _sink;

  static StreamController<dynamic> _sinkController =
      StreamController<dynamic>.broadcast();

  static void init() {
    _eventChannel.setMessageHandler((message) {
      _sinkController.add(message);
    });
  }

  /// Reports an error during SDK runtime.
  ///
  /// In most cases, the SDK cannot fix the issue and resume running. The SDK requires the app to take action or informs the user about the issue.
  static void Function(dynamic err) onError;

  /// Occurs when a user joins a specified channel.
  ///
  /// The channel name assignment is based on channelName specified in the [joinChannel] method.
  /// If the uid is not specified when [joinChannel] is called, the server automatically assigns a uid.
  static void Function(String channel, int uid, int elapsed)
      onJoinChannelSuccess;

  /// Occurs when a user leaves the channel.
  ///
  /// When the app calls the [leaveChannel] method, the SDK uses this callback to notify the app when the user leaves the channel.
  static VoidCallback onLeaveChannel;

  /// Occurs when a remote user (Communication)/host (Live Broadcast) joins the channel.
  ///
  /// Communication profile: This callback notifies the app when another user joins the channel. If other users are already in the channel, the SDK also reports to the app on the existing users.
  /// Live-broadcast profile: This callback notifies the app when the host joins the channel. If other hosts are already in the channel, the SDK also reports to the app on the existing hosts. Agora recommends having at most 17 hosts in a channel
  static void Function(int uid, int elapsed) onUserJoined;

  /// Occurs when a remote user (Communication)/host (Live Broadcast) leaves the channel.
  ///
  /// There are two reasons for users to become offline:
  /// 1. Leave the channel: When the user/host leaves the channel, the user/host sends a goodbye message. When this message is received, the SDK determines that the user/host leaves the channel.
  /// 2. Drop offline: When no data packet of the user or host is received for a certain period of time (20 seconds for the communication profile, and more for the live broadcast profile), the SDK assumes that the user/host drops offline. A poor network connection may lead to false detections, so Agora recommends using the signaling system for reliable offline detection.
  static void Function(int uid, int elapsed) onUserOffline;

  // Statistics Events
  /// Reports the statistics of the audio stream from each remote user/host.
  ///
  /// The SDK triggers this callback once every two seconds for each remote user/host. If a channel includes multiple remote users, the SDK triggers this callback as many times.
  static void Function(RemoteAudioStats stats) onRemoteAudioStats;

  /// Reports the statistics of the RtcEngine once every two seconds.
  static void Function(RtcStats stats) onRtcStats;

  // Core Methods
  /// Creates an RtcEngine instance.
  ///
  /// The Agora SDK only supports one RtcEngine instance at a time, therefore the app should create one RtcEngine object only.
  /// Only users with the same App ID can join the same channel and call each other.
  static Future<void> create(String appid) async {
    await _channel.invokeMethod('create', {'appId': appid});
    _addEventChannelHandler();
  }

  /// Destroys the RtcEngine instance and releases all resources used by the Agora SDK.
  ///
  /// This method is useful for apps that occasionally make voice or video calls, to free up resources for other operations when not making calls.
  /// Once the app calls destroy to destroy the created RtcEngine instance, you cannot use any method or callback in the SDK.
  static Future<void> destroy() async {
    await _removeEventChannelHandler();
    await _channel.invokeMethod('destroy');
  }

  /// Sets the channel profile.
  ///
  /// RtcEngine needs to know the application scenario to set the appropriate channel profile to apply different optimization methods.
  /// Users in the same channel must use the same channel profile.
  /// Before calling this method to set a new channel profile, [destroy] the current RtcEngine and [create] a new RtcEngine first.
  /// Call this method before [joinChannel], you cannot configure the channel profile when the channel is in use.
  static Future<void> setChannelProfile(ChannelProfile profile) async {
    await _channel
        .invokeMethod('setChannelProfile', {'profile': profile.index});
  }

  /// Allows a user to join a channel.
  ///
  /// Users in the same channel can talk to each other, and multiple users in the same channel can start a group chat. Users with different App IDs cannot call each other.
  /// You must call the [leaveChannel] method to exit the current call before joining another channel.
  /// A channel does not accept duplicate uids, such as two users with the same uid. If you set uid as 0, the system automatically assigns a uid.
  static Future<bool> joinChannel(String token, String channelId, String info, int uid) async {
    final bool success = await _channel.invokeMethod('joinChannel',
        {'token': token, 'channelId': channelId, 'info': info, 'uid': uid});
    return success;
  }

  /// Allows a user to leave a channel.
  ///
  /// If you call the [destroy] method immediately after calling this method, the leaveChannel process interrupts, and the SDK does not trigger the onLeaveChannel callback.
  static Future<bool> leaveChannel() async {
    final bool success = await _channel.invokeMethod('leaveChannel');
    return success;
  }

  /// Sends/Stops sending the local audio stream.
  ///
  /// When muted is set as true, this method does not disable the microphone and thus does not affect any ongoing recording.
  static Future<void> muteLocalAudioStream(bool muted) async {
    await _channel.invokeMethod('muteLocalAudioStream', {'muted': muted});
  }

  /// Receives/Stops receiving all remote audio streams.
  static Future<void> muteAllRemoteAudioStreams(bool muted) async {
    await _channel.invokeMethod('muteAllRemoteAudioStreams', {'muted': muted});
  }

  static void _addEventChannelHandler() async {
    _sink = _sinkController.stream.listen(_eventListener, onError: onError);
  }

  static void _removeEventChannelHandler() async {
    await _sink.cancel();
  }

  // CallHandler
  static void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onJoinChannelSuccess':
        if (onJoinChannelSuccess != null) {
          onJoinChannelSuccess(map['channel'], map['uid'], map['elapsed']);
        }
        break;
      case 'onLeaveChannel':
        if (onLeaveChannel != null) {
          onLeaveChannel();
        }
        break;
      case 'onUserJoined':
        if (onUserJoined != null) {
          onUserJoined(map['uid'], map['elapsed']);
        }
        break;
      case 'onUserOffline':
        if (onUserOffline != null) {
          onUserOffline(map['uid'], map['reason']);
        }
        break;
      case 'onRtcStats':
        if (onRtcStats != null) {
          RtcStats stats = RtcStats.fromJson(map['stats']);
          onRtcStats(stats);
        }
        break;
      case 'onRemoteAudioStats':
        if (onRemoteAudioStats != null) {
          RemoteAudioStats stats = RemoteAudioStats.fromJson(map['stats']);
          onRemoteAudioStats(stats);
        }
        break;
    }
  }
}