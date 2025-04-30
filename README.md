# Real-Time Chat App

A SwiftUI-based real-time chat application that supports offline functionality and real-time communication.

## Features

- 💬 Real-time messaging using WebSocket
- 📱 Single-screen chat interface
- 🔄 Offline message queuing and auto-retry
- 🚦 Robust error handling and connection management
- 📋 Chat preview list with unread indicators
- 🔀 Individual chat views
- 🔄 Automatic server fallback mechanism

## Technical Details

- **Platform**: iOS
- **Language**: Swift
- **Framework**: SwiftUI
- **Minimum iOS Version**: iOS 15.0
- **WebSocket Servers**:
  - Primary: wss://piehost.com/websocket-tester
  - Fallback: wss://ws.postman-echo.com/raw

## Project Structure

```
RealTimeChat/
├── Views/
│   ├── ChatView.swift         # Main chat list view
│   ├── IndividualChatView.swift   # Individual chat view
│   └── NewChatView.swift      # New chat creation view
├── ViewModels/
│   └── ChatViewModel.swift    # Main chat view model
├── Models/
│   ├── ChatMessage.swift      # Message model
│   └── ChatPreview.swift      # Chat preview model
├── Services/
│   ├── WebSocketManager.swift # WebSocket handling
│   └── NetworkMonitor.swift   # Network connectivity monitoring
└── RealTimeChatApp.swift      # App entry point
```

## Features in Detail

### Real-Time Communication
- WebSocket-based real-time messaging
- Automatic fallback to backup server if primary is unavailable
- Connection status monitoring and auto-reconnection

### Offline Support
- Message queuing when offline
- Automatic retry when connection is restored
- Network status monitoring

### User Interface
- Clean, modern interface
- Unread message indicators
- Real-time updates without refresh
- Clear error states and notifications

## Requirements

- Xcode 14.0+
- iOS 15.0+
- Swift 5.5+

## Installation

1. Clone the repository
```bash
git clone https://github.com/mdiostest/RealTimeChat.git
```

2. Open the project in Xcode
```bash
cd RealTimeChat
open RealTimeChat.xcodeproj
```

3. Build and run the project

## Usage

1. Launch the app
2. Create a new chat using the + button
3. Start sending messages
4. Messages will be queued if offline
5. Queued messages are automatically sent when back online

## Error Handling

The app handles various error scenarios:
- Network connectivity issues
- Server connection failures
- Message send failures
- Empty states

## Demo

A demo video showcasing the app's features is available [here].

## License

This project is licensed under the MIT License - see the LICENSE file for details. 