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
    
    private var allMessages: [ChatMessage] = []
    var chatMessages: [UUID: [ChatMessage]] = [:]
    
    init() {
        observeNetworkChanges()
        
        // Handle received messages
        WebSocketManager.shared.onMessageReceived = { [weak self] text in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let botMessage = ChatMessage(message: text, isUser: false, timestamp: Date())
                self.allMessages.append(botMessage)
                
                if let selectedId = self.selectedChatId {
                    self.chatMessages[selectedId, default: []].append(botMessage)
                    self.messages = self.chatMessages[selectedId] ?? []
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
        updateChatPreviews()
        return newChatId
    }
    
    func selectChat(_ chatId: UUID) {
        selectedChatId = chatId
        messages = chatMessages[chatId] ?? []
        updateChatPreviews()
    }
    
    func sendMessage(_ text: String) {
        guard let chatId = selectedChatId, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(message: text, isUser: true, timestamp: Date())
        allMessages.append(userMessage)
        chatMessages[chatId, default: []].append(userMessage)
        messages = chatMessages[chatId] ?? []
        
        WebSocketManager.shared.send(message: text)
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
            }
        }
    }

    func startMonitoringNetwork() {
        NetworkMonitor.shared.start()
    }
}
