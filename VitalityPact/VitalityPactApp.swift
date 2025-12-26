//
//  VitalityPactApp.swift
//  VitalityPact - 元气契约
//
//  你的每一次心跳，都是拯救异世界的能量
//

import SwiftUI

@main
struct VitalityPactApp: App {
    @StateObject private var healthManager = HealthStoreManager.shared
    @StateObject private var gameState = GameStateManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(gameState)
        }
    }
}
