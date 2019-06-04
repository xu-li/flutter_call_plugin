import Foundation
import CallKit

/**
 * Class to manage call operations
 */
class CallManager: NSObject {
    
    private let callController: CXCallController = CXCallController()
    private let provider: CXProvider
    
    // plugin
    private var plugin: SwiftFlutterCallPlugin?
    
    private var currentCallUUID: UUID?
    
    override init() {
        // CXProviderConfiguration
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
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
    
    
    func setRingtone(ringtone: String) {
        provider.configuration.ringtoneSound = ringtone
    }
    
    func makeCall(_ contact: Contact, completion: ((UUID, Error?) -> Void)? = nil) {
        let startCallAction = CXStartCallAction(
            call: contact.uuid,
            handle: CXHandle(type: contact.type, value: contact.handle)
        );
        
        startCallAction.contactIdentifier = contact.identifier;
        startCallAction.isVideo = false;
        
        callController.request(CXTransaction(action: startCallAction)) { error in
            completion?(contact.uuid, error);
        };
    }
    
    func endCall(uuid: UUID, completion: ((Error?) -> Void)? = nil) {
        let endCallAction = CXEndCallAction(call: uuid);
        callController.request(CXTransaction(action: endCallAction)) { error in
            completion?(error);
        };
    }
    
    func reportIncomingCall(_ contact: Contact, completion: ((NSError?) -> Void)?) {
        // prepare update to send to system
        let update = CXCallUpdate()
        // add call metadata
        update.remoteHandle = CXHandle(type: contact.type, value: contact.handle)
        update.hasVideo = false
        
        // use provider to notify system
        provider.reportNewIncomingCall(with: contact.uuid, update: update) { error in
            completion?(error as NSError?)
        }
    }
    
    func setPlugin(_ plugin: SwiftFlutterCallPlugin) {
        self.plugin = plugin
    }
    
}

extension CallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        plugin?.invokeMethod("onCXProviderDelegate", arguments: [
            "action": "providerDidReset"
        ]);
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        action.fulfill()
        
        currentCallUUID = action.callUUID
        
        plugin?.invokeMethod("onCXProviderDelegate", arguments: [
            "action": "StartCall",
            "uuid": action.callUUID.uuidString
        ]);
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
        
        currentCallUUID = nil
        
        plugin?.invokeMethod("onCXProviderDelegate", arguments: [
            "action": "EndCall",
            "uuid": action.callUUID.uuidString
        ]);
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        
        plugin?.invokeMethod("onCXProviderDelegate", arguments: [
            "action": "AnswerCall",
            "uuid": action.callUUID.uuidString
        ]);
    }

}
