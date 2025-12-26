//
//  WidgetDataManager.swift
//  VitalityPact
//
//  Widget 数据共享管理器 - 支持多角色系统
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let suiteName = "group.com.Xianwei.VitalityPact"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    /// 更新 Widget 数据（新版本 - 支持多角色）
    func updateWidgetData(
        steps: Int,
        sleepHours: Double,
        healthScore: Int,
        characterType: CharacterType,
        message: String
    ) {
        sharedDefaults?.set(steps, forKey: "steps")
        sharedDefaults?.set(sleepHours, forKey: "sleepHours")
        sharedDefaults?.set(healthScore, forKey: "healthScore")
        sharedDefaults?.set(characterType.rawValue, forKey: "characterType")
        sharedDefaults?.set(message, forKey: "currentMessage")

        // 请求 Widget 刷新
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 从主 App 同步数据到 Widget
    func syncFromHealthData(_ healthData: HealthData, characterType: CharacterType, message: String) {
        updateWidgetData(
            steps: healthData.steps,
            sleepHours: healthData.sleepHours,
            healthScore: healthData.overallScore,
            characterType: characterType,
            message: message
        )
    }
    
    /// 兼容旧接口
    func syncFromHealthData(_ healthData: HealthData, state: CharacterState, message: String) {
        let characterType = UserSettings.shared.selectedCharacterType
        syncFromHealthData(healthData, characterType: characterType, message: message)
    }
}
