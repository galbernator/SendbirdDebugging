//
//  Secrets.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Foundation

enum Secrets {
    enum Key: String {
        case userId = "USER_ID"
        case sendbirdAppId = "SENDBIRD_APPLICATION_ID"
        case sessionToken = "SESSION_TOKEN"
        case coachChannelURL = "COACH_CHAT_CHANNEL_URL"
        case memberSupportChannelURL = "MEMBER_SUPPORT_CHAT_CHANNEL_URL"
    }

    static func get(_ key: Key) -> String {
        guard let value = Bundle.main.infoDictionary?[key.rawValue] as? String else { fatalError(for: key) }

        return value
    }

    private static func fatalError(for key: Key) -> Never {
        Swift.fatalError("Unable to find secret key for \(key.rawValue). Please make sure you have a SendbirdConfig file set up and that it is set up correctly.")
    }
}
