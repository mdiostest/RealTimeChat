//
//  NetworkMonitor.swift
//  RealTimeChat
//
//  Created by Mriganka De on 30/04/25.
//

import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var onStatusChange: ((Bool) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self.onStatusChange?(isConnected)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
