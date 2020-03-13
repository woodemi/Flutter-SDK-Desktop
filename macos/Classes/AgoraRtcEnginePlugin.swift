import Cocoa
import FlutterMacOS
import AgoraRtcEngineKit

public class AgoraRtcEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = AgoraRtcEnginePlugin()

    let channel = FlutterMethodChannel(name: "agora_rtc_engine", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  private var agoraRtcEngine: AgoraRtcEngineKit?

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    let params = call.arguments as? Dictionary<String, Any>
    print("plugin handleMethodCall: \(method), args: \(String(describing: params))")

    switch method {
    case "create":
      let appId = params?["appId"] as! String
      agoraRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
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
}

extension AgoraRtcEnginePlugin: AgoraRtcEngineDelegate {

}