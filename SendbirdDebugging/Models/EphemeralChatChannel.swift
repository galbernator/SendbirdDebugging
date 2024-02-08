//
//  EphemeralChatChannel.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import AVKit
import Combine
import Foundation
import SendbirdChatSDK

class EphemeralChatChannel: ObservableObject {
    let sendbirdGroupChannel: GroupChannel
    private let chatMessageSubject: PassthroughSubject<ChatMessage, Never>
    private let sendbirdListQuery: PreviousMessageListQuery?
    private var cancellables = Set<AnyCancellable>()
    let uploadErrorSubject = PassthroughSubject<SBError, Never>()

    private(set) var messagesSubject = CurrentValueSubject<[ChatMessage], SBError>([])

    let chatType: ChatType

    var id: String {
        sendbirdGroupChannel.id
    }

    var recepientName: String {
        switch chatType {
        case .coach:
            return "Coach \(sendbirdGroupChannel.providerName)"
        case .memberSupport:
            return "Member Support"
        }
    }

    init(
        type: ChatType,
        sendbirdGroupChannel: GroupChannel,
        chatMessageSubject: PassthroughSubject<ChatMessage, Never>
    ) {
        self.chatType = type
        self.sendbirdGroupChannel = sendbirdGroupChannel
        self.chatMessageSubject = chatMessageSubject

        let queryParams = PreviousMessageListQueryParams()
        queryParams.limit = 20
        queryParams.reverse = false
        queryParams.includeMetaArray = false
        queryParams.includeReactions = false

        sendbirdListQuery = sendbirdGroupChannel.createPreviousMessageListQuery(params: queryParams)

        if sendbirdGroupChannel.unreadMessageCount > 0 {
            switch chatType {
            case .coach:
                NotificationService.shared.coachChatNotificationSubject.value = true
            case .memberSupport:
                NotificationService.shared.memberSupportChatNotificationSubject.value = true
            }
        }

        fetchChatMessages()
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        chatMessageSubject
            .receive(on: RunLoop.main)
            .filter { [weak self] in $0.channelURL == self?.sendbirdGroupChannel.channelURL }
            .sink { [weak self] chatMessage in
                guard let self = self else { return }
                var messages = self.messagesSubject.value
                messages.append(chatMessage)
                self.messagesSubject.value = messages
                NotificationService.shared.chatReceived(ofType: self.chatType)
            }
            .store(in: &cancellables)

        NotificationService.shared.markChannelAsRead
            .filter { [weak self] in
                guard let chatType = self?.chatType else { return false }
                return chatType == $0
            }
            .sink { [weak self] _ in
                self?.sendbirdGroupChannel.markAsRead { error in
                    if let error {
                        print("Messages not able to marked as read - Error: \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - API Calls

    func fetchChatMessages() {
        sendbirdListQuery?.loadNextPage { [weak self] sendbirdMessages, error in
            guard let self = self else { return }

            if let error = error {
                self.messagesSubject.send(completion: .failure(error))
                return
            }

            DispatchQueue.main.async {
                guard let sendbirdMessages = sendbirdMessages else { return }
                let chatMessages = sendbirdMessages.map { ChatMessage(baseMessage: $0) }
                var messages = self.messagesSubject.value
                // There is an odd bug where the first MS chat is duplicated, this removes that
                if messages.count == 1, !chatMessages.isEmpty {
                    if messages.first?.text == chatMessages.last?.text {
                        messages = []
                    }
                }
                messages.append(contentsOf: chatMessages)
                self.messagesSubject.value = messages
            }
        }
    }

    func sendMessage(text: String) {
        sendbirdGroupChannel.sendUserMessage(text) { [weak self] userMessage, error in
            guard let self = self else { return }

            guard error == nil, let userMessage = userMessage else {
                print("FILE UPLOAD FAILED WITH ERROR: \(error!)")
                self.uploadErrorSubject.send(error!)
                return
            }

            let chatMessage = ChatMessage(baseMessage: userMessage)
            var messages = self.messagesSubject.value
            messages.append(chatMessage)
            self.messagesSubject.value = messages
        }
    }
}

// MARK: - Hashable

extension EphemeralChatChannel: Hashable {
    static func == (lhs: EphemeralChatChannel, rhs: EphemeralChatChannel) -> Bool {
        lhs.sendbirdGroupChannel.channelURL == rhs.sendbirdGroupChannel.channelURL
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sendbirdGroupChannel.channelURL)
        hasher.combine(chatType.rawValue)
    }
}

fileprivate extension GroupChannel {
    var providerName: String {
        let member = members.first(
            where: { member in
                !member.isMuted && member.userId != Secrets.get(.userId)
            }
        )

        return member?.nickname ?? "Unknown"
    }
}
