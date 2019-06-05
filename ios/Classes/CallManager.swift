import Foundation
import CallKit
import AVFoundation

/**
 * Class to manage call operations
 */
class CallManager: NSObject {
    
    private let callController: CXCallController = CXCallController()
    private let provider: CXProvider
    
    // plugin
    private var plugin: SwiftFlutterCallPlugin?
    
    override init() {
        // CXProviderConfiguration
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic, .phoneNumber, .emailAddress]
        
        // CXProvider
        provider = CXProvider(configuration: providerConfiguration)
        
        // init parent
        super.init()
        
        // set delegate
        provider.setDelegate(self, queue: nil)
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
        let endCallAction = CXEndCallAction(call: uuid);
        callController.request(CXTransaction(action: endCallAction)) { error in
            completion?(error);
        };
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
