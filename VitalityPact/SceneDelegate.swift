//
//  SceneDelegate.swift
//  VitalityPact
//
//  场景委托 - 用于支持多窗口和Widget
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // 创建SwiftUI视图的窗口
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(
                rootView: ContentView()
                    .environmentObject(HealthStoreManager.shared)
                    .environmentObject(GameStateManager.shared)
            )
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // 场景被断开时调用
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 场景变为活跃状态时调用
        // 可以在这里刷新数据
        Task {
            await HealthStoreManager.shared.fetchAllData()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 场景将变为非活跃状态时调用
        // 保存当前状态到Widget
        let healthManager = HealthStoreManager.shared
        let gameState = GameStateManager.shared
        WidgetDataManager.shared.syncFromHealthData(
            healthManager.healthData,
            state: gameState.characterState,
            message: gameState.currentDialogue
        )
    }
}
