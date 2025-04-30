//
//  WebSocketManager.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation
import Combine

class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    
    @Published var isConnected = false
    var onMessageReceived: ((String) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    private var messageQueue: [String] = []
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard let url = URL(string: "wss://echo.websocket.org") else { return }
        webSocketTask = urlSession.webSocketTask(with: url)
        
        // Start the connection
        webSocketTask?.resume()
        
        // Listen for messages
        listenForMessages()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        onConnectionStatusChanged?(false)
    }
    
    func send(message: String) {
        if isConnected {
            let messageToSend = URLSessionWebSocketTask.Message.string(message)
            webSocketTask?.send(messageToSend) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                    self.messageQueue.append(message)
                }
            }
        } else {
            messageQueue.append(message)
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.disconnect()
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.onMessageReceived?(text)
                default:
                    break
                }
                
                // Continue listening for new messages
                self?.listenForMessages()
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 Attempting to reconnect WebSocket...")
            self.connect()
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                     didOpenWithProtocol protocol: String?) {
        print("WebSocket connected ✅")
        isConnected = true
        onConnectionStatusChanged?(true)
        
        // Retry any queued messages
        for msg in messageQueue {
            send(message: msg)
        }
        messageQueue.removeAll()
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                     didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("WebSocket disconnected. Close code: \(closeCode), Reason: \(reasonString)")
        } else {
            print("WebSocket disconnected with code: \(closeCode)")
        }
        
        isConnected = false
        onConnectionStatusChanged?(false)
        
        // Attempt to reconnect after a delay
        scheduleReconnect()
    }
}
