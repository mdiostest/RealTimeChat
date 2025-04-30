//
//  ChatViewModel.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var chatPreviews: [ChatPreview] = []
    @Published var isConnected: Bool = true
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private var allMessages: [ChatMessage] = []  // For storing all messages
    
    init() {
        observeNetworkChanges()
        
        // Handle received messages
        WebSocketManager.shared.onMessageReceived = { [weak self] text in
            DispatchQueue.main.async {
                let botMessage = ChatMessage(message: text, isUser: false, timestamp: Date())
                self?.allMessages.append(botMessage)
                self?.updateChatPreviews()
            }
        }
        
        // Handle socket connection status
        WebSocketManager.shared.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.isConnected = isConnected
                if !isConnected {
                    self?.alertMessage = "Disconnected from the server."
                    self?.showAlert = true
                }
            }
        }
        
        // Connect to the websocket server
        WebSocketManager.shared.connect()
    }
    
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(message: text, isUser: true, timestamp: Date())
        allMessages.append(userMessage)
        messages.append(userMessage)
        WebSocketManager.shared.send(message: text)
        updateChatPreviews()
    }

    func updateChatPreviews() {
        var previews: [ChatPreview] = []
        
        // Group messages by user (this can be adjusted as per your data structure)
        let groupedMessages = Dictionary(grouping: allMessages) { $0.isUser }
        
        // Create chat previews with the latest message and unread status
        for (isUser, messages) in groupedMessages {
            let latestMessage = messages.last!
            let preview = ChatPreview(userName: isUser ? "You" : "Bot",
                                      lastMessage: latestMessage.message,
                                      timestamp: latestMessage.timestamp,
                                      hasUnreadMessages: !latestMessage.read)
            previews.append(preview)
        }
        
        self.chatPreviews = previews
    }
    
    func observeNetworkChanges() {
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.isConnected = isConnected
            }
        }
    }

    func startMonitoringNetwork() {
        NetworkMonitor.shared.start()
    }
}
