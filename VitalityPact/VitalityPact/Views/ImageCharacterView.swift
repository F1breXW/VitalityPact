//
//  ImageCharacterView.swift
//  VitalityPact
//
//  图片角色选择和显示视图
//

import SwiftUI

// MARK: - 图片角色显示视图
struct ImageCharacterDisplayView: View {
    let character: ImageCharacter
    let healthLevel: HealthLevel
    var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 光环效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [character.themeColor.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
            
            // 角色图片（如果有）或占位符
            VStack(spacing: 10) {
                CharacterImageView(character: character, healthLevel: healthLevel)
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                
                // 状态效果
                if let effect = statusEffect {
                    Text(effect)
                        .font(.title2)
                        .transition(.scale)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: healthLevel)
    }
    
    var statusEffect: String? {
        switch healthLevel {
        case .critical: return "💀"
        case .weak: return "💫"
        case .normal: return nil
        case .good: return "⭐"
        case .excellent: return "🌟"
        }
    }
}

// MARK: - 角色图片视图（带占位符）
struct CharacterImageView: View {
    let character: ImageCharacter
    let healthLevel: HealthLevel
    
    var body: some View {
        // 尝试加载图片，如果没有则显示占位符
        if let _ = UIImage(named: character.imageName(for: healthLevel)) {
            Image(character.imageName(for: healthLevel))
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // 占位符 - 使用渐变圆和图标
            PlaceholderCharacterView(character: character, healthLevel: healthLevel)
        }
    }
}

// MARK: - 占位角色视图
struct PlaceholderCharacterView: View {
    let character: ImageCharacter
    let healthLevel: HealthLevel
    
    var body: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 角色图标
            VStack(spacing: 5) {
                Text(characterIcon)
                    .font(.system(size: 60))
                
                // 状态指示
                Text(healthLevel.shortName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(healthLevel.color.opacity(0.8))
                    .cornerRadius(8)
            }
        }
    }
    
    var characterIcon: String {
        switch character.id {
        case "fox": return foxEmoji
        case "girl_genki": return girlEmoji
        case "elf": return elfEmoji
        case "owl": return owlEmoji
        case "pixel_hero": return heroEmoji
        case "bear": return bearEmoji
        default: return "😊"
        }
    }
    
    var foxEmoji: String {
        switch healthLevel {
        case .critical: return "🦊💤"
        case .weak: return "🦊😔"
        case .normal: return "🦊"
        case .good: return "🦊😊"
        case .excellent: return "🦊✨"
        }
    }
    
    var girlEmoji: String {
        switch healthLevel {
        case .critical: return "👧💫"
        case .weak: return "👧😓"
        case .normal: return "👧"
        case .good: return "👧💪"
        case .excellent: return "👧🔥"
        }
    }
    
    var elfEmoji: String {
        switch healthLevel {
        case .critical: return "🧝‍♀️💫"
        case .weak: return "🧝‍♀️😢"
        case .normal: return "🧝‍♀️"
        case .good: return "🧝‍♀️😊"
        case .excellent: return "🧝‍♀️✨"
        }
    }
    
    var owlEmoji: String {
        switch healthLevel {
        case .critical: return "🦉💤"
        case .weak: return "🦉😔"
        case .normal: return "🦉"
        case .good: return "🦉📚"
        case .excellent: return "🦉🌟"
        }
    }
    
    var heroEmoji: String {
        switch healthLevel {
        case .critical: return "🎮💀"
        case .weak: return "🎮❤️"
        case .normal: return "🎮"
        case .good: return "🎮⚔️"
        case .excellent: return "🎮🏆"
        }
    }
    
    var bearEmoji: String {
        switch healthLevel {
        case .critical: return "🧸💤"
        case .weak: return "🧸😢"
        case .normal: return "🧸"
        case .good: return "🧸🤗"
        case .excellent: return "🧸💖"
        }
    }
    
    var gradientColors: [Color] {
        let baseColor = character.themeColor
        switch healthLevel {
        case .critical:
            return [.gray.opacity(0.6), .gray.opacity(0.3)]
        case .weak:
            return [baseColor.opacity(0.4), .gray.opacity(0.3)]
        case .normal:
            return [baseColor.opacity(0.6), baseColor.opacity(0.3)]
        case .good:
            return [baseColor.opacity(0.8), baseColor.opacity(0.4)]
        case .excellent:
            return [baseColor, baseColor.opacity(0.6)]
        }
    }
}

// MARK: - 图片角色选择页面
struct ImageCharacterSelectionView: View {
    @ObservedObject var characterManager = ImageCharacterManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) var dismiss
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前模式切换
                    VStack(spacing: 12) {
                        Text("选择伙伴类型")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            ModeButton(
                                title: "Emoji 角色",
                                icon: "😊",
                                isSelected: !characterManager.useImageCharacter,
                                action: {
                                    characterManager.switchToEmojiCharacter()
                                }
                            )
                            
                            ModeButton(
                                title: "图片角色",
                                icon: "🖼️",
                                isSelected: characterManager.useImageCharacter,
                                action: {
                                    if characterManager.selectedCharacterId == nil,
                                       let first = characterManager.availableCharacters.first {
                                        characterManager.selectCharacter(first)
                                    } else {
                                        characterManager.useImageCharacter = true
                                    }
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Emoji 角色选择（如果选择了 emoji 模式）
                    if !characterManager.useImageCharacter {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Emoji 伙伴")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(CharacterType.allCases, id: \.self) { type in
                                    EmojiCharacterCard(
                                        type: type,
                                        isSelected: userSettings.selectedCharacterType == type,
                                        action: {
                                            userSettings.selectedCharacterType = type
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 图片角色选择（如果选择了图片模式）
                    if characterManager.useImageCharacter {
                        ForEach(CharacterCategory.allCases, id: \.self) { category in
                            let characters = characterManager.availableCharacters.filter { $0.category == category }
                            if !characters.isEmpty {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text(category.icon)
                                        Text(category.displayName)
                                            .font(.headline)
                                    }
                                    .padding(.horizontal)
                                    
                                    LazyVGrid(columns: columns, spacing: 15) {
                                        ForEach(characters) { character in
                                            ImageCharacterCard(
                                                character: character,
                                                isSelected: characterManager.selectedCharacterId == character.id,
                                                action: {
                                                    characterManager.selectCharacter(character)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("选择伙伴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 模式选择按钮
struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.title)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Emoji 角色卡片
struct EmojiCharacterCard: View {
    let type: CharacterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(type.characterEmoji(for: .good))
                    .font(.system(size: 50))
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(type.shortDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? type.themeColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? type.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - 图片角色卡片
struct ImageCharacterCard: View {
    let character: ImageCharacter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 预览图片
                CharacterImageView(character: character, healthLevel: .good)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                
                Text(character.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(character.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? character.themeColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? character.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    ImageCharacterSelectionView()
}
