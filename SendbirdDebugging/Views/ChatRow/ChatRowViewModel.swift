//
//  ChatRowViewModel.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Combine
import Foundation

@MainActor
final class ChatRowViewModel: ObservableObject {
    private let channel: EphemeralChatChannel
    private let notificationSubject: CurrentValueSubject<Bool, Never>
    private var cancellables = Set<AnyCancellable>()

    var imageName: String {
        channel.chatType.iconName
    }

    @Published var hasUnreadMessage = false
    @Published var message = "No messages yet"
    @Published var messageTime = ""
    @Published var title = ""

    init(channel: EphemeralChatChannel) {
        self.channel = channel

        switch channel.chatType {
        case .coach:
            self.notificationSubject = NotificationService.shared.coachChatNotificationSubject
        case .memberSupport:
            self.notificationSubject = NotificationService.shared.memberSupportChatNotificationSubject
        }

        self.title = channel.recepientName

        if let message = channel.sendbirdGroupChannel.lastMessage {
            self.message = message.message
            self.messageTime = "\(message.createdAt)"
        }

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        notificationSubject
            .receive(on: RunLoop.main)
            .assign(to: &$hasUnreadMessage)

        channel.messagesSubject
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        print("Failed to load chat messages: \(error)")
                    default:
                        break
                    }
                },
                receiveValue: { [weak self] messages in
                    guard let self = self else { return }

                    if let message = messages.last {
                        if message.isFile {
                            self.message = "1 Attachment"
                        } else {
                            self.message = message.text
                        }

                        self.messageTime = "\(message.createdAt)"
                    }
                }
            )
            .store(in: &cancellables)
    }
}
