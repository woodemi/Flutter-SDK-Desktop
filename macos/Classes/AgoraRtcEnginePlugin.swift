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
    let params = call.arguments as! Dictionary<String, Any>
    print("plugin handleMethodCall: \(method), args: \(params)")

    switch method {
    case "create":
      let appId = params["appId"] as! String
      agoraRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension AgoraRtcEnginePlugin: AgoraRtcEngineDelegate {

}