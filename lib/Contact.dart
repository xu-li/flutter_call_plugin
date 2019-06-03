//
//  Contact.swift
//  flutter_call_plugin
//
//  Created by Xu Li on 2019/6/3.
//

enum ContactType { GENERIC, PHONE_NUMBER, EMAIL_ADDRESS }

class Contact {
  String uuid;
  String handle;
  ContactType type;
  String identifier;

  Contact({
    this.uuid,
    this.handle,
    this.type,
    this.identifier,
  });

  factory Contact.fromJson(Map<String, String> json) {
    ContactType type = ContactType.GENERIC;

    if (json.containsKey("type")) {
      switch (json['type']) {
        case "GENERIC":
          type = ContactType.GENERIC;
          break;

        case "PHONE_NUMBER":
          type = ContactType.PHONE_NUMBER;
          break;

        case "EMAIL_ADDRESS":
          type = ContactType.EMAIL_ADDRESS;
          break;
      }
    }

    return Contact(
      uuid: json.containsKey("uuid") ? json["uuid"] : "",
      handle: json.containsKey("handle") ? json["handle"] : "",
      type: type,
      identifier: json.containsKey("identifier") ? json["identifier"] : "",
    );
  }

  Map<String, String> toJson() {
    String type = "";

    switch (this.type) {
      case ContactType.GENERIC:
        type = "GENERIC";
        break;

      case ContactType.PHONE_NUMBER:
        type = "PHONE_NUMBER";
        break;

      case ContactType.EMAIL_ADDRESS:
        type = "EMAIL_ADDRESS";
        break;

      default:
        type = "GENERIC";
    }

    return {
      'uuid': uuid,
      'handle': handle,
      'type': type,
      'identifier': identifier,
    };
  }
}
