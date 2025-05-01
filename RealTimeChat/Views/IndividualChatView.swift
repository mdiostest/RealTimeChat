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
//                    .disabled(!viewModel.isConnected)
                
                Button(action: {
                    if viewModel.isConnected {
                        viewModel.sendMessage(viewModel.inputText)
                        viewModel.inputText = ""
                    } else {
                        // Queue the message offline
                        let offlineMessage = ChatMessage(message: viewModel.inputText, isUser: true, timestamp: Date())
                        viewModel.queueOfflineMessage(offlineMessage)
                        viewModel.inputText = ""
                    }
                }){
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(viewModel.isConnected ? .blue : .gray)
                }
//                .disabled(!viewModel.isConnected || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    
    var statusIcon: some View {
        Group {
            if message.isUser {
                switch message.status {
                case .sending: Image(systemName: "clock")
                case .sent: Image(systemName: "checkmark")
                case .delivered: Image(systemName: "checkmark.2")
                case .failed: Image(systemName: "exclamationmark")
                }
            }
        }
        .font(.caption)
        .foregroundColor(message.status == .failed ? .red : .gray)
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                statusIcon
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
