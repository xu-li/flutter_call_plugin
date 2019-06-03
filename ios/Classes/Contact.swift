//
//  Contact.swift
//  flutter_call_plugin
//
//  Created by Xu Li on 2019/6/3.
//

import Foundation
import CallKit

@available(iOS 10.0, *)
class Contact {
    let uuid: UUID
    let handle: String
    let type: CXHandle.HandleType
    let identifier: String

    init(uuid: UUID, handle: String, type:CXHandle.HandleType = .generic, identifier: String = "") {
        self.uuid = uuid
        self.handle = handle
        self.type = type
        self.identifier = identifier
    }
    
    init(contact: [String: String]) {
        if let uuid = contact["uuid"] {
            self.uuid = UUID(uuidString: uuid) ?? UUID()
        } else {
            self.uuid = UUID()
        }
        
        if let handle = contact["handle"] {
            self.handle = handle
        } else {
            self.handle = ""
        }
        
        if let type = contact["type"] {
            if type == "GENERIC" {
                self.type = .generic
            } else if type == "PHONE_NUMBER" {
                self.type = .phoneNumber
            } else if type == "EMAIL_ADDRESS" {
                self.type = .emailAddress
            } else {
                self.type = .generic
            }
        } else {
            self.type = .generic
        }
        
        if let identifier = contact["identifier"] {
            self.identifier = identifier
        } else {
            self.identifier = ""
        }
    }
}
