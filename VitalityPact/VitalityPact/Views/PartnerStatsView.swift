//
//  PartnerStatsView.swift
//  VitalityPact
//
//  伙伴属性展示视图 - RPG风格的属性面板
//

import SwiftUI

/// 伙伴属性面板（完整版）
struct PartnerStatsView: View {
    let attributes: PartnerAttributes
    let characterName: String
    @Environment(\.dismiss) var dismiss
    @State private var showGrowthRules = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部信息
                    partnerHeader
                    
                    // 等级和经验
                    levelSection
                    
                    // 四维属性
                    attributesSection
                    
                    // 成长规则按钮
                    Button {
                        showGrowthRules = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("查看成长规则")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    // 统计信息
                    statsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("伙伴属性")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGrowthRules) {
                GrowthRulesView()
            }
        }
    }
    
    // MARK: - 头部信息
    
    private var partnerHeader: some View {
        VStack(spacing: 12) {
            // 伙伴名称
            Text(characterName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 战力
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("战力")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(attributes.totalPower)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - 等级区域
    
    private var levelSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("LV.\(attributes.level)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(attributes.experience) / \(attributes.experienceToNextLevel) EXP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(attributes.experiencePercentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 经验条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * attributes.experiencePercentage)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - 属性区域
    
    private var attributesSection: some View {
        VStack(spacing: 12) {
            Text("四维属性")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                AttributeRow(
                    icon: "figure.walk",
                    name: "力量",
                    value: attributes.strength,
                    color: .red,
                    description: "步数表现"
                )
                
                AttributeRow(
                    icon: "heart.fill",
                    name: "体质",
                    value: attributes.vitality,
                    color: .green,
                    description: "睡眠质量"
                )
                
                AttributeRow(
                    icon: "figure.run",
                    name: "敏捷",
                    value: attributes.agility,
                    color: .orange,
                    description: "运动表现"
                )
                
                AttributeRow(
                    icon: "brain.head.profile",
                    name: "智慧",
                    value: attributes.wisdom,
                    color: .purple,
                    description: "综合表现"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - 统计信息
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("统计信息")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                StatRow(label: "活跃天数", value: "\(attributes.totalDaysActive)天")
                StatRow(label: "创建时间", value: formatDate(attributes.createdDate))
                StatRow(label: "最后活跃", value: formatDate(attributes.lastActiveDate))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 属性行

struct AttributeRow: View {
    let icon: String
    let name: String
    let value: Int
    let color: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            // 名称和描述
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 数值
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 统计行

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 迷你属性面板（用于主界面）

struct PartnerStatsMini: View {
    let attributes: PartnerAttributes
    @State private var showFullStats = false
    @EnvironmentObject var gameState: GameStateManager
    @ObservedObject var imageCharacterManager = ImageCharacterManager.shared
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Button {
            showFullStats = true
        } label: {
            HStack(spacing: 12) {
                // 等级
                VStack(spacing: 2) {
                    Text("LV.\(attributes.level)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    
                    Text("战力 \(attributes.totalPower)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                // 经验条
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * attributes.experiencePercentage)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(attributes.experience)/\(attributes.experienceToNextLevel)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFullStats) {
            // 使用最新的属性数据
            if let currentAttributes = gameState.currentPartnerAttributes {
                let characterName = getCurrentCharacterName()
                PartnerStatsView(attributes: currentAttributes, characterName: characterName)
            }
        }
    }
    
    private func getCurrentCharacterName() -> String {
        // 尝试从图片角色获取
        if imageCharacterManager.useImageCharacter,
           let character = imageCharacterManager.selectedCharacter {
            return character.name
        }
        
        // 从角色类型获取
        return userSettings.selectedCharacterType.displayName
    }
}

// MARK: - 升级动画视图

struct LevelUpAnimationView: View {
    let oldLevel: Int
    let newLevel: Int
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -30
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 20) {
                // 升级图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                }
                
                // 升级文字
                VStack(spacing: 8) {
                    Text("升级了！")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        Text("LV.\(oldLevel)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("LV.\(newLevel)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                rotation = 30
            }
            
            // 3秒后自动关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - 成长规则说明视图

struct GrowthRulesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 总览
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 成长系统")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("通过健康行为获取经验值和属性提升，培养你的专属伙伴！")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 经验值获取规则
                    VStack(alignment: .leading, spacing: 16) {
                        Text("⭐️ 经验值获取")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        RuleCard(
                            icon: "figure.walk",
                            title: "步数奖励",
                            color: .blue,
                            rules: [
                                "≥10000步：获得 30 EXP",
                                "≥7000步：获得 20 EXP",
                                "≥5000步：获得 10 EXP"
                            ]
                        )
                        
                        RuleCard(
                            icon: "bed.double.fill",
                            title: "睡眠奖励",
                            color: .purple,
                            rules: [
                                "≥8小时：获得 30 EXP",
                                "≥7小时：获得 20 EXP",
                                "≥6小时：获得 10 EXP"
                            ]
                        )
                        
                        RuleCard(
                            icon: "figure.run",
                            title: "运动奖励",
                            color: .green,
                            rules: [
                                "≥60分钟：获得 30 EXP",
                                "≥30分钟：获得 20 EXP",
                                "≥15分钟：获得 10 EXP"
                            ]
                        )
                        
                        RuleCard(
                            icon: "star.fill",
                            title: "综合奖励",
                            color: .yellow,
                            rules: [
                                "综合评分≥80：获得 20 EXP",
                                "综合评分≥60：小幅提升"
                            ]
                        )
                    }
                    
                    Divider()
                    
                    // 属性提升规则
                    VStack(alignment: .leading, spacing: 16) {
                        Text("💪 属性提升")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        AttributeRuleCard(
                            icon: "figure.walk",
                            name: "力量",
                            color: .red,
                            description: "步数表现",
                            rules: [
                                "≥10000步：+2点",
                                "≥7000步：+1点"
                            ]
                        )
                        
                        AttributeRuleCard(
                            icon: "heart.fill",
                            name: "体质",
                            color: .green,
                            description: "睡眠质量",
                            rules: [
                                "≥8小时：+2点",
                                "≥7小时：+1点",
                                "<5小时：-1点 ⚠️"
                            ]
                        )
                        
                        AttributeRuleCard(
                            icon: "figure.run",
                            name: "敏捷",
                            color: .orange,
                            description: "运动表现",
                            rules: [
                                "≥60分钟：+2点",
                                "≥30分钟：+1点"
                            ]
                        )
                        
                        AttributeRuleCard(
                            icon: "brain.head.profile",
                            name: "智慧",
                            color: .purple,
                            description: "综合表现",
                            rules: [
                                "综合评分≥80：+2点",
                                "综合评分≥60：+1点"
                            ]
                        )
                    }
                    
                    Divider()
                    
                    // 升级系统
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎉 升级系统")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        InfoBox(
                            icon: "arrow.up.circle.fill",
                            title: "自动升级",
                            description: "经验值达到要求时自动升级",
                            color: .blue
                        )
                        
                        InfoBox(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "升级所需经验",
                            description: "等级 × 100 + 50（等级越高升级越难）",
                            color: .green
                        )
                        
                        InfoBox(
                            icon: "sparkles",
                            title: "升级奖励",
                            description: "随机增加 1-3 点属性",
                            color: .yellow
                        )
                    }
                    
                    Divider()
                    
                    // 提示
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("💡")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("温馨提示")
                                    .font(.headline)
                                Text("• 每天的健康数据会在第二天自动计算奖励\n• 不同伙伴的属性完全独立\n• 切换伙伴不会影响各自的成长进度\n• 坚持健康习惯，伙伴会越来越强大！")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("成长规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 规则卡片

struct RuleCard: View {
    let icon: String
    let title: String
    let color: Color
    let rules: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rules, id: \.self) { rule in
                    HStack(spacing: 6) {
                        Text("•")
                            .foregroundColor(color)
                        Text(rule)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AttributeRuleCard: View {
    let icon: String
    let name: String
    let color: Color
    let description: String
    let rules: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rules, id: \.self) { rule in
                    HStack(spacing: 6) {
                        Text("•")
                            .foregroundColor(color)
                        Text(rule)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoBox: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
