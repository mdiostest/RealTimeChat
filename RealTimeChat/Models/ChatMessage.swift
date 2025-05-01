//
//  ChatMessage.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation

enum MessageStatus {
    case sending
    case sent
    case delivered
    case failed
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
    let isUser: Bool
    let timestamp: Date
    var read: Bool = false
    var status: MessageStatus = .sent // Add this line
}
