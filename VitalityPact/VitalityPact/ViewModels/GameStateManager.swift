//
//  GameStateManager.swift
//  VitalityPact
//
//  游戏状态管理器 - 数据映射与状态机（支持多角色系统）
//

import Foundation
import Combine
import UIKit

class GameStateManager: ObservableObject {
    static let shared = GameStateManager()

    @Published var characterState: CharacterState = .tired
    @Published var characterData = CharacterData()
    @Published var currentDialogue: String = "欢迎来到元气契约！点击我开始互动~"
    @Published var isLoadingDialogue = false
    @Published var showChestAnimation = false

    private var cancellables = Set<AnyCancellable>()
    private let aiService = AIService.shared

    private init() {
        setupHealthDataObserver()
        // 初始化时生成欢迎对话
        generateInitialDialogue()
    }

    /// 监听健康数据变化
    private func setupHealthDataObserver() {
        HealthStoreManager.shared.$healthData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.updateGameState(from: healthData)
            }
            .store(in: &cancellables)
    }
    
    /// 生成初始欢迎对话
    private func generateInitialDialogue() {
        let characterType = UserSettings.shared.selectedCharacterType
        switch characterType {
        case .warrior:
            currentDialogue = "嘿！新的一天，准备好冲锋了吗？"
        case .mage:
            currentDialogue = "你好呀~今天也要好好照顾自己哦"
        case .pet:
            currentDialogue = "喵~主人终于来了！人家等好久了~"
        case .sage:
            currentDialogue = "健康是最宝贵的财富，让我们一起守护它。"
        }
    }

    /// 根据健康数据更新游戏状态
    func updateGameState(from healthData: HealthData) {
        let previousState = characterState

        // 更新角色数据
        characterData.updateFromHealthData(healthData)

        // 计算角色状态
        characterState = calculateState(from: healthData)

        // 如果状态变化，生成新对话并同步到 Widget
        if previousState != characterState {
            generateDialogue(for: healthData)
        }
        
        // 同步数据到 Widget
        syncToWidget(healthData: healthData)
    }

    /// 计算角色状态
    private func calculateState(from healthData: HealthData) -> CharacterState {
        // 优先级：疲劳 > 兴奋 > 健康
        if healthData.hasSleepDebuff {
            return .tired
        }

        if healthData.overallScore >= 80 {
            return .excited
        }

        if healthData.overallScore >= 40 {
            return .healthy
        }

        return .tired
    }

    /// 触发奖励显示（用户手动触发或状态达标时）
    func showReward() {
        showChestAnimation = true
        HapticManager.shared.success()
    }
    
    /// 隐藏奖励动画
    func hideReward() {
        showChestAnimation = false
    }

    /// 生成AI对话（使用新的角色类型系统）
    func generateDialogue(for healthData: HealthData) {
        isLoadingDialogue = true
        
        let characterType = UserSettings.shared.selectedCharacterType
        let healthLevel = HealthLevel.from(score: healthData.overallScore)

        Task {
            let dialogue = await aiService.generateDialogue(
                characterType: characterType,
                healthLevel: healthLevel,
                healthData: healthData
            )

            await MainActor.run {
                self.currentDialogue = dialogue
                self.isLoadingDialogue = false
                // 生成对话后同步到 Widget
                self.syncToWidget(healthData: healthData)
            }
        }
    }

    /// 用户点击角色时触发对话
    func onCharacterTapped() {
        generateDialogue(for: HealthStoreManager.shared.healthData)
        // 触觉反馈
        HapticManager.shared.impact(style: .medium)
    }
    
    /// 同步数据到 Widget
    private func syncToWidget(healthData: HealthData) {
        let characterType = UserSettings.shared.selectedCharacterType
        WidgetDataManager.shared.syncFromHealthData(
            healthData,
            characterType: characterType,
            message: currentDialogue
        )
    }

    /// 获取状态描述文本
    func getStatusDescription() -> String {
        let healthData = HealthStoreManager.shared.healthData

        var descriptions: [String] = []

        // 步数状态
        if healthData.steps < 2000 {
            descriptions.append("步数较少")
        } else if healthData.steps >= 8000 {
            descriptions.append("步数充足")
        }

        // 睡眠状态
        if healthData.hasSleepDebuff {
            descriptions.append("睡眠不足⚠️")
        } else if healthData.sleepHours >= 7 {
            descriptions.append("睡眠良好")
        }

        // 运动状态
        if healthData.hasChestReward {
            descriptions.append("运动达标✨")
        }

        return descriptions.isEmpty ? "状态正常" : descriptions.joined(separator: " | ")
    }
}

/// 触觉反馈管理器
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func success() {
        notification(type: UINotificationFeedbackGenerator.FeedbackType.success)
    }

    func warning() {
        notification(type: UINotificationFeedbackGenerator.FeedbackType.warning)
    }

    func error() {
        notification(type: UINotificationFeedbackGenerator.FeedbackType.error)
    }
}
