//
//  HealthHistory.swift
//  VitalityPact
//
//  健康历史数据存储系统
//

import Foundation
import Combine

/// 每日健康记录
struct DailyHealthRecord: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var steps: Int
    var sleepHours: Double
    var exerciseMinutes: Int
    var overallScore: Int
    
    /// 从HealthData创建记录
    static func from(healthData: HealthData, date: Date = Date()) -> DailyHealthRecord {
        DailyHealthRecord(
            date: date,
            steps: healthData.steps,
            sleepHours: healthData.sleepHours,
            exerciseMinutes: healthData.exerciseMinutes,
            overallScore: healthData.overallScore
        )
    }
}

/// 历史数据分析结果
struct HealthHistoryAnalysis {
    // 最近N天的统计
    var recentDays: Int
    var averageSteps: Int
    var averageSleep: Double
    var averageExercise: Int
    var averageScore: Int
    
    // 趋势分析
    var sleepTrend: HealthTrend
    var stepsTrend: HealthTrend
    var exerciseTrend: HealthTrend
    
    // 异常情况
    var consecutiveLowSleepDays: Int  // 连续睡眠不足天数
    var consecutiveLowStepsDays: Int  // 连续步数不足天数
    
    /// 生成分析摘要文本（供LLM使用）
    func generateSummaryText() -> String {
        var summary = "近\(recentDays)天健康数据：\n"
        
        // 睡眠分析
        summary += "睡眠：平均\(String(format: "%.1f", averageSleep))小时/天"
        if consecutiveLowSleepDays > 0 {
            summary += "，已连续\(consecutiveLowSleepDays)天睡眠不足（<6小时）"
        }
        summary += "，趋势\(sleepTrend.emoji)\(sleepTrend.description)。\n"
        
        // 步数分析
        summary += "步数：平均\(averageSteps)步/天"
        if consecutiveLowStepsDays > 0 {
            summary += "，已连续\(consecutiveLowStepsDays)天运动不足（<5000步）"
        }
        summary += "，趋势\(stepsTrend.emoji)\(stepsTrend.description)。\n"
        
        // 运动分析
        summary += "运动：平均\(averageExercise)分钟/天"
        summary += "，趋势\(exerciseTrend.emoji)\(exerciseTrend.description)。\n"
        
        // 综合评分
        summary += "综合健康评分：\(averageScore)/100"
        
        return summary
    }
}

/// 健康趋势
enum HealthTrend: String, Codable {
    case improving = "improving"      // 改善中
    case stable = "stable"            // 稳定
    case declining = "declining"      // 下降中
    case insufficient = "insufficient" // 数据不足
    
    var description: String {
        switch self {
        case .improving: return "正在改善"
        case .stable: return "保持稳定"
        case .declining: return "有所下降"
        case .insufficient: return "数据不足"
        }
    }
    
    var emoji: String {
        switch self {
        case .improving: return "📈"
        case .stable: return "➡️"
        case .declining: return "📉"
        case .insufficient: return "❓"
        }
    }
}

/// 健康历史管理器
class HealthHistoryManager: ObservableObject {
    static let shared = HealthHistoryManager()
    
    @Published private var records: [DailyHealthRecord] = []
    
    private let userDefaultsKey = "healthHistoryRecords"
    private let maxRecordDays = 90  // 最多保留90天记录
    
    private init() {
        loadRecords()
    }
    
    /// 记录今日健康数据
    func recordToday(healthData: HealthData) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 移除今天的旧记录
        records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // 添加新记录
        let record = DailyHealthRecord.from(healthData: healthData, date: today)
        records.append(record)
        
        // 清理过期记录
        cleanupOldRecords()
        
        // 保存
        saveRecords()
    }
    
    /// 获取最近N天的记录
    func getRecentRecords(days: Int) -> [DailyHealthRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return records
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date > $1.date }
    }
    
    /// 分析最近N天的健康数据
    func analyzeRecent(days: Int) -> HealthHistoryAnalysis {
        let recentRecords = getRecentRecords(days: days)
        
        guard !recentRecords.isEmpty else {
            return HealthHistoryAnalysis(
                recentDays: 0,
                averageSteps: 0,
                averageSleep: 0,
                averageExercise: 0,
                averageScore: 0,
                sleepTrend: .insufficient,
                stepsTrend: .insufficient,
                exerciseTrend: .insufficient,
                consecutiveLowSleepDays: 0,
                consecutiveLowStepsDays: 0
            )
        }
        
        // 计算平均值
        let avgSteps = recentRecords.map { $0.steps }.reduce(0, +) / recentRecords.count
        let avgSleep = recentRecords.map { $0.sleepHours }.reduce(0, +) / Double(recentRecords.count)
        let avgExercise = recentRecords.map { $0.exerciseMinutes }.reduce(0, +) / recentRecords.count
        let avgScore = recentRecords.map { $0.overallScore }.reduce(0, +) / recentRecords.count
        
        // 分析趋势（对比前半段和后半段）
        let sleepTrend = analyzeTrend(values: recentRecords.map { $0.sleepHours })
        let stepsTrend = analyzeTrend(values: recentRecords.map { Double($0.steps) })
        let exerciseTrend = analyzeTrend(values: recentRecords.map { Double($0.exerciseMinutes) })
        
        // 计算连续异常天数
        let consecutiveLowSleep = countConsecutiveLowValues(
            records: recentRecords,
            getValue: { $0.sleepHours },
            threshold: 6.0
        )
        let consecutiveLowSteps = countConsecutiveLowValues(
            records: recentRecords,
            getValue: { Double($0.steps) },
            threshold: 5000
        )
        
        return HealthHistoryAnalysis(
            recentDays: recentRecords.count,
            averageSteps: avgSteps,
            averageSleep: avgSleep,
            averageExercise: avgExercise,
            averageScore: avgScore,
            sleepTrend: sleepTrend,
            stepsTrend: stepsTrend,
            exerciseTrend: exerciseTrend,
            consecutiveLowSleepDays: consecutiveLowSleep,
            consecutiveLowStepsDays: consecutiveLowSteps
        )
    }
    
    /// 获取今天是否已记录
    func hasTodayRecord() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return records.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    // MARK: - 私有方法
    
    private func analyzeTrend(values: [Double]) -> HealthTrend {
        guard values.count >= 3 else { return .insufficient }
        
        let halfPoint = values.count / 2
        let firstHalf = Array(values.prefix(halfPoint))
        let secondHalf = Array(values.suffix(halfPoint))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let change = (secondAvg - firstAvg) / firstAvg
        
        if change > 0.1 { return .improving }
        if change < -0.1 { return .declining }
        return .stable
    }
    
    private func countConsecutiveLowValues(
        records: [DailyHealthRecord],
        getValue: (DailyHealthRecord) -> Double,
        threshold: Double
    ) -> Int {
        var count = 0
        for record in records.sorted(by: { $0.date > $1.date }) {
            if getValue(record) < threshold {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    private func cleanupOldRecords() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxRecordDays, to: Date()) ?? Date()
        records.removeAll { $0.date < cutoffDate }
    }
    
    // MARK: - 持久化
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([DailyHealthRecord].self, from: data) {
            records = decoded
        }
    }
    
    /// 清空所有历史记录（调试用）
    func clearAllRecords() {
        records.removeAll()
        saveRecords()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// 直接插入历史记录（调试用）
    func insertRecord(_ record: DailyHealthRecord) {
        // 移除同一天的旧记录
        records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: record.date) }
        // 添加新记录
        records.append(record)
        // 保存
        saveRecords()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
