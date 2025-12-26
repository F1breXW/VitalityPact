//
//  CharacterType.swift
//  VitalityPact
//
//  角色形象类型系统 - 支持多种角色风格
//

import SwiftUI
import Combine

/// 角色形象类型
enum CharacterType: String, CaseIterable, Codable {
    case warrior = "warrior"        // 战士型 - 热血励志风格
    case mage = "mage"              // 法师型 - 温柔治愈风格
    case pet = "pet"                // 萌宠型 - 可爱撒娇风格
    case sage = "sage"              // 智者型 - 稳重建议风格
    
    /// 角色名称
    var displayName: String {
        switch self {
        case .warrior: return "热血战士"
        case .mage: return "治愈法师"
        case .pet: return "元气萌宠"
        case .sage: return "睿智导师"
        }
    }
    
    /// 角色描述
    var description: String {
        switch self {
        case .warrior: return "充满热血与斗志，用激励的话语鼓舞你前进"
        case .mage: return "温柔治愈系，用关怀的语气陪伴你每一天"
        case .pet: return "可爱萌系，会撒娇卖萌让你心情愉悦"
        case .sage: return "沉稳睿智，给你专业的健康建议和人生道理"
        }
    }
    
    /// 角色图标
    var icon: String {
        switch self {
        case .warrior: return "⚔️"
        case .mage: return "🔮"
        case .pet: return "🐱"
        case .sage: return "📚"
        }
    }
    
    /// 主题色
    var themeColor: Color {
        switch self {
        case .warrior: return .red
        case .mage: return .purple
        case .pet: return .pink
        case .sage: return .blue
        }
    }
    
    /// 健康状态对应的形象 (5个层次)
    func characterEmoji(for level: HealthLevel) -> String {
        switch self {
        case .warrior:
            switch level {
            case .critical: return "😵"      // 濒死
            case .weak: return "😓"          // 虚弱
            case .normal: return "😤"        // 普通
            case .good: return "💪"          // 良好
            case .excellent: return "🔥"     // 极佳
            }
        case .mage:
            switch level {
            case .critical: return "😢"
            case .weak: return "😔"
            case .normal: return "🙂"
            case .good: return "😊"
            case .excellent: return "✨"
            }
        case .pet:
            switch level {
            case .critical: return "🐱💤"
            case .weak: return "😿"
            case .normal: return "🐱"
            case .good: return "😺"
            case .excellent: return "😻"
            }
        case .sage:
            switch level {
            case .critical: return "🧙‍♂️💫"
            case .weak: return "🧙‍♂️😔"
            case .normal: return "🧙‍♂️"
            case .good: return "🧙‍♂️✨"
            case .excellent: return "🧙‍♂️🌟"
            }
        }
    }
    
    /// 状态效果图标
    func statusEffect(for level: HealthLevel) -> String? {
        switch level {
        case .critical: return "💀"
        case .weak: return "💫"
        case .normal: return nil
        case .good: return "⭐"
        case .excellent: return "🌟"
        }
    }
    
    /// 背景渐变色
    func backgroundColors(for level: HealthLevel) -> [Color] {
        let baseColors: [Color]
        switch self {
        case .warrior:
            baseColors = [.red, .orange]
        case .mage:
            baseColors = [.purple, .pink]
        case .pet:
            baseColors = [.pink, .yellow]
        case .sage:
            baseColors = [.blue, .cyan]
        }
        
        switch level {
        case .critical:
            return [.gray.opacity(0.8), .black]
        case .weak:
            return [.gray.opacity(0.6), baseColors[1].opacity(0.3)]
        case .normal:
            return [baseColors[0].opacity(0.5), baseColors[1].opacity(0.4)]
        case .good:
            return [baseColors[0].opacity(0.6), baseColors[1].opacity(0.5)]
        case .excellent:
            return [baseColors[0].opacity(0.8), baseColors[1].opacity(0.7)]
        }
    }
    
    /// 简短描述（用于卡片展示）
    var shortDescription: String {
        switch self {
        case .warrior: return "热血鼓励型"
        case .mage: return "温柔关怀型"
        case .pet: return "可爱陪伴型"
        case .sage: return "智慧建议型"
        }
    }
}

/// 健康等级（5个层次）
enum HealthLevel: Int, CaseIterable {
    case critical = 0   // 危险 (0-20分)
    case weak = 1       // 虚弱 (21-40分)
    case normal = 2     // 普通 (41-60分)
    case good = 3       // 良好 (61-80分)
    case excellent = 4  // 极佳 (81-100分)
    
