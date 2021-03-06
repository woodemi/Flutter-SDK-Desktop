import Cocoa
import FlutterMacOS
import AgoraRtcEngineKit

public class AgoraRtcEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = AgoraRtcEnginePlugin()

    let channel = FlutterMethodChannel(name: "agora_rtc_engine", binaryMessenger: registrar.messenger)
    plugin.messageChannel = FlutterBasicMessageChannel(name: "agora_rtc_engine_message_channel", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  private var agoraRtcEngine: AgoraRtcEngineKit?

  private var messageChannel: FlutterBasicMessageChannel!

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    let params = call.arguments as? Dictionary<String, Any>
    print("plugin handleMethodCall: \(method), args: \(String(describing: params))")

    switch method {
    case "requestAVPermissions":
      if #available(OSX 10.14, *) {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
          result(true)
        } else {
          AVCaptureDevice.requestAccess(for: .audio) {
            result($0)
          }
        }
      } else {
        result(true)
      }
    case "create":
      let appId = params?["appId"] as! String
      agoraRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
      result(nil)
    case "destroy":
      agoraRtcEngine = nil
      AgoraRtcEngineKit.destroy()
      result(nil)
    case "setChannelProfile":
      let profile = params?["profile"] as! Int
      agoraRtcEngine?.setChannelProfile(AgoraChannelProfile(rawValue: profile)!)
      result(nil)
    case "joinChannel":
      let token = params?["token"] as? String
      let channelId = params?["channelId"] as! String
      let info = params?["info"] as? String
      let uid = params?["uid"] as! Int
      agoraRtcEngine?.joinChannel(byToken: token, channelId: channelId, info: info, uid: numericCast(uid), joinSuccess: nil)
      result(true)
    case "leaveChannel":
      let success = agoraRtcEngine?.leaveChannel() == 0
      result(success)
    case "muteLocalAudioStream":
      let muted = params?["muted"] as! Bool
      agoraRtcEngine?.muteLocalAudioStream(muted)
      result(nil)
    case "muteAllRemoteAudioStreams":
      let muted = params?["muted"] as! Bool
      agoraRtcEngine?.muteAllRemoteAudioStreams(muted)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func sendEvent(_ name: String, params: Dictionary<String, Any>) {
    var p = params
    p["event"] = name
    messageChannel.sendMessage(p)
  }
}

extension AgoraRtcEnginePlugin: AgoraRtcEngineDelegate {
  public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    sendEvent("onJoinChannelSuccess", params: ["channel": channel, "uid": uid, "elapsed": elapsed])
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    sendEvent("onLeaveChannel", params: ["stats": stats.toDictionary()])
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    sendEvent("onUserJoined", params: ["uid": uid, "elapsed": elapsed])
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    sendEvent("onUserOffline", params: ["uid": uid, "reason": reason.rawValue])
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
    sendEvent("onRtcStats", params: ["stats": stats.toDictionary()])
  }

  public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStats stats: AgoraRtcRemoteAudioStats) {
    sendEvent("onRemoteAudioStats", params: [
      "stats": [
        "uid": stats.uid,
        "quality": stats.quality,
        "networkTransportDelay": stats.networkTransportDelay,
        "jitterBufferDelay": stats.jitterBufferDelay,
        "audioLossRate": stats.audioLossRate,
        "numChannels": stats.numChannels,
        "receivedSampleRate": stats.receivedSampleRate,
        "receivedBitrate": stats.receivedBitrate,
        "totalFrozenTime": stats.totalFrozenTime,
        "frozenRate": stats.frozenRate,
      ]
    ])
  }
}

extension AgoraChannelStats {
  func toDictionary() -> [String: Any] {
    [
      "totalDuration": duration,
      "txBytes": txBytes,
      "rxBytes": rxBytes,
      "txAudioBytes": txAudioBytes,
      "txVideoBytes": txVideoBytes,
      "rxAudioBytes": rxAudioBytes,
      "rxVideoBytes": rxVideoBytes,
      "txKBitrate": txKBitrate,
      "rxKBitrate": rxKBitrate,
      "txAudioKBitrate": txAudioKBitrate,
      "rxAudioKBitrate": rxAudioKBitrate,
      "txVideoKBitrate": txVideoKBitrate,
      "rxVideoKBitrate": rxVideoKBitrate,
      "lastmileDelay": lastmileDelay,
      "txPacketLossRate": txPacketLossRate,
      "rxPacketLossRate": rxPacketLossRate,
      "users": userCount,
      "cpuAppUsage": cpuAppUsage,
      "cpuTotalUsage": cpuTotalUsage,
    ]
  }
}