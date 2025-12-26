//
//  ContentView.swift
//  VitalityPact
//
//  主界面 - 修复版
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @EnvironmentObject var gameState: GameStateManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var showOnboarding = true
    @State private var showDebugPanel = false
    @State private var showCharacterSelection = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // 判断是否需要显示引导页
            if !userSettings.hasCompletedOnboarding {
                OnboardingView(
                    showOnboarding: $showOnboarding,
                    showCharacterSelection: $showCharacterSelection
                )
            } else {
                MainGameView(showDebugPanel: $showDebugPanel, showSettings: $showSettings)
            }
        }
        .sheet(isPresented: $showDebugPanel) {
            DebugPanelView()
        }
        .sheet(isPresented: $showCharacterSelection) {
            CharacterSelectionView(isPresented: $showCharacterSelection)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - 引导页
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Binding var showCharacterSelection: Bool
    @EnvironmentObject var healthManager: HealthStoreManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var demoHealthScore: Double = 30
    @State private var animateDemo = false

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.black, Color.purple.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Logo/Title
                VStack(spacing: 8) {
                    Text("元气契约")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("你的健康伙伴")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // 动态演示区域 - 让用户直观看到角色随健康变化
                VStack(spacing: 15) {
                    // 角色表情随滑块变化
                    Text(demoCharacterEmoji)
                        .font(.system(size: 80))
                        .animation(.spring(), value: demoHealthScore)
                    
                    Text(demoStatusText)
                        .font(.headline)
                        .foregroundColor(demoStatusColor)
                        .animation(.easeInOut, value: demoHealthScore)
                    
                    // 互动滑块
                    VStack(spacing: 5) {
                        Text("试试看：拖动调整健康值")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: $demoHealthScore, in: 0...100, step: 1)
                            .accentColor(.purple)
                            .padding(.horizontal, 40)
                        
                        Text("健康值: \(Int(demoHealthScore))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 20)

                Spacer()

                // 简化的说明文字
                VStack(alignment: .leading, spacing: 12) {
                    SimpleFeatureRow(emoji: "👟", text: "走路越多，角色越有活力")
                    SimpleFeatureRow(emoji: "😴", text: "睡眠充足，角色状态更好")
                    SimpleFeatureRow(emoji: "💪", text: "坚持运动，一起变强")
                }
                .padding(.horizontal, 40)

                Spacer()

                // 授权按钮
                Button {
                    Task {
                        await healthManager.requestAuthorization()
                        if healthManager.isAuthorized {
                            showCharacterSelection = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                        Text("开始使用")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
                .padding(.horizontal, 30)

                // 跳过（演示用）
                Button("演示模式（无需授权）") {
                    healthManager.debugMode = true
                    showCharacterSelection = true
                }
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .padding(.bottom, 10)

                Spacer()
            }
        }
        .onAppear {
            // 自动演示动画
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateDemo = true
            }
        }
    }
    
    // 演示用的角色表情
    var demoCharacterEmoji: String {
        let level = HealthLevel.from(score: Int(demoHealthScore))
        return CharacterType.warrior.characterEmoji(for: level)
    }
    
    var demoStatusText: String {
        let level = HealthLevel.from(score: Int(demoHealthScore))
        return level.displayName
    }
    
    var demoStatusColor: Color {
        let level = HealthLevel.from(score: Int(demoHealthScore))
        return level.color
    }
}

// 简化的功能说明行
struct SimpleFeatureRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - 角色选择页面
struct CharacterSelectionView: View {
    @Binding var isPresented: Bool
    @StateObject private var userSettings = UserSettings.shared
    @EnvironmentObject var healthManager: HealthStoreManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                
                VStack(spacing: 15) {
                    Text("选择你的伙伴")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("TA会陪你一起变得更健康")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(CharacterType.allCases, id: \.self) { type in
                                CharacterCard(
                                    type: type,
                                    isSelected: userSettings.selectedCharacterType == type
                                ) {
                                    userSettings.selectedCharacterType = type
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 选中角色的预览
                    if userSettings.selectedCharacterType != nil {
                        VStack(spacing: 8) {
                            Text("TA会这样陪伴你")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // 显示角色在不同状态下的表情
                            HStack(spacing: 15) {
                                ForEach([HealthLevel.critical, .weak, .normal, .good, .excellent], id: \.self) { level in
                                    VStack(spacing: 4) {
                                        Text(userSettings.selectedCharacterType.characterEmoji(for: level))
                                            .font(.title2)
                                        Text(level.shortName)
                                            .font(.system(size: 9))
                                            .foregroundColor(level.color)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Button {
                        userSettings.hasCompletedOnboarding = true
                        isPresented = false
                    } label: {
                        Text("就选TA了！")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userSettings.selectedCharacterType.themeColor)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct CharacterCard: View {
    let type: CharacterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 显示良好状态的表情
                Text(type.characterEmoji(for: .good))
                    .font(.system(size: 45))
                
                Text(type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(type.shortDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? type.themeColor.opacity(0.3) : Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? type.themeColor : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 主游戏界面
struct MainGameView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @EnvironmentObject var gameState: GameStateManager
    @StateObject private var userSettings = UserSettings.shared
    @ObservedObject var imageCharacterManager = ImageCharacterManager.shared
    @Binding var showDebugPanel: Bool
    @Binding var showSettings: Bool
    @State private var characterScale: CGFloat = 1.0
    @State private var showDialogueBubble = true
    @State private var showCharacterPicker = false
    @State private var showChat = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（根据角色类型和健康等级）
                DynamicBackgroundView(
                    characterType: currentCharacterStyle,
                    healthLevel: healthLevel
                )

                VStack(spacing: 0) {
                    // 顶部状态栏（不含调试按钮，除非是演示模式）
                    TopStatusBar(
                        showDebugPanel: $showDebugPanel,
                        showCharacterPicker: $showCharacterPicker,
                        showSettings: $showSettings,
                        showChat: $showChat,
                        healthLevel: healthLevel
                    )
                    
                    // 伙伴属性面板（迷你版）
                    if let attributes = gameState.currentPartnerAttributes {
                        PartnerStatsMini(attributes: attributes)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    Spacer()

                    // 角色区域（根据选择的角色类型显示）
                    if imageCharacterManager.useImageCharacter,
                       let character = imageCharacterManager.selectedCharacter {
                        ImageCharacterDisplayView(
                            character: character,
                            healthLevel: healthLevel,
                            scale: characterScale
                        )
                        .onTapGesture {
                            handleCharacterTap()
                        }
                    } else {
                        DynamicCharacterView(
                            characterType: userSettings.selectedCharacterType,
                            healthLevel: healthLevel,
                            scale: characterScale
                        )
                        .onTapGesture {
                            handleCharacterTap()
                        }
                    }

                    // 对话气泡
                    if showDialogueBubble {
                        DialogueBubbleView(
                            text: gameState.currentDialogue,
                            isLoading: gameState.isLoadingDialogue,
                            characterType: currentCharacterStyle
                        )
                        .transition(.scale.combined(with: .opacity))
                        .padding(.horizontal)
                    }

                    Spacer()

                    // 底部数据面板
                    DataPanelView(healthLevel: healthLevel)
                }
                .padding(.vertical)

                // 宝箱动画
                if gameState.showChestAnimation {
                    ChestAnimationView()
                }
                
                // 升级动画
                if gameState.showLevelUpAnimation,
                   let levelInfo = gameState.levelUpInfo {
                    LevelUpAnimationView(
                        oldLevel: levelInfo.oldLevel,
                        newLevel: levelInfo.newLevel,
                        isPresented: $gameState.showLevelUpAnimation
                    )
                }
            }
        }
        .sheet(isPresented: $showCharacterPicker) {
            ImageCharacterSelectionView()
        }
        .sheet(isPresented: $showChat) {
            ChatView()
        }
    }
    
    var healthLevel: HealthLevel {
        HealthLevel.from(score: healthManager.healthData.overallScore)
    }
    
    /// 当前角色的对话风格
    var currentCharacterStyle: CharacterType {
        if imageCharacterManager.useImageCharacter,
           let character = imageCharacterManager.selectedCharacter {
            return character.style
        }
        return userSettings.selectedCharacterType
    }
    
    /// 处理角色点击
    func handleCharacterTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            characterScale = 1.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring()) {
                characterScale = 1.0
            }
        }
        gameState.onCharacterTapped()
        showDialogueBubble = true
    }
}

// MARK: - 动态背景视图
struct DynamicBackgroundView: View {
    let characterType: CharacterType
    let healthLevel: HealthLevel

    var body: some View {
        LinearGradient(
            colors: characterType.backgroundColors(for: healthLevel),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: healthLevel)
    }
}

// MARK: - 顶部状态栏
struct TopStatusBar: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @StateObject private var userSettings = UserSettings.shared
    @Binding var showDebugPanel: Bool
    @Binding var showCharacterPicker: Bool
    @Binding var showSettings: Bool
    @Binding var showChat: Bool
    let healthLevel: HealthLevel
    @State private var debugTapCount = 0
    @State private var showHealthHistory = false  // 显示健康历史
    @State private var showCoinInfo = false  // 显示金币获取说明

    var body: some View {
        HStack(spacing: 8) {
            // 金币显示 - 点击查看如何获得金币
            Button {
                showCoinInfo = true
            } label: {
                HStack(spacing: 5) {
                    Text("🪙")
                    Text("\(healthManager.healthData.goldCoins)")
                        .fontWeight(.bold)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
            }
            .buttonStyle(PlainButtonStyle())
            .alert("如何获得金币？", isPresented: $showCoinInfo) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("""
                通过保持健康的生活习惯来赚取金币：
                
                🦶 步数奖励：
                   每走10步 = 1金币
                   （例如：10,000步 = 1,000金币）
                
                😴 睡眠奖励：
                   • ≥8小时：+50金币
                   • 7-8小时：+30金币
                   • 6-7小时：+10金币
                
                🏃 运动奖励：
                   • ≥60分钟：+50金币
                   • 30-60分钟：+30金币
                   • 15-30分钟：+10金币
                
                💰 用途：解锁精美的图片角色
                
                💡 小贴士：全方位保持健康习惯，
                   每天最高可获得1000+金币！
                """)
            }

            Spacer()
            
            // 健康历史按钮
            Button {
                showHealthHistory = true
            } label: {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 15))
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .sheet(isPresented: $showHealthHistory) {
                HealthHistoryView()
            }

            // 聊天按钮
            Button {
                showChat = true
            } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 15))
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)

            // 设置按钮 - 长按开启调试模式
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 2.0)
                    .onEnded { _ in
                        healthManager.debugMode = true
                        // 给用户震动反馈
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
            )

            // 角色切换按钮
            Button {
                showCharacterPicker = true
            } label: {
                Text(userSettings.selectedCharacterType.icon)
                    .font(.system(size: 20))
            }
            .padding(6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // 调试按钮（仅在演示模式下显示）
            if healthManager.debugMode {
                Button {
                    debugTapCount += 1
                    if debugTapCount >= 3 {
                        showDebugPanel = true
                        debugTapCount = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        debugTapCount = 0
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}

// MARK: - 动态角色视图
struct DynamicCharacterView: View {
    let characterType: CharacterType
    let healthLevel: HealthLevel
    var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 光环效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [characterType.themeColor.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)

            // 角色
            VStack(spacing: 10) {
                Text(characterType.characterEmoji(for: healthLevel))
                    .font(.system(size: 100))
                
                // 状态效果
                if let effect = characterType.statusEffect(for: healthLevel) {
                    Text(effect)
                        .font(.title)
                        .offset(x: 40, y: -80)
                }
            }
        }
        .scaleEffect(scale)
        .animation(.easeInOut(duration: 0.3), value: healthLevel)
    }
}

// MARK: - 对话气泡
struct DialogueBubbleView: View {
    let text: String
    let isLoading: Bool
    var characterType: CharacterType = .warrior

    var body: some View {
        VStack {
            if isLoading {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(characterType.themeColor)
                            .frame(width: 8, height: 8)
                            .opacity(0.5)
                    }
                }
                .padding()
            } else {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .foregroundColor(.primary)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: characterType.themeColor.opacity(0.3), radius: 10)
        .frame(maxWidth: 300)
    }
}

// MARK: - 数据面板
struct DataPanelView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @EnvironmentObject var gameState: GameStateManager
    @StateObject private var userSettings = UserSettings.shared
    let healthLevel: HealthLevel

    var body: some View {
        VStack(spacing: 15) {
            // 进度条
            HStack(spacing: 20) {
                DataProgressView(
                    icon: "figure.walk",
                    value: Double(healthManager.healthData.steps),
                    maxValue: 10000,
                    label: "\(healthManager.healthData.steps) 步",
                    color: .blue
                )

                DataProgressView(
                    icon: "bed.double.fill",
                    value: healthManager.healthData.sleepHours,
                    maxValue: 8,
                    label: String(format: "%.1fh", healthManager.healthData.sleepHours),
                    color: healthManager.healthData.hasSleepDebuff ? .red : .purple
                )

                DataProgressView(
                    icon: "flame.fill",
                    value: Double(healthManager.healthData.exerciseMinutes),
                    maxValue: 60,
                    label: "\(healthManager.healthData.exerciseMinutes) 分钟",
                    color: .orange
                )
            }
            .padding(.horizontal)

            // 综合评分和奖励按钮
            HStack {
                // 健康指数
                HStack(spacing: 4) {
                    Text("健康指数")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(healthManager.healthData.overallScore)")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(healthLevel.color)
                        .shadow(color: healthLevel.color.opacity(0.3), radius: 2, x: 0, y: 1)
                    Text("/ 100")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(healthLevel.color.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // 查看奖励按钮
                Button {
                    gameState.showReward()
                } label: {
                    HStack(spacing: 4) {
                        Text(rewardIcon)
                        Text("查看奖励")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(healthLevel.color.opacity(0.2))
                    .cornerRadius(15)
                }
                .foregroundColor(healthLevel.color)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    var rewardIcon: String {
        userSettings.getReward(for: healthLevel).icon
    }
}

struct DataProgressView: View {
    let icon: String
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color

    var progress: Double {
        min(1.0, value / maxValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)

            // 圆形进度条
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(color)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 奖励动画视图（根据状态显示不同奖励）
struct RewardAnimationView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @EnvironmentObject var gameState: GameStateManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var healthLevel: HealthLevel {
        HealthLevel.from(score: healthManager.healthData.overallScore)
    }
    
    var reward: (icon: String, text: String) {
        userSettings.getReward(for: healthLevel)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    gameState.showChestAnimation = false
                }

            VStack(spacing: 15) {
                // 根据状态显示不同图标
                Text(reward.icon)
                    .font(.system(size: 80))
                    .scaleEffect(scale)

                Text(rewardTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary) // 自动适应深浅模式

                Text(reward.text)
                    .font(.body)
                    .foregroundColor(.secondary) // 使用系统次要颜色
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // 状态标签
                HStack {
                    Circle()
                        .fill(healthLevel.color)
                        .frame(width: 10, height: 10)
                    Text("当前状态: \(healthLevel.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                Button("知道了") {
                    withAnimation {
                        gameState.showChestAnimation = false
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(healthLevel.color)
                .cornerRadius(25)
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    var rewardTitle: String {
        switch healthLevel {
        case .critical: return "需要休息了"
        case .weak: return "温馨提示"
        case .normal: return "继续加油"
        case .good: return "做得很好！"
        case .excellent: return "太棒了！🎉"
        }
    }
}

// 保留旧的 ChestAnimationView 作为兼容
struct ChestAnimationView: View {
    var body: some View {
        RewardAnimationView()
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 奖励设置
                Section {
                    NavigationLink {
                        UserRewardSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("自定义奖励")
                        }
                    }
                } header: {
                    Text("个性化")
                } footer: {
                    Text("为每种健康状态设置专属的奖励内容和图标")
                }
                
                // 角色管理
                Section {
                    NavigationLink {
                        ImageCharacterSelectionView()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                            Text("选择伙伴")
                            Spacer()
                            Text(currentPartnerName)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("伙伴")
                } footer: {
                    Text("选择 Emoji 角色或精美图片角色作为你的健康伙伴。所有伙伴都配备了 AI 智能对话，会根据你的健康数据生成个性化的陪伴语句。")
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("AI 模型")
                        Spacer()
                        Text("Qwen2.5-7B")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("设置")
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
    
    var currentPartnerName: String {
        if ImageCharacterManager.shared.useImageCharacter,
           let character = ImageCharacterManager.shared.selectedCharacter {
            return character.name
        }
        return userSettings.selectedCharacterType.displayName
    }
}
struct UserRewardSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var editingRewards: [HealthLevel: String] = [:]
    @State private var editingIcons: [HealthLevel: String] = [:]
    @State private var selectedLevel: HealthLevel? = nil
    @State private var showIconPicker = false
    @State private var showImagePicker = false
    
    var body: some View {
        Form {
            Section {
                Text("为每种健康状态设置专属的奖励。当你达到对应的健康等级时，会显示相应的奖励提示。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(HealthLevel.allCases, id: \.self) { level in
                Section {
                    // 状态预览
                    HStack {
                        Circle()
                            .fill(level.color)
                            .frame(width: 12, height: 12)
                        Text(level.displayName)
                            .font(.headline)
                        Spacer()
                        Text(healthRangeText(for: level))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 图标选择
                    HStack {
                        Text("奖励图标")
                        Spacer()
                        Button {
                            selectedLevel = level
                            showIconPicker = true
                        } label: {
                            HStack {
                                Text(editingIcons[level] ?? userSettings.rewardIcons[level] ?? "🎁")
                                    .font(.title)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 奖励内容
                    VStack(alignment: .leading, spacing: 8) {
                        Text("奖励内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入奖励内容", text: rewardBinding(for: level))
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Button("恢复默认设置") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("自定义奖励")
        .onAppear {
            editingRewards = userSettings.rewardContents
            editingIcons = userSettings.rewardIcons
        }
        .onDisappear {
            userSettings.rewardContents = editingRewards
            userSettings.rewardIcons = editingIcons
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(
                selectedIcon: iconBinding(for: selectedLevel ?? .good),
                onDismiss: { showIconPicker = false }
            )
        }
    }
    
    func healthRangeText(for level: HealthLevel) -> String {
        switch level {
        case .critical: return "0-20分"
        case .weak: return "21-40分"
        case .normal: return "41-60分"
        case .good: return "61-80分"
        case .excellent: return "81-100分"
        }
    }
    
    func rewardBinding(for level: HealthLevel) -> Binding<String> {
        Binding(
            get: { editingRewards[level] ?? "" },
            set: { editingRewards[level] = $0 }
        )
    }
    
    func iconBinding(for level: HealthLevel) -> Binding<String> {
        Binding(
            get: { editingIcons[level] ?? "🎁" },
            set: { editingIcons[level] = $0 }
        )
    }
    
    func resetToDefaults() {
        editingRewards = [
            .critical: "好好休息一下吧",
            .weak: "喝杯热水，放松一下",
            .normal: "继续保持，你很棒",
            .good: "奖励自己一杯奶茶",
            .excellent: "太棒了！给自己一个大大的奖励"
        ]
        editingIcons = [
            .critical: "💤",
            .weak: "🤗",
            .normal: "⭐",
            .good: "🎁",
            .excellent: "🏆"
        ]
    }
}

// MARK: - 图标选择器（支持emoji和图片）
struct IconPickerView: View {
    @Binding var selectedIcon: String
    let onDismiss: () -> Void
    @State private var customEmoji: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    // 分类的 emoji
    let emojiCategories: [(name: String, emojis: [String])] = [
        ("奖励", ["🎁", "🏆", "🥇", "🥈", "🥉", "🎖️", "🏅", "🎀", "💎", "👑"]),
        ("食物", ["☕", "🧋", "🍰", "🍕", "🍦", "🍩", "🍫", "🍪", "🎂", "🍿"]),
        ("休闲", ["🎮", "📚", "🎬", "🎵", "🎨", "🎭", "🎪", "🎯", "🎲", "🎻"]),
        ("健康", ["💪", "🏃", "🧘", "🏋️", "🚴", "⚽", "🎾", "🏊", "💃", "🕺"]),
        ("心情", ["😊", "🥳", "😴", "💤", "🤗", "😌", "🥰", "😎", "🌟", "✨"]),
        ("自然", ["🌸", "🌺", "🌻", "🌈", "☀️", "🌙", "⭐", "🔥", "❤️", "💖"]),
        ("动物", ["🐱", "🐶", "🐰", "🐼", "🦊", "🦋", "🐳", "🦄", "🐣", "🦁"])
    ]
    
    let columns = [GridItem(.adaptive(minimum: 45))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前选中
                    VStack(spacing: 8) {
                        Text(selectedIcon)
                            .font(.system(size: 60))
                        Text("当前图标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 自定义输入
                    VStack(alignment: .leading, spacing: 10) {
                        Text("自定义输入")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            TextField("输入任意 emoji", text: $customEmoji)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("使用") {
                                if !customEmoji.isEmpty {
                                    // 获取第一个emoji字符
                                    if let firstEmoji = customEmoji.first {
                                        selectedIcon = String(firstEmoji)
                                    }
                                    customEmoji = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(customEmoji.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 分类选择
                    ForEach(emojiCategories, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.name)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(category.emojis, id: \.self) { emoji in
                                    Button {
                                        selectedIcon = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 45, height: 45)
                                            .background(selectedIcon == emoji ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthStoreManager.shared)
        .environmentObject(GameStateManager.shared)
}
