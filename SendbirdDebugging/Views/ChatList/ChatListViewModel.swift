//
//  ChatListViewModel.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Combine
import Foundation

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var isLoading = true

    @Published var coachChannel: EphemeralChatChannel?
    @Published var memberSupportChannel: EphemeralChatChannel?
    @Published var selectedChatType: ChatType?

    let errorMessage = CurrentValueSubject<String?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }


    private func setupSubscriptions() {
        ChatService.shared.coachChatChannel
            .receive(on: RunLoop.main)
            .assign(to: &$coachChannel)

        ChatService.shared.memberSupportChatChannel
            .receive(on: RunLoop.main)
            .assign(to: &$memberSupportChannel)

        ChatService.shared.errorMessage
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.errorMessage.value = $0 }
            .store(in: &cancellables)

        Publishers.CombineLatest($coachChannel, $memberSupportChannel)
            .receive(on: RunLoop.main)
            .map { $0 == nil && $1 == nil }
            .assign(to: &$isLoading)
    }
}
