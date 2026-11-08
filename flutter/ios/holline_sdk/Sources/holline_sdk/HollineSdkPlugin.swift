import Flutter
import UIKit

public final class HollineSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "holline_sdk", binaryMessenger: registrar.messenger())
        let instance = HollineSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        Task { @MainActor in
            Holline.onPhaseChanged = { phase in channel.invokeMethod("onPhase", arguments: phase) }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task { @MainActor in
            switch call.method {
            case "open":
                let args = call.arguments as? [String: Any] ?? [:]
                if let base = args["baseUrl"] as? String, let url = URL(string: base) {
                    Holline.baseURL = url
                }
                Holline.open(
                    company: args["company"] as? String ?? "",
                    name: args["name"] as? String,
                    phone: args["phone"] as? String,
                    source: args["source"] as? String ?? "mobile_app"
                )
                result(nil)
            case "isInCall":
                result(Holline.isInCall)
            case "joinMeeting", "isMeetingLink":
                let args = call.arguments as? [String: Any] ?? [:]
                if let base = args["baseUrl"] as? String, let url = URL(string: base) {
                    Holline.baseURL = url
                }
                let link = args["link"] as? String ?? ""
                if call.method == "isMeetingLink" {
                    result(Holline.isMeetingLink(link))
                } else {
                    result(Holline.joinMeeting(link, name: args["name"] as? String))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
