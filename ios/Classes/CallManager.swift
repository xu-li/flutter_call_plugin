import Foundation
import CallKit
import AVFoundation

/**
 * Class to manage call operations
 */
class CallManager: NSObject {
    
    public let provider: CXProvider
    private let callController: CXCallController = CXCallController()
    
    // plugin
    private var plugin: SwiftFlutterCallPlugin?
    
    override init() {
        // CXProvider
        provider = CXProvider(configuration: CallManager.buildConfiguration([:], with: nil))
        
        // init parent
        super.init()
        
        // set delegate
        provider.setDelegate(self, queue: nil)
    }
    
    static func buildConfiguration(_ config:[String: String], with registrar: FlutterPluginRegistrar?) -> CXProviderConfiguration {
        var configuration: CXProviderConfiguration
        
        // check appName
        if let appName = config["appName"] {
            configuration = CXProviderConfiguration(localizedName: appName)
        } else {
            let defaultName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            configuration = CXProviderConfiguration(localizedName: defaultName)
        }
        
        // check ringtone
        if let ringtone = config["ringtone"] {
            configuration.ringtoneSound = registrar?.lookupKey(forAsset: ringtone)
        }
        
        // check icon
        if let icon = config["icon"] {
            let key = registrar?.lookupKey(forAsset: icon)
            if let path = Bundle.main.path(forResource: key, ofType: ""), let iconImage = UIImage(contentsOfFile: path) {
                configuration.iconTemplateImageData = UIImagePNGRepresentation(iconImage)
            }
        }
        
        // defaults
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic, .phoneNumber, .emailAddress]
        
        return configuration
    }
    
    /**
     Make a call
     */
    func makeCall(_ contact: Contact, video: Bool = false, completion: ((UUID, Error?) -> Void)? = nil) {
        let startCallAction = CXStartCallAction(
            call: contact.uuid,
            handle: CXHandle(type: contact.type, value: contact.handle)
        );
        
        startCallAction.contactIdentifier = contact.identifier;
        startCallAction.isVideo = video;
        
        callController.request(CXTransaction(action: startCallAction)) { error in
            completion?(contact.uuid, error);
        };
    }
    
    /**
     End a call
    */
    func endCall(uuid: UUID, completion: ((Error?) -> Void)? = nil) {
        let endCallAction = CXEndCallAction(call: uuid)
        callController.request(CXTransaction(action: endCallAction)) { error in
            completion?(error);
        }
    }
    
    /**
     Report a incoming call
    */
    func reportIncomingCall(_ contact: Contact, video: Bool = false, completion: ((NSError?) -> Void)?) {
        // prepare update to send to system
        let update = CXCallUpdate()
        // add call metadata
        update.remoteHandle = CXHandle(type: contact.type, value: contact.handle)
        update.hasVideo = video
        
        // use provider to notify system
        provider.reportNewIncomingCall(with: contact.uuid, update: update) { error in
            completion?(error as NSError?)
        }
    }
    
    /**
     Set plugin
    */
    func setPlugin(_ plugin: SwiftFlutterCallPlugin) {
        self.plugin = plugin
    }
}

extension CallManager: CXProviderDelegate {
    func providerDidBegin(_ provider: CXProvider) {
        plugin?.invokeMethod("onCallProviderBegan")
    }
    
    func providerDidReset(_ provider: CXProvider) {
        plugin?.invokeMethod("onCallProviderReset")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        plugin?.invokeMethod("onAudioSessionActivated")
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        plugin?.invokeMethod("onAudioSessionDeactivated")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        action.fulfill()
        
        plugin?.invokeMethod("onCallStarted", arguments: ["uuid": action.callUUID.uuidString])
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        
        plugin?.invokeMethod("onCallAnswered", arguments: ["uuid": action.callUUID.uuidString])
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
        
        plugin?.invokeMethod("onCallEnded", arguments: ["uuid": action.callUUID.uuidString])
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
        
        plugin?.invokeMethod("onCallTimedOut")
    }

}
