//
//  IndividualChatView.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import SwiftUI

struct IndividualChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    let chatId: UUID
    
    var body: some View {
        VStack {
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.chatMessages[chatId] ?? []) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!viewModel.isConnected)
                
                Button(action: {
                    viewModel.sendMessage(viewModel.inputText)
                    viewModel.inputText = ""
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(viewModel.isConnected ? .blue : .gray)
                }
                .disabled(!viewModel.isConnected || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationBarTitle("Chat", displayMode: .inline)
        .onAppear {
            viewModel.selectChat(chatId)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.message)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationView {
        IndividualChatView(viewModel: ChatViewModel(), chatId: UUID())
    }
} 