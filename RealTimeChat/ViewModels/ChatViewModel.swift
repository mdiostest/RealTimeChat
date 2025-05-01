//
//  ChatViewModel.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation
import Combine
import UIKit

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var chatPreviews: [ChatPreview] = []
    @Published var isConnected: Bool = true
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var inputText = ""
    @Published var selectedChatId: UUID?
    private var offlineMessageQueue: [ChatMessage] = []
    
    private var allMessages: [ChatMessage] = []
    var chatMessages: [UUID: [ChatMessage]] = [:]
    
    init() {
        observeNetworkChanges()
        
        // Handle received messages
        WebSocketManager.shared.onMessageReceived = { [weak self] text in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let botMessage = ChatMessage(message: text, isUser: false, timestamp: Date())
                
                // Find the last user message and its chat
                if let lastUserMessage = self.allMessages.last(where: { $0.isUser }) {
                    for (chatId, messages) in self.chatMessages {
                        if messages.contains(where: { $0.id == lastUserMessage.id }) {
                            // Add bot message to the correct chat
                            self.chatMessages[chatId, default: []].append(botMessage)
                            // Only update the messages array if this is the selected chat
                            if chatId == self.selectedChatId {
                                self.messages = self.chatMessages[chatId] ?? []
                            }
                            break
                        }
                    }
                }
                self.updateChatPreviews()
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
        
        // Clear chats when app is closed
        NotificationCenter.default.addObserver(self, selector: #selector(clearChats), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func clearChats() {
        allMessages.removeAll()
        messages.removeAll()
        chatPreviews.removeAll()
        chatMessages.removeAll()
        selectedChatId = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func createNewChat() -> UUID {
        let newChatId = UUID()
        chatMessages[newChatId] = []
        selectedChatId = newChatId
        // Clear the current messages when creating a new chat
        messages = []
        updateChatPreviews()
        return newChatId
    }
    
    func selectChat(_ chatId: UUID) {
        selectedChatId = chatId
        // Only update messages for the selected chat
        messages = chatMessages[chatId] ?? []
        // Mark messages as read when selecting a chat
        if var chatMessages = chatMessages[chatId] {
            for i in 0..<chatMessages.count {
                chatMessages[i].read = true
            }
            self.chatMessages[chatId] = chatMessages
        }
        updateChatPreviews()
    }
    
//    func sendMessage(_ text: String) {
//        guard let chatId = selectedChatId, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
//        
//        let userMessage = ChatMessage(message: text, isUser: true, timestamp: Date())
//        // Add to both allMessages and the specific chat
//        allMessages.append(userMessage)
//        chatMessages[chatId, default: []].append(userMessage)
//        // Only update messages for the current chat
//        if chatId == selectedChatId {
//            messages = chatMessages[chatId] ?? []
//        }
//        
//        // Store the current chat ID before sending the message
//        let currentChatId = chatId
//        WebSocketManager.shared.send(message: text) { [weak self] success in
//            if !success {
//                // If message sending fails, remove it from both collections
//                DispatchQueue.main.async {
//                    if let index = self?.chatMessages[currentChatId]?.firstIndex(where: { $0.id == userMessage.id }) {
//                        self?.chatMessages[currentChatId]?.remove(at: index)
//                        if currentChatId == self?.selectedChatId {
//                            self?.messages = self?.chatMessages[currentChatId] ?? []
//                        }
//                        // Also remove from allMessages
//                        if let allIndex = self?.allMessages.firstIndex(where: { $0.id == userMessage.id }) {
//                            self?.allMessages.remove(at: allIndex)
//                        }
//                        self?.updateChatPreviews()
//                    }
//                }
//            }
//        }
//        updateChatPreviews()
//    }
//    
    
    // In ChatViewModel.swift
    func sendMessage(_ text: String) {
        guard let chatId = selectedChatId, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(message: text, isUser: true, timestamp: Date(), status: .sending)
        
        // Add to both allMessages and the specific chat
        allMessages.append(userMessage)
        chatMessages[chatId, default: []].append(userMessage)
        messages = chatMessages[chatId] ?? []
        
        if isConnected {
            WebSocketManager.shared.send(message: text) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Update the message status
                    if let index = self.messages.firstIndex(where: { $0.id == userMessage.id }) {
                        self.messages[index].status = success ? .sent : .failed
                        self.chatMessages[chatId]?[index].status = success ? .sent : .failed
                    }
                    
                    if !success {
                        self.queueOfflineMessage(userMessage)
                    }
                }
            }
        } else {
            queueOfflineMessage(userMessage)
        }
        
        updateChatPreviews()
    }

    func updateChatPreviews() {
        var previews: [ChatPreview] = []
        
        for (chatId, messages) in chatMessages {
            let previewMessage = messages.last?.message ?? "No messages"
            let preview = ChatPreview(
                id: chatId,
                userName: "Chat \(chatId.uuidString.prefix(4))",
                lastMessage: previewMessage,
                timestamp: messages.last?.timestamp ?? Date(),
                hasUnreadMessages: messages.contains { !$0.read }
            )
            previews.append(preview)
        }
        
        self.chatPreviews = previews.sorted { $0.timestamp > $1.timestamp }
    }
    
    
    func observeNetworkChanges() {
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.isConnected = isConnected
                if isConnected {
                    self?.retryOfflineMessages()
                }
            }
        }
    }

  
    
    func queueOfflineMessage(_ message: ChatMessage) {
        guard let chatId = selectedChatId else { return }
        
        // Add to both the offline queue and display immediately
        offlineMessageQueue.append(message)
        chatMessages[chatId, default: []].append(message)
        messages = chatMessages[chatId] ?? []
        updateChatPreviews()
    }

    func retryOfflineMessages() {
        guard isConnected, !offlineMessageQueue.isEmpty else { return }
        
        for message in offlineMessageQueue {
            sendMessage(message.message)
        }
    }
    
    func startMonitoringNetwork() {
        NetworkMonitor.shared.start()
    }
    
}
