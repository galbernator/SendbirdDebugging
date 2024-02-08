//
//  ChatService.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Combine
import Foundation
import SendbirdChatSDK

final class ChatService {
    static let shared = ChatService()

    // MARK: - Publishers

    let chatMessageSubject = PassthroughSubject<ChatMessage, Never>()
    let coachChatChannel = CurrentValueSubject<EphemeralChatChannel?, Never>(nil)
    let memberSupportChatChannel = CurrentValueSubject<EphemeralChatChannel?, Never>(nil)
    let errorMessage = PassthroughSubject<String, Never>()

    // MARK: - Initalizer

    // This is private so that we are forced to use the shared instance
    private init() {
        let sendbirdParams = InitParams(
            applicationId: Secrets.get(.sendbirdAppId),
            isLocalCachingEnabled: false,
            logLevel: .info
         )

        SendbirdChat.initialize(params: sendbirdParams)

        SendbirdChat.setSessionDelegate(self)
        SendbirdChat.addConnectionDelegate(self, identifier: "connectionDelegate")
        SendbirdChat.addChannelDelegate(self, identifier: "channelDelegate")

        connectWithSendbirdAndBuildChannels()
    }

    private func connectWithSendbirdAndBuildChannels() {
        Task {
            connect()
            await buildChatChannels()
        }
    }

    // Handles connecting to Sendbird for the user id specified in the `SendbirdConfig` file
    private func connect() {
        let userId = Secrets.get(.userId)
        let accessToken = Secrets.get(.sessionToken)
        SendbirdChat.connect(userId: userId, authToken: accessToken) { _, error in
            if error == nil {
                print("Connection successful #sendbird")
            } else {
                print("Connection failed #sendbird")
            }
        }
    }

    /// Loops over the different chat types and then, once the channel is created, assigns each to their correct property (`coachChatChannel` or `memberSupportChatChannel`).
    private func buildChatChannels() async {
        for chatType in ChatType.allCases {
            guard let newChannel = await buildChatChannel(for: chatType) else { continue }

            switch chatType {
            case .coach:
                guard coachChatChannel.value?.id != newChannel.id else { continue }

                DispatchQueue.main.async {
                    self.coachChatChannel.value = newChannel
                }
            case .memberSupport:
                guard memberSupportChatChannel.value?.id != newChannel.id else { continue }

                DispatchQueue.main.async {
                    self.memberSupportChatChannel.value = newChannel
                }
            }
        }
    }

    /// Returns the custom channel object used in the application (`EphemeralChatChannel`) if successfully retrieved from Sendbird
    private func buildChatChannel(for type: ChatType) async -> EphemeralChatChannel? {
        guard let channel = await getSendbirdGroupChannel(url: type.channelURL) else { return nil }

        let chatChannel = EphemeralChatChannel(
            type: type,
            sendbirdGroupChannel: channel,
            chatMessageSubject: chatMessageSubject
        )

        return chatChannel
    }

    // Fetches group channel at the specified URL string from Sendbird
    private func getSendbirdGroupChannel(url: String) async -> GroupChannel? {
        return await withCheckedContinuation { continuation in
            GroupChannel.getChannel(url: url) { [weak self] groupChannel, error in
                if let error = error {
                    let message = "Error fetching Sendbird channel at \(url): \(error.localizedDescription)"
                    // To help with debugging purposes, we are not failing gracefully here
                    fatalError(message)
                    // If you would prefer that the app did not crash, comment out the line above
                    self?.errorMessage.send(message)
                    return
                }

                continuation.resume(returning: groupChannel)
            }
        }
    }
}

// MARK: - Sendbird Session Delegate

extension ChatService: SessionDelegate {
    func sessionTokenDidRequire(successCompletion success: @escaping (String?) -> Void, failCompletion fail: @escaping () -> Void) {
        print("Sendbird Session Delegate - sessionTokenDidRequire")
    }
    
    func sessionWasClosed() {
        print("Sendbird Session Delegate - sessionWasClosed")
    }
}

// MARK: - Sendbird Connection Delegate

extension ChatService: ConnectionDelegate {
    func didStartReconnection() {
        print("Sendbird Connection Delegate - didStartReconnection")
    }

    func didSucceedReconnection() {
        print("Sendbird Connection Delegate - didSucceedReconnection")
    }

    func didFailReconnection() {
        print("Sendbird Connection Delegate - didFailReconnection")
    }

    func didConnect(userId: String) {
        print("Sendbird Connection Delegate - didConnect - userId: \(userId)")
    }

    func didDisconnect(userId: String) {
        print("Sendbird Connection Delegate - didDisconnect - userId: \(userId)")
    }
}

// MARK: - Sendbird Group Channel Delegate

extension ChatService: GroupChannelDelegate {
    func channel(_ channel: BaseChannel, didReceive message: BaseMessage) {
        let chatMessage = ChatMessage(baseMessage: message)
        chatMessageSubject.send(chatMessage)
    }
}

