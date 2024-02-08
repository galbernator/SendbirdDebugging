//
//  ChatMessage.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Foundation
import SendbirdChatSDK

enum ChatType: String, Decodable, CaseIterable {
    case coach
    case memberSupport = "member_support"

    var channelURL: String {
        switch self {
        case .coach: return Secrets.get(.coachChannelURL)
        case .memberSupport: return Secrets.get(.memberSupportChannelURL)
        }
    }

    var iconName: String {
        switch self {
        case .coach: return "flag.checkered.circle"
        case .memberSupport: return "questionmark.circle.fill"
        }
    }

    var name: String {
        switch self {
        case .coach: return "Coach"
        case .memberSupport: return "Member Support"
        }
    }
}

struct ChatMessage: Identifiable {
    let text: String
    let createdAt: Int64
    let channelURL: String
    var messageId: Int64
    let senderUserId: String? // senderUserId is `nil` for admin messages
    var file: ChatFile?

    var id: Int64 {
        createdAt + messageId
    }

    init(baseMessage: BaseMessage) {
        text = baseMessage.message
        createdAt = baseMessage.createdAt
        channelURL = baseMessage.channelURL
        messageId = baseMessage.messageId
        senderUserId = baseMessage.sender?.userId

        if let fileMessage = baseMessage as? FileMessage {
            let chatFile = ChatFile(name: fileMessage.name, urlString: fileMessage.url)
            file = chatFile
        }
    }

    var relativeTimeString: String {
        createdAt.relativeTimeString
    }

    var isFile: Bool {
        file != nil
    }

    var isNotEmpty: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension ChatMessage {
    init(
        text: String,
        createdAt: Int64,
        channelURL: String,
        messageId: Int64,
        senderUserId: String? = nil,
        file: ChatFile? = nil
    ) {
        self.text = text
        self.createdAt = createdAt
        self.channelURL = channelURL
        self.messageId = messageId
        self.senderUserId = senderUserId
        self.file = file
    }
}

fileprivate extension Int64 {
    var relativeTimeString: String {
        let timeInterval = TimeInterval(Double(self) / 1000.0)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mma"
        return dateFormatter.string(from: date)
    }

    var date: Date {
        let timeInterval = TimeInterval(Double(self) / 1000.0)
        return Date(timeIntervalSince1970: timeInterval)
    }
}
