//
//  HealthHistoryView.swift
//  VitalityPact
//
//  用户历史健康数据查看页面 - 包含详细数据和AI分析
//

import SwiftUI

struct HealthHistoryView: View {
    @EnvironmentObject var gameState: GameStateManager
    @State private var selectedDays: Int = 7  // 查看天数
    @State private var aiAnalysis: String = ""
    @State private var isLoadingAnalysis: Bool = false
    @State private var showDetailedStats: Bool = true  // 默认展开详细数据
    
    private let daysOptions = [7, 14, 30, 90]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 天数选择器
                    daysPicker
                    
                    // 总览统计卡片
                    overviewCard
                    
                    // 详细数据列表（每日数据）
                    detailedDataSection
                    
                    // 趋势分析卡片
                    trendAnalysisCard
                    
                    // AI 深度分析（放在最后）
                    aiAnalysisCard
                }
                .padding()
            }
            .navigationTitle("健康历史")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAIAnalysis()
            }
        }
    }
    
    // MARK: - 天数选择器
    private var daysPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("查看周期")
                .font(.headline)
            
            Picker("Days", selection: $selectedDays) {
                ForEach(daysOptions, id: \.self) { days in
                    Text("\(days)天").tag(days)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedDays) { _ in
                loadAIAnalysis()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 总览统计卡片
    private var overviewCard: some View {
        let records = gameState.healthHistory.getRecentRecords(days: selectedDays)
        
        // 拆分复杂表达式避免编译器超时
        let totalSleep = records.map { $0.sleepHours }.reduce(0, +)
        let avgSleep = records.isEmpty ? 0 : totalSleep / Double(records.count)
        
        let totalSteps = records.map { Double($0.steps) }.reduce(0, +)
        let avgSteps = records.isEmpty ? 0 : Int(totalSteps / Double(records.count))
        
        let totalExercise = records.map { Double($0.exerciseMinutes) }.reduce(0, +)
        let avgExercise = records.isEmpty ? 0 : Int(totalExercise / Double(records.count))
        
        let totalScore = records.map { Double($0.overallScore) }.reduce(0, +)
        let avgScore = records.isEmpty ? 0 : Int(totalScore / Double(records.count))
        
        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("📊 数据总览")
                    .font(.headline)
                Spacer()
                Text("近\(selectedDays)天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatBox(icon: "💤", title: "平均睡眠", value: String(format: "%.1f小时", avgSleep))
                StatBox(icon: "👣", title: "平均步数", value: "\(avgSteps)步")
                StatBox(icon: "🏃", title: "平均运动", value: "\(avgExercise)分钟")
                StatBox(icon: "❤️", title: "平均健康分", value: "\(avgScore)分")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - AI深度分析卡片
    private var aiAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("🤖 AI 健康分析")
                    .font(.headline)
                Spacer()
                if isLoadingAnalysis {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: loadAIAnalysis) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if aiAnalysis.isEmpty && !isLoadingAnalysis {
                Text("点击刷新按钮获取AI分析...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Text(aiAnalysis)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 详细数据列表
    private var detailedDataSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { showDetailedStats.toggle() }) {
                HStack {
                    Text("📋 详细数据记录")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showDetailedStats ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showDetailedStats {
                let records = gameState.healthHistory.getRecentRecords(days: selectedDays)
                ForEach(records.reversed()) { record in
                    DailyRecordCard(record: record)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 趋势分析卡片
    private var trendAnalysisCard: some View {
        let analysis = gameState.healthHistory.analyzeRecent(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 15) {
            Text("📈 趋势分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                TrendRow(title: "睡眠趋势", trend: analysis.sleepTrend)
                TrendRow(title: "步数趋势", trend: analysis.stepsTrend)
                TrendRow(title: "运动趋势", trend: analysis.exerciseTrend)
                
                if analysis.consecutiveLowSleepDays > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("连续\(analysis.consecutiveLowSleepDays)天睡眠不足")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                if analysis.consecutiveLowStepsDays > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("连续\(analysis.consecutiveLowStepsDays)天步数不足")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 加载AI分析
    private func loadAIAnalysis() {
        isLoadingAnalysis = true
        aiAnalysis = ""
        
        Task {
            let analysis = await generateDetailedAIAnalysis()
            await MainActor.run {
                aiAnalysis = analysis
                isLoadingAnalysis = false
            }
        }
    }
    
    private func generateDetailedAIAnalysis() async -> String {
        let records = gameState.healthHistory.getRecentRecords(days: selectedDays)
        guard !records.isEmpty else {
            return "暂无足够的健康数据进行分析。"
        }
        
        let analysis = gameState.healthHistory.analyzeRecent(days: selectedDays)
        let characterType = UserSettings.shared.selectedCharacterType
        
        // 构建详细的分析prompt
        let prompt = buildAnalysisPrompt(records: records, analysis: analysis)
        
        do {
            return try await AIService.shared.callDetailedAnalysisAPI(
                prompt: prompt,
                characterType: characterType
            )
        } catch {
            return "AI分析暂时不可用，请稍后再试。"
        }
    }
    
    private func buildAnalysisPrompt(records: [DailyHealthRecord], analysis: HealthHistoryAnalysis) -> String {
        // 格式化日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M月d日"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        // 构建每日详细数据列表
        var dailyDetails = "每日详细数据：\n"
        for record in records.reversed() {
            let dateStr = dateFormatter.string(from: record.date)
            dailyDetails += "- \(dateStr): 睡眠\(String(format: "%.1f", record.sleepHours))小时, 步数\(record.steps)步, 运动\(record.exerciseMinutes)分钟, 健康分\(record.overallScore)/100\n"
        }
        
        // 计算平均值（用于对比）
        let totalSleep = records.map { $0.sleepHours }.reduce(0, +)
        let avgSleep = totalSleep / Double(records.count)
        
        let totalSteps = records.map { Double($0.steps) }.reduce(0, +)
        let avgSteps = Int(totalSteps / Double(records.count))
        
        let totalExercise = records.map { Double($0.exerciseMinutes) }.reduce(0, +)
        let avgExercise = Int(totalExercise / Double(records.count))
        
        return """
        请作为健康顾问，对用户近\(selectedDays)天的健康数据进行深度分析：
        
        \(dailyDetails)
        
        数据总览（平均值）：
        - 平均睡眠: \(String(format: "%.1f", avgSleep))小时
        - 平均步数: \(avgSteps)步
        - 平均运动: \(avgExercise)分钟
        
        趋势分析：
        - 睡眠趋势: \(analysis.sleepTrend.description)
        - 步数趋势: \(analysis.stepsTrend.description)
        - 运动趋势: \(analysis.exerciseTrend.description)
        
        异常情况：
        \(analysis.consecutiveLowSleepDays > 0 ? "- 连续\(analysis.consecutiveLowSleepDays)天睡眠不足" : "- 睡眠正常")
        \(analysis.consecutiveLowStepsDays > 0 ? "- 连续\(analysis.consecutiveLowStepsDays)天步数不足" : "- 活动正常")
        
        请根据每日详细数据和整体趋势，生成一段150-200字的个性化健康分析报告，要求：
        1. 用温暖、专业的语气，像朋友在关心
        2. 结合具体某天的数据来说明问题（比如"12月20日睡眠只有4.5小时"）
        3. 指出具体的问题和亮点（用每日数据和趋势说话）
        4. 给出3-4条实用的改善建议
        5. 鼓励用户，给予信心和动力
        6. 不要使用模板化的套路，每次分析都要有新意
        7. 语言要自然流畅，不要僵硬
        8. 可以适当使用emoji增加亲切感
        """
    }
}

// MARK: - 辅助视图

struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct DailyRecordCard: View {
    let record: DailyHealthRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(record.date))
                    .font(.headline)
                Spacer()
                HealthScoreBadge(score: record.overallScore)
            }
            
            HStack(spacing: 20) {
                DataItem(icon: "💤", value: String(format: "%.1f小时", record.sleepHours))
                DataItem(icon: "👣", value: "\(record.steps)步")
                DataItem(icon: "🏃", value: "\(record.exerciseMinutes)分钟")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

struct DataItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HealthScoreBadge: View {
    let score: Int
    
    var body: some View {
        Text("\(score)分")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
    
    private var color: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

struct TrendRow: View {
    let title: String
    let trend: HealthTrend
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                Text(trend.description)
                    .font(.subheadline)
                    .foregroundColor(trend.color)
            }
        }
    }
}

extension HealthTrend {
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .insufficient: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        case .insufficient: return .gray
        }
    }
}
