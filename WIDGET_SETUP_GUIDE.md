# Widget 桌面小组件设置指南

## 概述
元气契约支持 iOS 桌面小组件功能，用户可以在手机桌面直接看到角色状态和健康数据，无需打开 App。

## 设置步骤

### 1. 创建 Widget Extension Target

1. 在 Xcode 中打开项目
2. 选择 `File` → `New` → `Target`
3. 选择 `Widget Extension` 模板
4. 命名为 `VitalityPactWidget`
5. 取消勾选 `Include Live Activity` 和 `Include Configuration App Intent`
6. 点击 `Finish`

### 2. 配置 App Group

为了让主 App 和 Widget 共享数据，需要配置 App Group：

1. 选择主 App target → `Signing & Capabilities`
2. 点击 `+ Capability` → 选择 `App Groups`
3. 点击 `+` 添加一个新的 App Group，命名为：
   ```
   group.com.yourname.VitalityPact
   ```
4. 对 Widget Extension target 重复同样的步骤

### 3. 移动 Widget 代码

1. 将 `VitalityPact/VitalityPactWidget/VitalityPactWidget.swift` 文件移动到新创建的 Widget Extension target
2. 取消注释文件底部的 `@main` 和 Widget 配置代码：

```swift
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
```

### 4. 更新 App Group 标识符

如果你修改了 App Group 名称，需要同时更新以下文件中的 `suiteName`：

- `VitalityPact/Utils/WidgetDataManager.swift`
- `VitalityPactWidget/VitalityPactWidget.swift`

将 `group.com.Xianwei.VitalityPact` 替换为你实际使用的 App Group 名称。

### 5. 编译和运行

1. 选择主 App scheme 并运行
2. 在模拟器或真机上，长按桌面进入编辑模式
3. 点击左上角 `+` 按钮
4. 搜索 "元气契约" 并添加小组件

## Widget 功能说明

### 支持的尺寸

| 尺寸 | 显示内容 |
|------|----------|
| 小 | 角色表情 + 健康等级 + 简短状态 |
| 中 | 角色表情 + 角色名称 + 对话消息 + 步数/睡眠数据 |
| 大 | 完整角色展示 + 对话气泡 + 详细数据卡片 |

### 数据更新

- Widget 每 15 分钟自动刷新一次
- 当主 App 中健康数据变化时，会主动触发 Widget 更新
- 角色形象会根据用户选择的角色类型和当前健康等级动态变化

### 角色类型

Widget 支持显示 4 种角色类型：
- ⚔️ 热血战士
- 🔮 治愈法师
- 🐱 元气萌宠
- 📚 睿智导师

每种角色都有 5 个不同的健康等级表情。

## 常见问题

### Q: Widget 显示 "打开App查看状态"？
A: 这表示 Widget 还未从主 App 获取到数据。请先打开主 App，等待数据同步后 Widget 会自动更新。

### Q: Widget 数据不更新？
A: 检查 App Group 是否配置正确，确保主 App 和 Widget Extension 使用相同的 App Group。

### Q: 如何更换 Widget 上的角色？
A: 在主 App 中点击右上角的角色图标，选择新的角色类型后，Widget 会在下次刷新时更新。
