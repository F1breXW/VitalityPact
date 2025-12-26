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
                
                // 金币和角色管理（调试用）
                if healthManager.debugMode {
                    Section("金币管理") {
                        VStack(alignment: .leading) {
                            Text("金币数量: \(healthManager.healthData.goldCoins)")
                                .font(.headline)
                            
                            Stepper(value: $healthManager.healthData.goldCoins, in: 0...99999, step: 100) {
                                Text("调整金币")
                            }
                            
                            HStack {
                                Button("设为 500") {
                                    healthManager.healthData.goldCoins = 500
                                }
                                .buttonStyle(.bordered)
                                
                                Button("设为 1000") {
                                    healthManager.healthData.goldCoins = 1000
                                }
                                .buttonStyle(.bordered)
                                
                                Button("设为 5000") {
                                    healthManager.healthData.goldCoins = 5000
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    Section("角色管理") {
                        Button("🔓 解锁所有图片角色") {
                            ImageCharacterManager.shared.unlockAllCharacters()
                        }
                        .foregroundColor(.blue)
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
                
                // 伙伴成长系统管理
                Section("伙伴成长系统") {
                    if let attributes = gameState.currentPartnerAttributes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当前伙伴属性")
                                .font(.headline)
                            
                            HStack {
                                Text("等级")
                                Spacer()
                                Text("LV.\(attributes.level)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("经验值")
                                Spacer()
                                Text("\(attributes.experience)/\(attributes.experienceToNextLevel)")
                            }
                            
                            HStack {
                                Text("战力")
                                Spacer()
                                Text("\(attributes.totalPower)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("活跃天数")
                                Spacer()
                                Text("\(attributes.totalDaysActive)天")
                            }
                        }
                    }
                    
                    Button("手动触发今日奖励计算") {
                        gameState.processDailyRewards()
                    }
                    
                    NavigationLink("编辑伙伴属性") {
                        PartnerAttributeEditor()
                    }
                    
                    Button("重置所有伙伴属性", role: .destructive) {
                        PartnerAttributesManager.shared.resetAllPartners()
                        gameState.loadCurrentPartnerAttributes()
                    }
                }
                
                // 历史数据管理
                Section("健康历史数据") {
                    let recentRecords = HealthHistoryManager.shared.getRecentRecords(days: 7)
                    
                    if !recentRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近7天记录")
                                .font(.headline)
                            
                            ForEach(recentRecords.prefix(3)) { record in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatDate(record.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Text("步数:\(record.steps)")
                                        Text("睡眠:\(String(format: "%.1f", record.sleepHours))h")
                                        Text("运动:\(record.exerciseMinutes)min")
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("暂无历史记录")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("查看历史数据分析") {
                        let analysis = HealthHistoryManager.shared.analyzeRecent(days: 7)
                        print("=== 健康历史分析 ===")
                        print(analysis.generateSummaryText())
                    }
                    
                    NavigationLink("加载预设历史记录") {
                        HistoryPresetsView()
                    }
                    
                    Button("清空所有历史记录", role: .destructive) {
                        HealthHistoryManager.shared.clearAllRecords()
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
    
    /// 格式化日期
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
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

// MARK: - 伙伴属性编辑器

struct PartnerAttributeEditor: View {
    @EnvironmentObject var gameState: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var level: Double = 1
    @State private var experience: Double = 0
    @State private var strength: Double = 10
    @State private var vitality: Double = 10
    @State private var agility: Double = 10
    @State private var wisdom: Double = 10
    
    var body: some View {
        Form {
            Section("基础属性") {
                VStack(alignment: .leading) {
                    Text("等级: \(Int(level))")
                        .font(.headline)
                    Slider(value: $level, in: 1...100, step: 1)
                }
                
                VStack(alignment: .leading) {
                    Text("经验值: \(Int(experience))")
                        .font(.headline)
                    Slider(value: $experience, in: 0...10000, step: 10)
                }
            }
            
            Section("四维属性") {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.red)
                        Text("力量: \(Int(strength))")
                            .font(.headline)
                    }
                    Slider(value: $strength, in: 1...200, step: 1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.green)
                        Text("体质: \(Int(vitality))")
                            .font(.headline)
                    }
                    Slider(value: $vitality, in: 1...200, step: 1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundColor(.orange)
                        Text("敏捷: \(Int(agility))")
                            .font(.headline)
                    }
                    Slider(value: $agility, in: 1...200, step: 1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("智慧: \(Int(wisdom))")
                            .font(.headline)
                    }
                    Slider(value: $wisdom, in: 1...200, step: 1)
                }
            }
            
            Section {
                Button("应用修改") {
                    applyChanges()
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("编辑伙伴属性")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentAttributes()
        }
    }
    
    private func loadCurrentAttributes() {
        if let attributes = gameState.currentPartnerAttributes {
            level = Double(attributes.level)
            experience = Double(attributes.experience)
            strength = Double(attributes.strength)
            vitality = Double(attributes.vitality)
            agility = Double(attributes.agility)
            wisdom = Double(attributes.wisdom)
        }
    }
    
    private func applyChanges() {
        guard var attributes = gameState.currentPartnerAttributes else { return }
        
        attributes.level = Int(level)
        attributes.experience = Int(experience)
        attributes.strength = Int(strength)
        attributes.vitality = Int(vitality)
        attributes.agility = Int(agility)
        attributes.wisdom = Int(wisdom)
        
        PartnerAttributesManager.shared.updateAttributes(attributes)
        gameState.loadCurrentPartnerAttributes()
    }
}

// MARK: - 历史记录预设视图

struct HistoryPresetsView: View {
    @EnvironmentObject var gameState: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("睡眠相关预设") {
                PresetButton(
                    title: "😴 连续睡眠不足",
                    description: "连续7天睡眠<6小时",
                    color: .red
                ) {
                    loadPreset(.lackOfSleep)
                }
                
                PresetButton(
                    title: "😪 间歇性睡眠不足",
                    description: "7天中有4天睡眠<6小时",
                    color: .orange
                ) {
                    loadPreset(.intermittentSleepIssues)
                }
                
                PresetButton(
                    title: "😊 睡眠改善中",
                    description: "从睡眠不足逐渐改善",
                    color: .green
                ) {
                    loadPreset(.sleepImproving)
                }
                
                PresetButton(
                    title: "🌙 完美睡眠",
                    description: "连续7天睡眠≥8小时",
                    color: .blue
                ) {
                    loadPreset(.perfectSleep)
                }
            }
            
            Section("步数相关预设") {
                PresetButton(
                    title: "🚶 连续步数不足",
                    description: "连续7天步数<5000",
                    color: .red
                ) {
                    loadPreset(.lackOfSteps)
                }
                
                PresetButton(
                    title: "🏃 步数逐渐增加",
                    description: "步数呈上升趋势",
                    color: .green
                ) {
                    loadPreset(.stepsImproving)
                }
                
                PresetButton(
                    title: "💪 完美运动",
                    description: "连续7天步数≥10000",
                    color: .blue
                ) {
                    loadPreset(.perfectSteps)
                }
            }
            
            Section("综合状态预设") {
                PresetButton(
                    title: "😰 全面低迷",
                    description: "睡眠、步数、运动都不足",
                    color: .red
                ) {
                    loadPreset(.allPoor)
                }
                
                PresetButton(
                    title: "📈 全面改善",
                    description: "各项数据都在改善",
                    color: .green
                ) {
                    loadPreset(.allImproving)
                }
                
                PresetButton(
                    title: "⭐️ 完美状态",
                    description: "所有指标都达标",
                    color: .blue
                ) {
                    loadPreset(.allPerfect)
                }
                
                PresetButton(
                    title: "📉 状态下滑",
                    description: "从好状态逐渐下滑",
                    color: .orange
                ) {
                    loadPreset(.declining)
                }
            }
        }
        .navigationTitle("历史记录预设")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadPreset(_ preset: HistoryPreset) {
        let records = preset.generateRecords()
        HealthHistoryManager.shared.clearAllRecords()
        
        for record in records {
            // 直接插入历史记录
            HealthHistoryManager.shared.insertRecord(record)
        }
        
        // 重新生成对话
        gameState.generateDialogue(for: HealthStoreManager.shared.healthData)
        
        dismiss()
    }
}

struct PresetButton: View {
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 历史记录预设数据

enum HistoryPreset {
    case lackOfSleep          // 连续睡眠不足
    case intermittentSleepIssues  // 间歇性睡眠不足
    case sleepImproving       // 睡眠改善中
    case perfectSleep         // 完美睡眠
    case lackOfSteps          // 连续步数不足
    case stepsImproving       // 步数改善中
    case perfectSteps         // 完美步数
    case allPoor              // 全面低迷
    case allImproving         // 全面改善
    case allPerfect           // 完美状态
    case declining            // 状态下滑
    
    func generateRecords() -> [DailyHealthRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var records: [DailyHealthRecord] = []
        
        for i in (0...6).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let record: DailyHealthRecord
            
            switch self {
            case .lackOfSleep:
                record = DailyHealthRecord(
                    date: date,
                    steps: 7000 + Int.random(in: -1000...1000),
                    sleepHours: Double.random(in: 4.0...5.5),
                    exerciseMinutes: 20 + Int.random(in: -5...10),
                    overallScore: 40 + Int.random(in: -10...10)
                )
                
            case .intermittentSleepIssues:
                let sleep = [4.5, 7.5, 5.0, 8.0, 5.5, 7.0, 5.5][6-i]
                record = DailyHealthRecord(
                    date: date,
                    steps: 7000 + Int.random(in: -1000...1000),
                    sleepHours: sleep,
                    exerciseMinutes: 25,
                    overallScore: Int((sleep / 8.0) * 50) + 30
                )
                
            case .sleepImproving:
                let sleep = 5.0 + Double(i) * 0.5
                record = DailyHealthRecord(
                    date: date,
                    steps: 8000,
                    sleepHours: sleep,
                    exerciseMinutes: 30,
                    overallScore: 50 + i * 5
                )
                
            case .perfectSleep:
                record = DailyHealthRecord(
                    date: date,
                    steps: 9000 + Int.random(in: -500...1000),
                    sleepHours: Double.random(in: 8.0...9.0),
                    exerciseMinutes: 40 + Int.random(in: -5...15),
                    overallScore: 85 + Int.random(in: -5...10)
                )
                
            case .lackOfSteps:
                record = DailyHealthRecord(
                    date: date,
                    steps: Int.random(in: 2000...4500),
                    sleepHours: 7.0,
                    exerciseMinutes: 15,
                    overallScore: 35 + Int.random(in: -5...10)
                )
                
            case .stepsImproving:
                record = DailyHealthRecord(
                    date: date,
                    steps: 5000 + i * 800,
                    sleepHours: 7.0,
                    exerciseMinutes: 25 + i * 5,
                    overallScore: 50 + i * 6
                )
                
            case .perfectSteps:
                record = DailyHealthRecord(
                    date: date,
                    steps: 10000 + Int.random(in: 0...3000),
                    sleepHours: 7.5,
                    exerciseMinutes: 50 + Int.random(in: -10...15),
                    overallScore: 90 + Int.random(in: -5...10)
                )
                
            case .allPoor:
                record = DailyHealthRecord(
                    date: date,
                    steps: Int.random(in: 1500...3000),
                    sleepHours: Double.random(in: 4.0...5.5),
                    exerciseMinutes: Int.random(in: 5...15),
                    overallScore: Int.random(in: 20...35)
                )
                
            case .allImproving:
                record = DailyHealthRecord(
                    date: date,
                    steps: 4000 + i * 900,
                    sleepHours: 5.5 + Double(i) * 0.4,
                    exerciseMinutes: 15 + i * 6,
                    overallScore: 40 + i * 8
                )
                
            case .allPerfect:
                record = DailyHealthRecord(
                    date: date,
                    steps: 10000 + Int.random(in: 0...2000),
                    sleepHours: Double.random(in: 8.0...9.0),
                    exerciseMinutes: 50 + Int.random(in: -5...20),
                    overallScore: 90 + Int.random(in: -2...8)
                )
                
            case .declining:
                record = DailyHealthRecord(
                    date: date,
                    steps: 10000 - i * 1000,
                    sleepHours: 8.5 - Double(i) * 0.5,
                    exerciseMinutes: 60 - i * 8,
                    overallScore: 90 - i * 10
                )
            }
            
            records.append(record)
        }
        
        return records
    }
}

#Preview {
    DebugPanelView()
        .environmentObject(HealthStoreManager.shared)
        .environmentObject(GameStateManager.shared)
}
