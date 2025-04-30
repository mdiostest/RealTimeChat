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
    @Published var connectionError: String?
    @Published var currentServer: String = "Primary"
    
    var onMessageReceived: ((String) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    private var messageQueue: [String] = []
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5
    private var isUsingFallbackServer = false
    
    private let primaryServer = "wss://piehost.com/websocket-tester"
    private let fallbackServer = "wss://ws.postman-echo.com/raw"
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 10
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        connectToServer(isUsingFallbackServer ? fallbackServer : primaryServer)
    }
    
    private func connectToServer(_ serverURL: String) {
        guard let url = URL(string: serverURL) else {
            connectionError = "Invalid WebSocket URL"
            return
        }
        
        print("🔄 Attempting to connect to \(isUsingFallbackServer ? "fallback" : "primary") server...")
        currentServer = isUsingFallbackServer ? "Fallback Server" : "Primary Server"
        
        // Create WebSocket request with headers
        var request = URLRequest(url: url)
        request.timeoutInterval = 10  // Shorter timeout to quickly detect failures
        request.setValue("websocket", forHTTPHeaderField: "Upgrade")
        request.setValue("Upgrade", forHTTPHeaderField: "Connection")
        request.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Listen for messages
        listenForMessages()
        
        // Send a ping to test connection
        sendPing()
    }
    
    func disconnect() {
        print("🔌 Disconnecting from \(isUsingFallbackServer ? "fallback" : "primary") server...")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        onConnectionStatusChanged?(false)
    }
    
    func switchToFallbackServer() {
        guard !isUsingFallbackServer else { return }
        print("⚠️ Switching to fallback server...")
        isUsingFallbackServer = true
        disconnect()
        connect()
    }
    
    func send(message: String, completion: ((Bool) -> Void)? = nil) {
        if isConnected {
            let messageToSend = URLSessionWebSocketTask.Message.string(message)
            webSocketTask?.send(messageToSend) { [weak self] error in
                if let error = error {
                    print("❌ Error sending message: \(error.localizedDescription)")
                    self?.connectionError = "Failed to send message: \(error.localizedDescription)"
                    self?.messageQueue.append(message)
                    completion?(false)
                    
                    // If on primary server and send fails, try fallback
                    if !(self?.isUsingFallbackServer ?? true) {
                        self?.switchToFallbackServer()
                    }
                } else {
                    completion?(true)
                }
            }
        } else {
            print("📦 Queueing message for later: \(message)")
            messageQueue.append(message)
            completion?(false)
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("❌ Error receiving message: \(error.localizedDescription)")
                self?.connectionError = "Failed to receive message: \(error.localizedDescription)"
                
                // If on primary server and receive fails, try fallback
                if !(self?.isUsingFallbackServer ?? true) {
                    self?.switchToFallbackServer()
                } else {
                    self?.disconnect()
                }
                
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received message: \(text)")
                    self?.onMessageReceived?(text)
                default:
                    print("⚠️ Received unexpected message type")
                }
                
                // Continue listening for new messages
                self?.listenForMessages()
            }
        }
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping failed: \(error.localizedDescription)")
                self?.connectionError = "Failed to establish connection: \(error.localizedDescription)"
                
                // If ping fails on primary server, switch to fallback
                if !(self?.isUsingFallbackServer ?? true) {
                    self?.switchToFallbackServer()
                } else {
                    self?.disconnect()
                }
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 Attempting to reconnect...")
            self.connect()
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                     didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected successfully to \(isUsingFallbackServer ? "fallback" : "primary") server")
        isConnected = true
        connectionError = nil
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
        
        let errorMessage: String
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            errorMessage = "WebSocket disconnected. Close code: \(closeCode), Reason: \(reasonString)"
        } else {
            errorMessage = "WebSocket disconnected with code: \(closeCode)"
        }
        
        print("❌ \(errorMessage)")
        connectionError = errorMessage
        isConnected = false
        onConnectionStatusChanged?(false)
        
        // If primary server closes, try fallback
        if !isUsingFallbackServer {
            switchToFallbackServer()
        } else {
            scheduleReconnect()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ WebSocket task failed: \(error.localizedDescription)")
            connectionError = "Connection failed: \(error.localizedDescription)"
            isConnected = false
            onConnectionStatusChanged?(false)
            
            // If primary server fails, try fallback
            if !isUsingFallbackServer {
                switchToFallbackServer()
            } else {
                scheduleReconnect()
            }
        }
    }
}
