//
//  ZenithApp.swift
//  Zenith
//
//  Created by chaitu  on 27/08/25.
//

import SwiftUI

@main
struct ZenithApp: App {
    // MARK: - State Management
    
    /// Finance manager injected once at app entry as StateObject
    /// This ensures single instance throughout the app lifecycle
    @StateObject private var financeManager = FinanceManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(financeManager)
        }
    }
}
