//
//  ChatListCoordinator.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import SwiftUI

@MainActor
final class ChatListCoordinator {
    let viewModel: ChatListViewModel

    init(viewModel: ChatListViewModel) {
        self.viewModel = viewModel
    }

    enum Event {
        case channelTapped(ChatType)
    }

    func send(_ event: Event) {
        switch event {
        case .channelTapped(let type):
            viewModel.selectedChatType = type
        }
    }

    func row(for channel: EphemeralChatChannel) -> some View {
        let rowViewModel = ChatRowViewModel(channel: channel)
        return ChatRow(viewModel: rowViewModel)
    }

    @ViewBuilder func chat() -> some View {
        if let selectedChatType = viewModel.selectedChatType {
            Text("SELECTED CHAT: \(selectedChatType.name)")
        } else {
            EmptyView()
        }
    }
}

extension ChatListCoordinator {
    func start() -> some View {
        ChatListView(coordinator: self, viewModel: viewModel)
    }
}