    var displayName: String {
        switch self {
        case .critical: return "危险"
        case .weak: return "虚弱"
        case .normal: return "普通"
        case .good: return "良好"
        case .excellent: return "极佳"
        }
    }
    
    /// 简短名称（用于小空间展示）
    var shortName: String {
        switch self {
        case .critical: return "危"
        case .weak: return "弱"
        case .normal: return "中"
        case .good: return "好"
        case .excellent: return "优"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .weak: return .orange
        case .normal: return .yellow
        case .good: return .green
        case .excellent: return .cyan
        }
    }
    
    /// 从健康分数计算等级
    static func from(score: Int) -> HealthLevel {
        switch score {
        case 0...20: return .critical
        case 21...40: return .weak
        case 41...60: return .normal
        case 61...80: return .good
        default: return .excellent
        }
    }
}

/// 用户设置管理
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var selectedCharacterType: CharacterType {
        didSet {
            UserDefaults.standard.set(selectedCharacterType.rawValue, forKey: "selectedCharacterType")
            syncToWidget()
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    // MARK: - 奖励设置
    /// 奖励触发的健康等级
    @Published var rewardTriggerLevel: HealthLevel {
        didSet {
            UserDefaults.standard.set(rewardTriggerLevel.rawValue, forKey: "rewardTriggerLevel")
        }
    }
    
    /// 各等级的奖励内容
    @Published var rewardContents: [HealthLevel: String] {
        didSet {
            let dict = rewardContents.mapKeys { String($0.rawValue) }
            UserDefaults.standard.set(dict, forKey: "rewardContents")
        }
    }
    
    /// 各等级的奖励图标（用户自定义）
    @Published var rewardIcons: [HealthLevel: String] {
        didSet {
            let dict = rewardIcons.mapKeys { String($0.rawValue) }
            UserDefaults.standard.set(dict, forKey: "rewardIcons")
        }
    }
    
    private init() {
        // 从 UserDefaults 加载设置
        if let typeString = UserDefaults.standard.string(forKey: "selectedCharacterType"),
           let type = CharacterType(rawValue: typeString) {
            self.selectedCharacterType = type
        } else {
            self.selectedCharacterType = .warrior
        }
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // 加载奖励设置
        self.rewardTriggerLevel = HealthLevel(rawValue: UserDefaults.standard.integer(forKey: "rewardTriggerLevel")) ?? .good
        
        // 加载奖励内容
        if let savedDict = UserDefaults.standard.dictionary(forKey: "rewardContents") as? [String: String] {
            var contents: [HealthLevel: String] = [:]
            for (key, value) in savedDict {
                if let rawValue = Int(key), let level = HealthLevel(rawValue: rawValue) {
                    contents[level] = value
                }
            }
            self.rewardContents = contents
        } else {
            // 默认奖励内容
            self.rewardContents = [
                .critical: "好好休息一下吧",
                .weak: "喝杯热水，放松一下",
                .normal: "继续保持，你很棒",
                .good: "奖励自己一杯奶茶",
                .excellent: "太棒了！给自己一个大大的奖励"
            ]
        }
        
        // 加载奖励图标
        if let savedIcons = UserDefaults.standard.dictionary(forKey: "rewardIcons") as? [String: String] {
            var icons: [HealthLevel: String] = [:]
            for (key, value) in savedIcons {
                if let rawValue = Int(key), let level = HealthLevel(rawValue: rawValue) {
                    icons[level] = value
                }
            }
            self.rewardIcons = icons
        } else {
            // 默认图标
            self.rewardIcons = [
                .critical: "💤",
                .weak: "🤗",
                .normal: "⭐",
                .good: "🎁",
                .excellent: "🏆"
            ]
        }
    }
    
    /// 重置所有设置（退出调试模式时调用）
    func resetToInitialState() {
        hasCompletedOnboarding = false
    }
    
    /// 同步设置到 Widget
    private func syncToWidget() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.Xianwei.VitalityPact")
        sharedDefaults?.set(selectedCharacterType.rawValue, forKey: "characterType")
    }
    
    /// 获取当前等级的奖励
    func getReward(for level: HealthLevel) -> (icon: String, text: String) {
        let text = rewardContents[level] ?? "继续努力！"
        let icon = rewardIcons[level] ?? defaultIcon(for: level)
        return (icon, text)
    }
    
    /// 默认图标
    private func defaultIcon(for level: HealthLevel) -> String {
        switch level {
        case .critical: return "💤"
        case .weak: return "🤗"
        case .normal: return "⭐"
        case .good: return "🎁"
        case .excellent: return "🏆"
        }
    }
}

// 辅助扩展
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}
