//
//  VitalityPactWidget.swift
//  VitalityPactWidget
//
//  桌面 Widget 组件 - 支持多角色系统
//
//  ⚠️ 重要说明：
//  此文件需要在独立的 Widget Extension target 中才能正常工作。
//  请按照以下步骤启用 Widget 功能：
//  1. Xcode -> File -> New -> Target -> Widget Extension
//  2. 将此文件移到新创建的 Widget target
//  3. 配置 App Group 以共享数据
//  4. 取消注释 @main 和相关代码
//

import WidgetKit
import SwiftUI

// MARK: - Widget 数据模型
struct CharacterEntry: TimelineEntry {
    let date: Date
    let characterType: WidgetCharacterType
    let healthLevel: WidgetHealthLevel
    let steps: Int
    let sleepHours: Double
    let message: String
}

// MARK: - Widget 专用角色类型
enum WidgetCharacterType: String {
    case warrior, mage, pet, sage
    
    var icon: String {
        switch self {
        case .warrior: return "⚔️"
        case .mage: return "🔮"
        case .pet: return "🐱"
        case .sage: return "📚"
        }
    }
    
    var displayName: String {
        switch self {
        case .warrior: return "热血战士"
        case .mage: return "治愈法师"
        case .pet: return "元气萌宠"
        case .sage: return "睿智导师"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .warrior: return .red
        case .mage: return .purple
        case .pet: return .pink
        case .sage: return .blue
        }
    }
    
