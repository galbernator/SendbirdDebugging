//
//  ChatRow.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import SwiftUI

struct ChatRow: View {
    @ObservedObject var viewModel: ChatRowViewModel

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
                .frame(width: 64, height: 64)

            VStack(spacing: 2) {
                HStack {
                    Text(viewModel.title)
                        .foregroundStyle(Color.black)

                    Spacer()

                    Text(viewModel.messageTime)
                        .font(.caption)
                        .foregroundStyle(Color.black.opacity(0.8))
                }
                .padding(.top, 4)

                HStack {
                    Text(viewModel.message)
                        .foregroundStyle(Color.black)
                        .lineLimit(2)

                    Spacer()

                    Circle()
                        .stroke(notificationColor, lineWidth: 8)
                        .frame(width: 11, height: 11)
                        .foregroundColor(.systemBackground)
                        .padding(.leading, 24)
                }
                .frame(height: 44, alignment: .topLeading)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.systemBackground.opacity(0.001)) // To make empty space tappable
        .padding(.horizontal)
    }

    var notificationColor: Color {
        viewModel.hasUnreadMessage ? Color.orange : .systemBackground
    }
}

//#Preview {
//    ChatRow(viewModel: ChatRowViewModel())
//}
