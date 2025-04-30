//
//  ChatPreview.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Foundation
struct ChatPreview: Identifiable {
    let id: UUID = UUID()
    let userName: String
    let lastMessage: String
    let timestamp: Date
    var hasUnreadMessages: Bool
}
