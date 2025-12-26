//
//  HealthData.swift
//  VitalityPact
//
//  健康数据模型
//

import Foundation

/// 健康数据模型
struct HealthData {
    var steps: Int = 0              // 今日步数
    var sleepHours: Double = 0      // 昨晚睡眠时长（小时）
    var exerciseMinutes: Int = 0    // 运动时长（分钟）
    var heartRate: Int = 70         // 心率

    /// 步数评级 (0-100)
    var stepsScore: Int {
        min(100, steps / 100)  // 10000步 = 100分
    }

    /// 睡眠评级 (0-100)
    var sleepScore: Int {
        if sleepHours >= 8 { return 100 }
        if sleepHours >= 7 { return 80 }
        if sleepHours >= 6 { return 60 }
        if sleepHours >= 5 { return 40 }
        if sleepHours >= 4 { return 20 }
        return 0
    }

    /// 运动评级 (0-100)
    var exerciseScore: Int {
        min(100, exerciseMinutes * 100 / 60)  // 60分钟 = 100分
    }

    /// 综合健康分数
    var overallScore: Int {
        (stepsScore + sleepScore + exerciseScore) / 3
    }

    /// 金币数量 (步数/10)
    var goldCoins: Int {
        steps / 10
    }

    /// 是否有睡眠不足的 Debuff
    var hasSleepDebuff: Bool {
        sleepHours < 6
    }

    /// 是否获得宝箱 (运动>30分钟)
    var hasChestReward: Bool {
        exerciseMinutes >= 30
    }
}

/// 角色状态枚举
enum CharacterState: String, CaseIterable {
    case healthy = "healthy"      // 健康状态
    case tired = "tired"          // 疲劳状态
    case excited = "excited"      // 兴奋/进化状态

    var displayName: String {
        switch self {
        case .healthy: return "健康"
        case .tired: return "疲劳"
        case .excited: return "亢奋"
        }
    }

    var imageName: String {
        switch self {
        case .healthy: return "character_healthy"
        case .tired: return "character_tired"
        case .excited: return "character_excited"
        }
    }

    var backgroundName: String {
        switch self {
        case .healthy: return "bg_normal"
        case .tired: return "bg_dark"
        case .excited: return "bg_bright"
        }
    }

    var description: String {
        switch self {
        case .healthy: return "状态良好，随时准备冒险！"
        case .tired: return "能量不足，需要休息..."
        case .excited: return "能量满溢，无所畏惧！"
        }
    }
}

/// 角色数据模型
struct CharacterData {
    var name: String = "元气兽"
    var level: Int = 1
    var experience: Int = 0
    var attack: Int = 10
    var defense: Int = 10
    var health: Int = 100
    var maxHealth: Int = 100

    /// 根据健康数据更新角色属性
    mutating func updateFromHealthData(_ healthData: HealthData) {
        // 心率影响攻击力
        attack = 10 + (healthData.heartRate - 60) / 5

        // 睡眠影响防御力
        if healthData.hasSleepDebuff {
            defense = 5  // 防御减半
        } else {
            defense = 10 + Int(healthData.sleepHours)
        }

        // 综合分数影响生命值
        health = min(maxHealth, healthData.overallScore)
    }
}
