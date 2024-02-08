//
//  SendbirdDebuggingApp.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import SwiftUI

@main
struct SendbirdDebuggingApp: App {
    var body: some Scene {
        WindowGroup {
            let viewModel = ChatListViewModel()
            let coordinator = ChatListCoordinator(viewModel: viewModel)

            coordinator.start()
        }
    }
}
