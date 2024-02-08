//
//  ChatChannel.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Foundation

struct ChatChannel: Decodable {
    let id: String
    let externalId: String
    let chatType: ChatType
    let url: String

    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case chatType = "chat_type"
        case url
    }
}
