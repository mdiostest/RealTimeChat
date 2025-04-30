//
//  ChatView.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            if !viewModel.isConnected {
                Text("⚠️ No Internet Connection")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            if viewModel.chatPreviews.isEmpty {
                Spacer()
                Text(viewModel.isConnected ? "No chats yet" : "No chats available")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
            } else {
                List(viewModel.chatPreviews) { preview in
                    HStack {
                        Text(preview.userName)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(preview.lastMessage)
                            .foregroundColor(.gray)
                        
                        if preview.hasUnreadMessages {
                            Text("●")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                    .padding()
                }
            }
            
            HStack {
                TextField("Enter message", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                    .disabled(!viewModel.isConnected)

                Button("Send") {
                    guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.sendMessage(inputText)
                    inputText = ""
                }
                .disabled(!viewModel.isConnected)
            }
            .padding()
        }
        .onAppear {
            viewModel.startMonitoringNetwork()
        }
    }
}

#Preview {
    ChatView()
}
