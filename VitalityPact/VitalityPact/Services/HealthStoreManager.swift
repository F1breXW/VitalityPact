//
//  HealthStoreManager.swift
//  VitalityPact
//
//  HealthKit 数据管理器
//

import Foundation
import HealthKit
import Combine

class HealthStoreManager: ObservableObject {
    static let shared = HealthStoreManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var healthData = HealthData()
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 调试模式：用于演示时手动调节数据
    @Published var debugMode = false
    @Published var debugSteps: Double = 0
    @Published var debugSleepHours: Double = 7
    @Published var debugExerciseMinutes: Double = 0
    @Published var debugHeartRate: Double = 70

    private init() {}

    /// 需要读取的健康数据类型
    private var typesToRead: Set<HKObjectType> {
        Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])
    }

    /// 检查 HealthKit 是否可用
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// 请求 HealthKit 授权
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            await MainActor.run {
                self.errorMessage = "此设备不支持 HealthKit"
            }
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
            }
            await fetchAllData()
        } catch {
            await MainActor.run {
                self.errorMessage = "授权失败: \(error.localizedDescription)"
            }
        }
    }

    /// 获取所有健康数据
    func fetchAllData() async {
        await MainActor.run {
            self.isLoading = true
        }

        // 如果是调试模式，使用调试数据
        if debugMode {
            await MainActor.run {
                self.healthData = HealthData(
                    steps: Int(self.debugSteps),
                    sleepHours: self.debugSleepHours,
                    exerciseMinutes: Int(self.debugExerciseMinutes),
                    heartRate: Int(self.debugHeartRate)
                )
                self.isLoading = false
            }
            return
        }

        async let steps = fetchSteps()
        async let sleep = fetchSleepHours()
        async let exercise = fetchExerciseMinutes()
        async let heartRate = fetchHeartRate()

        let (stepsResult, sleepResult, exerciseResult, heartRateResult) = await (steps, sleep, exercise, heartRate)

        await MainActor.run {
            self.healthData = HealthData(
                steps: stepsResult,
                sleepHours: sleepResult,
                exerciseMinutes: exerciseResult,
                heartRate: heartRateResult
            )
            self.isLoading = false
        }
    }

    /// 获取今日步数
    private func fetchSteps() async -> Int {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    /// 获取昨晚睡眠时长
    private func fetchSleepHours() async -> Double {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                var totalSleepSeconds: TimeInterval = 0
                for sample in sleepSamples {
                    // 只计算 asleep 状态
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                let hours = totalSleepSeconds / 3600
                continuation.resume(returning: hours)
            }
            healthStore.execute(query)
        }
    }

    /// 获取今日运动时长
    private func fetchExerciseMinutes() async -> Int {
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let minutes = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                continuation.resume(returning: Int(minutes))
            }
            healthStore.execute(query)
        }
    }

    /// 获取最新心率
    private func fetchHeartRate() async -> Int {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 70) // 默认心率
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: Int(heartRate))
            }
            healthStore.execute(query)
        }
    }

    /// 更新调试数据（演示用）
    func updateDebugData() {
        if debugMode {
            healthData = HealthData(
                steps: Int(debugSteps),
                sleepHours: debugSleepHours,
                exerciseMinutes: Int(debugExerciseMinutes),
                heartRate: Int(debugHeartRate)
            )
        }
    }
}
