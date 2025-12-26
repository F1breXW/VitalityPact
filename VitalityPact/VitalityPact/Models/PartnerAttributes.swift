//
//  PartnerAttributes.swift
//  VitalityPact
//
//  伙伴属性成长系统 - RPG风格的持久化属性
//

import Foundation
import Combine

/// 伙伴属性数据（每个伙伴独立）
struct PartnerAttributes: Codable {
    var partnerId: String
    
    // 基础属性
    var level: Int = 1                      // 等级
    var experience: Int = 0                 // 当前经验值
    var experienceToNextLevel: Int {        // 升级所需经验
        level * 100 + 50                    // 等级越高升级越难
    }
    
    // RPG属性
    var strength: Int = 10                  // 力量（步数相关）
    var vitality: Int = 10                  // 体质（睡眠相关）
    var agility: Int = 10                   // 敏捷（运动相关）
    var wisdom: Int = 10                    // 智慧（综合表现）
    
    // 统计数据
    var totalDaysActive: Int = 0            // 活跃天数
    var lastActiveDate: Date = Date()       // 最后活跃日期
    var createdDate: Date = Date()          // 创建日期
    
    /// 总战力
    var totalPower: Int {
        strength + vitality + agility + wisdom + (level * 5)
    }
    
    /// 经验百分比
    var experiencePercentage: Double {
        Double(experience) / Double(experienceToNextLevel)
    }
    
    /// 是否可以升级
    var canLevelUp: Bool {
        experience >= experienceToNextLevel
    }
    
    /// 升级
    mutating func levelUp() {
        if canLevelUp {
            level += 1
            experience -= experienceToNextLevel
            
            // 升级时随机增加属性
            strength += Int.random(in: 1...3)
            vitality += Int.random(in: 1...3)
            agility += Int.random(in: 1...3)
            wisdom += Int.random(in: 1...2)
        }
    }
    
    /// 添加经验值
    mutating func addExperience(_ exp: Int) {
        experience += exp
        
        // 连续升级
        while canLevelUp {
            levelUp()
        }
    }
}

/// 健康行为奖励规则
struct HealthRewardRule {
    /// 计算今日健康行为带来的奖励
    static func calculateDailyRewards(from healthData: HealthData) -> PartnerRewards {
        var rewards = PartnerRewards()
        
        // 步数奖励 -> 力量
        if healthData.steps >= 10000 {
            rewards.experienceGain += 30
            rewards.strengthGain += 2
        } else if healthData.steps >= 7000 {
            rewards.experienceGain += 20
            rewards.strengthGain += 1
        } else if healthData.steps >= 5000 {
            rewards.experienceGain += 10
        }
        
        // 睡眠奖励 -> 体质
        if healthData.sleepHours >= 8 {
            rewards.experienceGain += 30
            rewards.vitalityGain += 2
        } else if healthData.sleepHours >= 7 {
            rewards.experienceGain += 20
            rewards.vitalityGain += 1
        } else if healthData.sleepHours >= 6 {
            rewards.experienceGain += 10
        } else if healthData.sleepHours < 5 {
            // 睡眠不足惩罚
            rewards.vitalityGain -= 1
        }
        
        // 运动奖励 -> 敏捷
        if healthData.exerciseMinutes >= 60 {
            rewards.experienceGain += 30
            rewards.agilityGain += 2
        } else if healthData.exerciseMinutes >= 30 {
            rewards.experienceGain += 20
            rewards.agilityGain += 1
        } else if healthData.exerciseMinutes >= 15 {
            rewards.experienceGain += 10
        }
        
        // 综合表现奖励 -> 智慧
        if healthData.overallScore >= 80 {
            rewards.experienceGain += 20
            rewards.wisdomGain += 2
        } else if healthData.overallScore >= 60 {
            rewards.wisdomGain += 1
        }
        
        return rewards
    }
}

/// 每日奖励结果
struct PartnerRewards {
    var experienceGain: Int = 0
    var strengthGain: Int = 0
    var vitalityGain: Int = 0
    var agilityGain: Int = 0
    var wisdomGain: Int = 0
    
    var hasAnyReward: Bool {
        experienceGain > 0 || strengthGain > 0 || vitalityGain > 0 || 
        agilityGain > 0 || wisdomGain > 0
    }
    
    /// 应用奖励到伙伴属性
    func apply(to attributes: inout PartnerAttributes) {
        attributes.addExperience(experienceGain)
        attributes.strength = max(1, attributes.strength + strengthGain)
        attributes.vitality = max(1, attributes.vitality + vitalityGain)
        attributes.agility = max(1, attributes.agility + agilityGain)
        attributes.wisdom = max(1, attributes.wisdom + wisdomGain)
    }
}

/// 伙伴属性管理器
class PartnerAttributesManager: ObservableObject {
    static let shared = PartnerAttributesManager()
    
    @Published private var attributesDict: [String: PartnerAttributes] = [:]
    
    private let userDefaultsKey = "partnerAttributesDict"
    
    private init() {
        loadAttributes()
    }
    
    /// 获取指定伙伴的属性
    func getAttributes(for partnerId: String) -> PartnerAttributes {
        if let existing = attributesDict[partnerId] {
            return existing
        }
        
        // 创建新伙伴
        let newAttributes = PartnerAttributes(partnerId: partnerId)
        attributesDict[partnerId] = newAttributes
        saveAttributes()
        return newAttributes
    }
    
    /// 更新伙伴属性
    func updateAttributes(_ attributes: PartnerAttributes) {
        attributesDict[attributes.partnerId] = attributes
        saveAttributes()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// 应用每日健康数据奖励
    func applyDailyRewards(partnerId: String, healthData: HealthData) -> (attributes: PartnerAttributes, rewards: PartnerRewards, leveledUp: Bool) {
        var attributes = getAttributes(for: partnerId)
        let oldLevel = attributes.level
        
        // 计算奖励
        let rewards = HealthRewardRule.calculateDailyRewards(from: healthData)
        
        // 应用奖励
        rewards.apply(to: &attributes)
        
        // 更新活跃信息
        attributes.totalDaysActive += 1
        attributes.lastActiveDate = Date()
        
        // 保存
        updateAttributes(attributes)
        
        let leveledUp = attributes.level > oldLevel
        return (attributes, rewards, leveledUp)
    }
    
    /// 重置所有伙伴（调试用）
    func resetAllPartners() {
        attributesDict.removeAll()
        saveAttributes()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 持久化
    
    private func saveAttributes() {
        if let encoded = try? JSONEncoder().encode(attributesDict) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadAttributes() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: PartnerAttributes].self, from: data) {
            attributesDict = decoded
        }
    }
}
