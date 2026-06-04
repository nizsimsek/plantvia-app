//
//  ConnectivityStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import Foundation
import Network
import Combine

final class ConnectivityStore: ObservableObject {
    @Published @MainActor private(set) var isOnline = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "plantvia.connectivity.monitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            DispatchQueue.main.async {
                self?.isOnline = isOnline
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
