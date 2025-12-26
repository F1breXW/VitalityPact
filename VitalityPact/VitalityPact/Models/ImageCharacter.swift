//
//  ImageCharacter.swift
//  VitalityPact
//
//  图片角色系统 - 支持精美图片作为伙伴形象
//

import SwiftUI
import Combine

/// 图片角色定义
struct ImageCharacter: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: CharacterCategory
    let style: CharacterType  // 继承哪种对话风格
    
    /// 各健康等级对应的图片名称
    let images: [String: String]  // HealthLevel.rawValue -> imageName
    
    /// 主题色（用于UI）
    var themeColorHex: String
    
    var themeColor: Color {
        Color(hex: themeColorHex) ?? .purple
    }
    
    /// 获取指定等级的图片名
    func imageName(for level: HealthLevel) -> String {
        images[String(level.rawValue)] ?? images["2"] ?? "\(id)_normal"
    }
    
    static func == (lhs: ImageCharacter, rhs: ImageCharacter) -> Bool {
        lhs.id == rhs.id
    }
}

/// 角色类别
enum CharacterCategory: String, Codable, CaseIterable {
    case anime = "anime"           // 动漫风格
    case cute = "cute"             // Q版可爱
    case realistic = "realistic"   // 写实风格
    case pixel = "pixel"           // 像素风格
    case custom = "custom"         // 用户自定义
    
    var displayName: String {
        switch self {
        case .anime: return "动漫风格"
        case .cute: return "Q版可爱"
        case .realistic: return "写实风格"
        case .pixel: return "像素风格"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .anime: return "🎭"
        case .cute: return "🧸"
        case .realistic: return "🖼️"
        case .pixel: return "👾"
        case .custom: return "✨"
        }
    }
}

/// 图片角色管理器
class ImageCharacterManager: ObservableObject {
    static let shared = ImageCharacterManager()
    
    @Published var availableCharacters: [ImageCharacter] = []
    @Published var selectedCharacterId: String? {
        didSet {
            UserDefaults.standard.set(selectedCharacterId, forKey: "selectedImageCharacterId")
        }
    }
    @Published var useImageCharacter: Bool = false {
        didSet {
            UserDefaults.standard.set(useImageCharacter, forKey: "useImageCharacter")
        }
    }
    
    var selectedCharacter: ImageCharacter? {
        guard let id = selectedCharacterId else { return nil }
        return availableCharacters.first { $0.id == id }
    }
    
    private init() {
        loadSettings()
        loadBuiltInCharacters()
    }
    
    private func loadSettings() {
        selectedCharacterId = UserDefaults.standard.string(forKey: "selectedImageCharacterId")
        useImageCharacter = UserDefaults.standard.bool(forKey: "useImageCharacter")
    }
    
    /// 加载内置角色
    private func loadBuiltInCharacters() {
        availableCharacters = [
            // 可爱小狐狸
            ImageCharacter(
                id: "fox",
                name: "小狐狸·绒绒",
                description: "温暖治愈的小狐狸，会用软软的尾巴安慰你",
                category: .cute,
                style: .pet,
                images: [
                    "0": "fox_critical",
                    "1": "fox_weak",
                    "2": "fox_normal",
                    "3": "fox_good",
                    "4": "fox_excellent"
                ],
                themeColorHex: "#FF9500"
            ),
            
            // 元气少女
            ImageCharacter(
                id: "girl_genki",
                name: "元气少女·小阳",
                description: "活力满满的元气少女，用热情感染你",
                category: .anime,
                style: .warrior,
                images: [
                    "0": "girl_genki_critical",
                    "1": "girl_genki_weak",
                    "2": "girl_genki_normal",
                    "3": "girl_genki_good",
                    "4": "girl_genki_excellent"
                ],
                themeColorHex: "#FF6B6B"
            ),
            
            // 温柔精灵
            ImageCharacter(
                id: "elf",
                name: "森林精灵·露娜",
                description: "来自森林的精灵，用自然的力量守护你",
                category: .anime,
                style: .mage,
                images: [
                    "0": "elf_critical",
                    "1": "elf_weak",
                    "2": "elf_normal",
                    "3": "elf_good",
                    "4": "elf_excellent"
                ],
                themeColorHex: "#4ECDC4"
            ),
            
            // 智慧猫头鹰
            ImageCharacter(
                id: "owl",
                name: "智者·欧罗",
                description: "博学多识的猫头鹰，给你睿智的建议",
                category: .cute,
                style: .sage,
                images: [
                    "0": "owl_critical",
                    "1": "owl_weak",
                    "2": "owl_normal",
                    "3": "owl_good",
                    "4": "owl_excellent"
                ],
                themeColorHex: "#5C6BC0"
            ),
            
            // 像素勇者
            ImageCharacter(
                id: "pixel_hero",
                name: "像素勇者",
                description: "复古像素风格的小勇者，陪你一起冒险",
                category: .pixel,
                style: .warrior,
                images: [
                    "0": "pixel_hero_critical",
                    "1": "pixel_hero_weak",
                    "2": "pixel_hero_normal",
                    "3": "pixel_hero_good",
                    "4": "pixel_hero_excellent"
                ],
                themeColorHex: "#9C27B0"
            ),
            
            // 治愈小熊
            ImageCharacter(
                id: "bear",
                name: "抱抱熊·团团",
                description: "软绵绵的小熊，随时给你一个温暖的拥抱",
                category: .cute,
                style: .mage,
                images: [
                    "0": "bear_critical",
                    "1": "bear_weak",
                    "2": "bear_normal",
                    "3": "bear_good",
                    "4": "bear_excellent"
                ],
                themeColorHex: "#8D6E63"
            )
        ]
    }
    
    /// 选择角色
    func selectCharacter(_ character: ImageCharacter) {
        selectedCharacterId = character.id
        useImageCharacter = true
    }
    
    /// 切换回emoji角色
    func switchToEmojiCharacter() {
        useImageCharacter = false
    }
}

// MARK: - Color 扩展
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
