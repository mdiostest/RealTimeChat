//
//  ChatView.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingNewChat = false
    @StateObject private var webSocketManager = WebSocketManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if !webSocketManager.isConnected {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Connection Status")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 10)
                        
                        if let error = webSocketManager.connectionError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            webSocketManager.connect()
                        }) {
                            Text("Retry Connection")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.bottom, 10)
                    }
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected to \(webSocketManager.currentServer)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 10)
                }
                
                if viewModel.chatPreviews.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text(webSocketManager.isConnected ? "No chats yet" : "No chats available")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        if webSocketManager.isConnected {
                            Text("Tap + to start a new chat")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    Spacer()
                } else {
                    List(viewModel.chatPreviews) { preview in
                        NavigationLink(destination: IndividualChatView(viewModel: viewModel, chatId: preview.id)) {
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
                        .onAppear {
                            viewModel.selectChat(preview.id)
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        showingNewChat = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(!webSocketManager.isConnected)
                }
                .padding()
            }
            .navigationTitle("Chats")
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.startMonitoringNetwork()
                webSocketManager.connect()
            }
        }
    }
}

struct NewChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Start a new chat")
                    .font(.title)
                    .padding()
                
                Button(action: {
                    let newChatId = viewModel.createNewChat()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Chat")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    ChatView()
}
