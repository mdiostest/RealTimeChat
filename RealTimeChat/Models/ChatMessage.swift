//
//  ChatMessage.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
    let isUser: Bool
    let timestamp: Date
    var read: Bool = false  // Track if the message is read or not
}
