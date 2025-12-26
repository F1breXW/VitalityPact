//
//  DebugPanelView.swift
//  VitalityPact
//
//  调试控制台 (God Mode) - 用于演示
//

import SwiftUI

struct DebugPanelView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @EnvironmentObject var gameState: GameStateManager
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                // 调试模式开关
                Section {
                    Toggle("启用调试模式", isOn: $healthManager.debugMode)
                        .onChange(of: healthManager.debugMode) { oldValue, newValue in
                            if newValue {
                                healthManager.updateDebugData()
                            } else {
                                // 关闭调试模式时显示确认对话框
                                showExitConfirmation = true
                            }
                        }
                } header: {
                    Text("God Mode")
                } footer: {
                    Text("关闭调试模式将重置到初始页面")
                }

                // 数据调节滑杆
                if healthManager.debugMode {
                    Section("步数调节") {
                        VStack(alignment: .leading) {
                            Text("今日步数: \(Int(healthManager.debugSteps)) 步")
                                .font(.headline)

                            Slider(
                                value: $healthManager.debugSteps,
                                in: 0...15000,
                                step: 100
                            )
                            .onChange(of: healthManager.debugSteps) { oldValue, newValue in
                                healthManager.updateDebugData()
                                gameState.updateGameState(from: healthManager.healthData)
                            }

                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("15000")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        // 快捷按钮
                        HStack {
                            QuickSetButton(title: "0", value: 0) {
                                healthManager.debugSteps = 0
                                updateAll()
                            }
                            QuickSetButton(title: "2K", value: 2000) {
                                healthManager.debugSteps = 2000
                                updateAll()
                            }
                            QuickSetButton(title: "6K", value: 6000) {
                                healthManager.debugSteps = 6000
                                updateAll()
                            }
                            QuickSetButton(title: "10K", value: 10000) {
                                healthManager.debugSteps = 10000
                                updateAll()
                            }
                        }
                    }

                    Section("睡眠调节") {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("昨晚睡眠: \(String(format: "%.1f", healthManager.debugSleepHours)) 小时")
                                    .font(.headline)

                                if healthManager.debugSleepHours < 6 {
                                    Text("⚠️ 不足")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            Slider(
                                value: $healthManager.debugSleepHours,
                                in: 0...12,
                                step: 0.5
                            )
                            .onChange(of: healthManager.debugSleepHours) { oldValue, newValue in
                                healthManager.updateDebugData()
                                gameState.updateGameState(from: healthManager.healthData)
                            }

                            HStack {
                                Text("0h")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("12h")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        // 快捷按钮
                        HStack {
                            QuickSetButton(title: "3h", value: 3) {
                                healthManager.debugSleepHours = 3
                                updateAll()
                            }
                            QuickSetButton(title: "5h", value: 5) {
                                healthManager.debugSleepHours = 5
                                updateAll()
                            }
                            QuickSetButton(title: "7h", value: 7) {
                                healthManager.debugSleepHours = 7
                                updateAll()
                            }
                            QuickSetButton(title: "8h", value: 8) {
                                healthManager.debugSleepHours = 8
                                updateAll()
                            }
                        }
                    }

                    Section("运动时长") {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("今日运动: \(Int(healthManager.debugExerciseMinutes)) 分钟")
                                    .font(.headline)

                                if healthManager.debugExerciseMinutes >= 30 {
                                    Text("✅ 达标")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            Slider(
                                value: $healthManager.debugExerciseMinutes,
                                in: 0...120,
                                step: 5
                            )
                            .onChange(of: healthManager.debugExerciseMinutes) { oldValue, newValue in
                                healthManager.updateDebugData()
                                gameState.updateGameState(from: healthManager.healthData)
                            }
                        }

                        // 快捷按钮
                        HStack {
                            QuickSetButton(title: "0min", value: 0) {
                                healthManager.debugExerciseMinutes = 0
                                updateAll()
                            }
                            QuickSetButton(title: "15min", value: 15) {
                                healthManager.debugExerciseMinutes = 15
                                updateAll()
                            }
                            QuickSetButton(title: "30min", value: 30) {
                                healthManager.debugExerciseMinutes = 30
                                updateAll()
                            }
                            QuickSetButton(title: "60min", value: 60) {
                                healthManager.debugExerciseMinutes = 60
                                updateAll()
                            }
                        }
                    }

                    Section("心率") {
                        VStack(alignment: .leading) {
                            Text("当前心率: \(Int(healthManager.debugHeartRate)) BPM")
                                .font(.headline)

                            Slider(
                                value: $healthManager.debugHeartRate,
                                in: 50...150,
                                step: 1
                            )
                            .onChange(of: healthManager.debugHeartRate) { oldValue, newValue in
                                healthManager.updateDebugData()
                                gameState.updateGameState(from: healthManager.healthData)
                            }
                        }
                    }
                }

                // 当前状态预览
                Section("当前状态") {
                    HStack {
                        Text("健康等级")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(currentHealthLevel.color)
                                .frame(width: 10, height: 10)
                            Text(currentHealthLevel.displayName)
                                .fontWeight(.bold)
                                .foregroundColor(currentHealthLevel.color)
                        }
                    }

                    HStack {
                        Text("金币")
                        Spacer()
                        Text("🪙 \(healthManager.healthData.goldCoins)")
                    }

                    HStack {
                        Text("综合分数")
                        Spacer()
                        Text("\(healthManager.healthData.overallScore) / 100")
                    }

                    HStack {
                        Text("睡眠状态")
                        Spacer()
                        Text(healthManager.healthData.hasSleepDebuff ? "⚠️ 睡眠不足" : "✅ 睡眠充足")
                    }

                    HStack {
                        Text("当前奖励")
                        Spacer()
                        Text("\(currentReward.icon) \(currentReward.text)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                // 演示场景
                Section("演示场景预设") {
                    Button("🔴 危险状态 (0-20分)") {
                        // 步数500=5分, 睡眠3h=0分, 运动0=0分, 平均≈1.6分
                        setScenario(steps: 500, sleep: 3, exercise: 0)
                    }
                    .foregroundColor(.red)

                    Button("🟠 虚弱状态 (21-40分)") {
                        // 步数3000=30分, 睡眠5h=40分, 运动10min=16分, 平均≈28分
                        setScenario(steps: 3000, sleep: 5, exercise: 10)
                    }
                    .foregroundColor(.orange)

                    Button("🟡 普通状态 (41-60分)") {
                        // 步数5000=50分, 睡眠6h=60分, 运动20min=33分, 平均≈47分
                        setScenario(steps: 5000, sleep: 6, exercise: 20)
                    }
                    .foregroundColor(.yellow)

                    Button("🟢 良好状态 (61-80分)") {
                        // 步数7000=70分, 睡眠7h=80分, 运动35min=58分, 平均≈69分
                        setScenario(steps: 7000, sleep: 7, exercise: 35)
                    }
                    .foregroundColor(.green)

                    Button("🔵 极佳状态 (81-100分)") {
                        // 步数10000=100分, 睡眠8h=100分, 运动60min=100分, 平均=100分
                        setScenario(steps: 10000, sleep: 8, exercise: 60)
                    }
                    .foregroundColor(.cyan)
                }
                
                // 奖励设置
                Section("奖励设置") {
                    NavigationLink("自定义奖励内容") {
                        RewardSettingsView()
                    }
                }

                // 手动操作
                Section("手动操作") {
                    Button("刷新数据") {
                        Task {
                            await healthManager.fetchAllData()
                            gameState.updateGameState(from: healthManager.healthData)
                        }
                    }

                    Button("生成新对话") {
                        gameState.generateDialogue(for: healthManager.healthData)
                    }

                    Button("查看当前状态奖励") {
                        gameState.showReward()
                    }
                }
            }
            .navigationTitle("控制台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("退出调试模式", isPresented: $showExitConfirmation) {
                Button("取消", role: .cancel) {
                    // 恢复调试模式
                    healthManager.debugMode = true
                }
                Button("确认退出", role: .destructive) {
                    exitDebugMode()
                }
            } message: {
                Text("退出调试模式后将返回初始页面，你可以重新选择授权真实数据或再次进入调试模式。")
            }
        }
    }

    var stateColor: Color {
        switch gameState.characterState {
        case .tired: return .red
        case .healthy: return .green
        case .excited: return .orange
        }
    }
    
    var currentHealthLevel: HealthLevel {
        HealthLevel.from(score: healthManager.healthData.overallScore)
    }
    
    var currentReward: (icon: String, text: String) {
        userSettings.getReward(for: currentHealthLevel)
    }
    
    /// 退出调试模式，重置到初始状态
    func exitDebugMode() {
        healthManager.debugMode = false
        userSettings.resetToInitialState()
        dismiss()
    }

    func updateAll() {
        healthManager.updateDebugData()
        gameState.updateGameState(from: healthManager.healthData)
    }

    func setScenario(steps: Double, sleep: Double, exercise: Double) {
        healthManager.debugMode = true
        healthManager.debugSteps = steps
        healthManager.debugSleepHours = sleep
        healthManager.debugExerciseMinutes = exercise
        updateAll()
        gameState.generateDialogue(for: healthManager.healthData)
    }
}

// MARK: - 奖励设置页面
struct RewardSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var editingRewards: [HealthLevel: String] = [:]
    @State private var editingIcons: [HealthLevel: String] = [:]
    @State private var selectedLevel: HealthLevel? = nil
    @State private var showEmojiPicker = false
    
    // 常用 emoji 供用户快速选择
    let suggestedEmojis = ["💤", "🤗", "⭐", "🎁", "🏆", "☕", "🧋", "🍰", "🎮", "📚", "🎬", "🏃", "💪", "🌟", "❤️", "🔥", "✨", "🌈", "🎉", "👏", "😊", "🥳", "🍕", "🍦", "🎂", "🌸", "🐱", "🐶", "🦋", "🌺"]
    
    var body: some View {
        Form {
            Section {
                Text("为每种健康状态设置专属的奖励图标和内容。点击图标可以更换。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("各状态的奖励设置") {
                ForEach(HealthLevel.allCases, id: \.self) { level in
                    VStack(alignment: .leading, spacing: 10) {
                        // 状态标题
                        HStack {
                            Circle()
                                .fill(level.color)
                                .frame(width: 10, height: 10)
                            Text(level.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 12) {
                            // 图标按钮（点击选择emoji）
                            Button {
                                selectedLevel = level
                                showEmojiPicker = true
                            } label: {
                                Text(editingIcons[level] ?? userSettings.rewardIcons[level] ?? "🎁")
                                    .font(.system(size: 35))
                                    .frame(width: 55, height: 55)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(12)
                            }
                            
                            // 奖励内容输入
                            TextField("输入奖励内容", text: binding(for: level))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            
            Section {
                Button("恢复默认设置") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("奖励设置")
        .onAppear {
            editingRewards = userSettings.rewardContents
            editingIcons = userSettings.rewardIcons
        }
        .onDisappear {
            userSettings.rewardContents = editingRewards
            userSettings.rewardIcons = editingIcons
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(
                selectedEmoji: iconBinding(for: selectedLevel ?? .good),
                suggestedEmojis: suggestedEmojis,
                onDismiss: { showEmojiPicker = false }
            )
        }
    }
    
    func binding(for level: HealthLevel) -> Binding<String> {
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

// MARK: - Emoji 选择器
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let suggestedEmojis: [String]
    let onDismiss: () -> Void
    @State private var customEmoji: String = ""
    
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 当前选中
                VStack(spacing: 8) {
                    Text(selectedEmoji)
                        .font(.system(size: 60))
                    Text("当前图标")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // 快速选择区
                VStack(alignment: .leading, spacing: 10) {
                    Text("快速选择")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(suggestedEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
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
                                selectedEmoji = String(customEmoji.prefix(2)) // 取前2个字符（一个emoji可能占2个字符）
                                customEmoji = ""
                            }
                        }
                        .disabled(customEmoji.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    Text("提示：可以从键盘的 emoji 面板选择任意表情")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
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

struct QuickSetButton: View {
    let title: String
    let value: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DebugPanelView()
        .environmentObject(HealthStoreManager.shared)
        .environmentObject(GameStateManager.shared)
}
