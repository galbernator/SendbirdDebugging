//
//  ChatListView.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import SwiftUI

struct ChatListView: View {
    let coordinator: ChatListCoordinator
    @ObservedObject var viewModel: ChatListViewModel
    @State private var hasAlert = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Messages")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.bottom, 24)
                        .padding(.leading)
                        .offset(y: 12)

                    Spacer()
                }
                .background(Color.blue.opacity(0.3))

                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        listView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onReceive(viewModel.errorMessage) {
                hasAlert = $0 != nil
            }
            .alert(isPresented: $hasAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage.value ?? "")
                )
            }
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Care Team")
                    .fontWeight(.bold)
                    .padding([.leading, .top])

                Spacer()
            }

            if let coachChannel = viewModel.coachChannel {
                VStack(spacing: 0) {
                    coordinator.row(for: coachChannel)
                        .padding(.vertical)
                        .onTapGesture {
                            coordinator.send(.channelTapped(.coach))
                        }

                    NavigationLink(
                        destination: coordinator.chat(),
                        tag: .coach,
                        selection: $viewModel.selectedChatType,
                        label: { EmptyView() }
                    )
                    .isDetailLink(false)
                }
            }

            if let memberSupportChannel = viewModel.memberSupportChannel {
                HStack {
                    Text("Account and scheduling")
                        .fontWeight(.bold)
                        .padding([.leading, .top])

                    Spacer()
                }

                coordinator.row(for: memberSupportChannel)
                    .padding(.vertical)
                    .onTapGesture {
                        coordinator.send(.channelTapped(.memberSupport))
                    }

                NavigationLink(
                    destination: coordinator.chat(),
                    tag: .memberSupport,
                    selection: $viewModel.selectedChatType,
                    label: { EmptyView() }
                )
                .isDetailLink(false)
            }
        }
    }
}

#Preview {
    let viewModel = ChatListViewModel()
    let coordinator = ChatListCoordinator(viewModel: viewModel)

    return coordinator.start()
}
