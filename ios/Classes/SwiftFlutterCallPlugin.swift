import Flutter
import UIKit
import CallKit
import PushKit
import AVFoundation

public class SwiftFlutterCallPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.flutter.io/flutter_call_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCallPlugin()
        instance.setChannel(channel)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    // CallManager instance
    private let callManager: CallManager
    
    // Whether it has been initialized or not
    private var initialized: Bool = false
    
    // The MethodChannel
    private var channel: FlutterMethodChannel?
    
    // Any pending calls
    private var pendingMethodCalls: [Dictionary<String, Any>] = []

    /**
     Init
    */
    public override init() {
        callManager = CallManager()
        
        super.init();
        
        callManager.setPlugin(self)
    }
    
    /**
     Main method to handle all the Flutter calls
    */
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call, result: result);
        case "makeCall":
            makeCall(call, result: result);
        case "endCall":
            endCall(call, result: result);
        case "reportIncomingCall":
            reportIncomingCall(call, result: result);
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /**
     Handle the flutter call "initialize"
    */
    func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if !initialized {
            initialized = true
            
            if pendingMethodCalls.count > 0 {
                for call in pendingMethodCalls {
                    invokeMethod(call["method"] as! String, arguments: call["arguments"])
                }
            }
        }
        
        result(true);
    }
    
    /**
     Handle the flutter call "makeCall"
     */
    func makeCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: String] {
            if args.keys.contains("handle") {
                let contact = Contact(contact: args)
                callManager.makeCall(contact) { (uuid, error) in
                    if error == nil {
                        result(uuid.uuidString);
                    } else {
                        result(FlutterError.init(code: "MAKE_CALL_FAILED", message: error?.localizedDescription, details: nil));
                    }
                };
            } else {
                result(FlutterError.init(code: "BAD_ARGS", message: "Wrong argument", details: nil));
            }
        } else {
            result(FlutterError.init(code: "BAD_ARGS", message: "Wrong argument type", details: nil))
        }
    }
    
    /**
     Handle the flutter call "endCall"
     */
    func endCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let uuidString = call.arguments as? String {
            let uuid = UUID(uuidString: uuidString);
            if uuid == nil {
                result(FlutterError.init(code: "END_CALL_FAILED", message: "Wrong UUID: " + uuidString, details: nil));
            } else {
                callManager.endCall(uuid: uuid!) { error in
                    if error == nil {
                        result(true);
                    } else {
                        result(FlutterError.init(code: "END_CALL_FAILED", message: error?.localizedDescription, details: nil));
                    }
                };
            }
        } else {
            result(FlutterError.init(code: "BAD_ARGS", message: "Wrong argument types", details: nil))
        }
    }
    
    /**
     Handle the flutter call "reportIncomingCall"
     */
    func reportIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: String] {
            if args.keys.contains("handle") {
                let contact = Contact(contact: args)
                callManager.reportIncomingCall(contact) { error in
                    if error == nil {
                        result(true);
                    } else {
                        result(FlutterError.init(code: "REPORT_INCOMING_CALL_FAILED", message: error?.localizedDescription, details: nil));
                    }
                }
            } else {
                result(FlutterError.init(code: "BAD_ARGS", message: "Wrong argument", details: nil));
            }
        } else {
            result(FlutterError.init(code: "BAD_ARGS", message: "Wrong argument type", details: nil))
        }
    }
    
    /**
     Set channel
    */
    func setChannel(_ channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    /**
     invokeMethod
     */
    public func invokeMethod(_ method: String, arguments: Any? = []) {
        if initialized {
            channel?.invokeMethod(method, arguments: arguments)
        } else {
            pendingMethodCalls.append([
                "method": method,
                "arguments": arguments ?? []
            ])
        }
    }
    
    /**
     ApplicationDelegate
     
     1. setup audio session
     2. setup push registry
     */
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        // setup audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeVoiceChat, options: [])
        } catch (let error) {
            print("Error while configuring audio session: \(error)")
        }
        
        // setup push registry
        let registry:PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        
        return true
    }
}


extension SwiftFlutterCallPlugin: PKPushRegistryDelegate {
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%.2hhx", $0) }.joined()
        invokeMethod("onPushRegistryCredentialsUpdated", arguments: ["token": token, "type": type.rawValue])
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        invokeMethod("onPushRegistryCredentialsUpdated", arguments: ["token": "", "type": type.rawValue])
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        invokeMethod("onPushRegistryPushReceived", arguments: ["payload": payload.dictionaryPayload, "type": type.rawValue])
    }
}
