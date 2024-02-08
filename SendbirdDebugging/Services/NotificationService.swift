//
//  NotificationService.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Combine
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    let coachChatNotificationSubject = CurrentValueSubject<Bool, Never>(false)
    let memberSupportChatNotificationSubject = CurrentValueSubject<Bool, Never>(false)
    let markChannelAsRead = PassthroughSubject<ChatType, Never>()

    func chatReceived(ofType type: ChatType) {
        switch type {
        case .coach: coachChatNotificationSubject.send(true)
        case .memberSupport: memberSupportChatNotificationSubject.send(true)
        }
    }
}