    func emoji(for level: WidgetHealthLevel) -> String {
        switch self {
        case .warrior:
            switch level {
            case .critical: return "😵"
            case .weak: return "😓"
            case .normal: return "😤"
            case .good: return "💪"
            case .excellent: return "🔥"
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
            case .critical: return "😿"
            case .weak: return "🐱💤"
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
    
    func backgroundColor(for level: WidgetHealthLevel) -> Color {
        switch level {
        case .critical: return Color.gray.opacity(0.5)
        case .weak: return themeColor.opacity(0.2)
        case .normal: return themeColor.opacity(0.3)
        case .good: return themeColor.opacity(0.4)
        case .excellent: return themeColor.opacity(0.5)
        }
    }
}

// MARK: - Widget 健康等级
enum WidgetHealthLevel: Int {
    case critical = 0, weak = 1, normal = 2, good = 3, excellent = 4
    
    var displayName: String {
        switch self {
        case .critical: return "危险"
        case .weak: return "虚弱"
        case .normal: return "普通"
        case .good: return "良好"
        case .excellent: return "极佳"
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
    
    static func from(score: Int) -> WidgetHealthLevel {
        switch score {
        case 0...20: return .critical
        case 21...40: return .weak
        case 41...60: return .normal
        case 61...80: return .good
        default: return .excellent
        }
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CharacterEntry {
        CharacterEntry(
            date: Date(),
            characterType: .warrior,
            healthLevel: .normal,
            steps: 5000,
            sleepHours: 7,
            message: "等待连接中..."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CharacterEntry) -> Void) {
        let entry = CharacterEntry(
            date: Date(),
            characterType: .warrior,
            healthLevel: .good,
            steps: 6000,
            sleepHours: 7.5,
            message: "状态不错，继续加油！"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharacterEntry>) -> Void) {
        // 从 App Group 读取共享数据
        let sharedDefaults = UserDefaults(suiteName: "group.com.Xianwei.VitalityPact")

        let steps = sharedDefaults?.integer(forKey: "steps") ?? 3000
        let sleepHours = sharedDefaults?.double(forKey: "sleepHours") ?? 6.0
        let healthScore = sharedDefaults?.integer(forKey: "healthScore") ?? 50
        let characterTypeString = sharedDefaults?.string(forKey: "characterType") ?? "warrior"
        let message = sharedDefaults?.string(forKey: "currentMessage") ?? "打开App查看状态~"
        
        let characterType = WidgetCharacterType(rawValue: characterTypeString) ?? .warrior
        let healthLevel = WidgetHealthLevel.from(score: healthScore)

        let entry = CharacterEntry(
            date: Date(),
            characterType: characterType,
            healthLevel: healthLevel,
            steps: steps,
            sleepHours: sleepHours,
            message: message
        )

        // 每 15 分钟更新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct VitalityPactWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 小尺寸 Widget
struct SmallWidgetView: View {
    let entry: CharacterEntry

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    entry.characterType.backgroundColor(for: entry.healthLevel),
                    entry.characterType.themeColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                // 角色表情
                Text(entry.characterType.emoji(for: entry.healthLevel))
                    .font(.system(size: 45))

                // 状态标签
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.healthLevel.color)
                        .frame(width: 6, height: 6)
                    Text(entry.healthLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)

                // 简短消息
                Text(getShortMessage())
                    .font(.caption2)
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(10)
        }
    }
    
    func getShortMessage() -> String {
        switch entry.healthLevel {
        case .critical: return "需要休息..."
        case .weak: return "状态欠佳"
        case .normal: return "状态一般"
        case .good: return "状态良好"
        case .excellent: return "满分状态！"
        }
    }
}

// MARK: - 中尺寸 Widget
struct MediumWidgetView: View {
    let entry: CharacterEntry

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    entry.characterType.backgroundColor(for: entry.healthLevel),
                    entry.characterType.themeColor.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 15) {
                // 左侧角色
                VStack(spacing: 8) {
                    Text(entry.characterType.emoji(for: entry.healthLevel))
                        .font(.system(size: 55))

                    // 角色名称
                    Text(entry.characterType.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.7))
                }
                .frame(width: 80)

                // 右侧信息
                VStack(alignment: .leading, spacing: 8) {
                    // 状态和消息
                    HStack {
                        Circle()
                            .fill(entry.healthLevel.color)
                            .frame(width: 8, height: 8)
                        Text(entry.healthLevel.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    Text(entry.message)
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // 数据统计
                    HStack(spacing: 12) {
                        DataLabel(icon: "figure.walk", value: "\(entry.steps)")
                        DataLabel(icon: "bed.double.fill", value: String(format: "%.1fh", entry.sleepHours))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
        }
    }
}

// MARK: - 大尺寸 Widget
struct LargeWidgetView: View {
    let entry: CharacterEntry

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    entry.characterType.backgroundColor(for: entry.healthLevel),
                    entry.characterType.themeColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 15) {
                // 顶部：角色和消息
                HStack(spacing: 20) {
                    // 角色
                    VStack {
                        Text(entry.characterType.emoji(for: entry.healthLevel))
                            .font(.system(size: 70))
                        Text(entry.characterType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    // 消息气泡
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(entry.healthLevel.color)
                                .frame(width: 10, height: 10)
                            Text(entry.healthLevel.displayName)
                                .font(.headline)
                        }
                        
                        Text(entry.message)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity)
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // 底部：详细数据
                HStack(spacing: 20) {
                    LargeDataCard(
                        icon: "figure.walk",
                        title: "今日步数",
                        value: "\(entry.steps)",
                        color: .blue
                    )
                    
                    LargeDataCard(
                        icon: "bed.double.fill",
                        title: "睡眠时长",
                        value: String(format: "%.1fh", entry.sleepHours),
                        color: .purple
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 辅助视图组件
struct DataLabel: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.primary.opacity(0.7))
    }
}

struct LargeDataCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

// MARK: - Widget 配置
// ⚠️ 在独立的 Widget Extension target 中取消注释以下代码

/*
@main
struct VitalityPactWidget: Widget {
    let kind: String = "VitalityPactWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VitalityPactWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("元气契约")
        .description("你的健康伙伴时刻陪伴着你")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
*/

// MARK: - Preview
#if DEBUG
struct VitalityPactWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 小尺寸预览
            SmallWidgetView(entry: CharacterEntry(
                date: .now,
                characterType: .warrior,
                healthLevel: .good,
                steps: 6000,
                sleepHours: 7,
                message: "状态不错！"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - 战士")
            
            SmallWidgetView(entry: CharacterEntry(
                date: .now,
                characterType: .pet,
                healthLevel: .excellent,
                steps: 10000,
                sleepHours: 8,
                message: "满分！"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - 萌宠")
            
            // 中尺寸预览
            MediumWidgetView(entry: CharacterEntry(
                date: .now,
                characterType: .mage,
                healthLevel: .weak,
                steps: 2000,
                sleepHours: 4.5,
                message: "有些疲惫呢，记得照顾好自己哦"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - 法师")
            
            // 大尺寸预览
            LargeWidgetView(entry: CharacterEntry(
                date: .now,
                characterType: .sage,
                healthLevel: .normal,
                steps: 5000,
                sleepHours: 6.5,
                message: "保持当前的节奏，循序渐进。"
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - 智者")
        }
    }
}
#endif
