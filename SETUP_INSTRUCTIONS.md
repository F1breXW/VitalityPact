# 元气契约 (Vitality Pact) - 配置说明

## 项目设置说明

### 1. App Group 配置（Widget数据共享）

为了在主App和Widget之间共享数据，需要配置App Group：

#### 步骤：
1. 在 [Apple Developer Portal](https://developer.apple.com) 创建 App Group
   - Identifier: `group.com.yourname.VitalityPact`
   - 替换代码中的 `group.com.yourname.VitalityPact` 为实际的App Group ID

2. 在 Xcode 项目设置中：
   - 进入 `Signing & Capabilities` 选项卡
   - 点击 `+ Capability` 添加 `App Groups`
   - 选择你创建的 App Group

3. 更新以下文件中的 App Group ID：
   - `VitalityPact/Utils/WidgetDataManager.swift` (第14行)
   - `VitalityPactWidget/VitalityPactWidget.swift` (第75行)

#### 临时解决方案：
如果暂时不想配置 App Group，可以修改 `WidgetDataManager.swift` 使用普通 UserDefaults，但Widget将无法显示实时数据。

### 2. HealthKit 权限设置

项目已经配置了以下权限：
- 读取步数 (Step Count)
- 读取睡眠分析 (Sleep Analysis)
- 读取运动时长 (Apple Exercise Time)
- 读取心率 (Heart Rate)

首次运行时会弹出授权提示。

### 3. AI API 配置

在 `Services/AIService.swift` 中配置你的API Key：

```swift
private let apiKey = "YOUR_API_KEY_HERE"  // 替换为你的API Key
```

支持的API：
- DeepSeek: `https://api.deepseek.com/v1/chat/completions`
- OpenAI: `https://api.openai.com/v1/chat/completions`
- Moonshot: `https://api.moonshot.cn/v1/chat/completions`

未配置API Key时，应用会使用本地预设的对话模板。

### 4. 演示功能 (Debug Mode)

应用内置了演示控制台：

1. 在主界面连续点击右上角隐藏按钮5次
2. 打开"控制台"面板
3. 可以手动调节：
   - 步数 (0-15000)
   - 睡眠 (0-12小时)
   - 运动时长 (0-120分钟)
   - 心率 (50-150)

### 5. 项目运行

1. 使用 Xcode 打开 `VitalityPact.xcodeproj`
2. 选择目标设备（iPhone/iPad）
3. 点击运行 (⌘+R)

### 6. 添加Widget到桌面

1. 长按iPhone桌面空白处进入编辑模式
2. 点击左上角的"+"
3. 搜索"元气契约"
4. 选择小号或中号尺寸
5. 完成添加

## 故障排除

### Widget不显示数据
- 检查App Group配置是否正确
- 确保主App至少运行过一次以同步数据
- 重启设备

### HealthKit数据为空
- 在iPhone设置中确保健康应用有数据
- 检查是否授权了所有健康数据类型
- 使用Debug Mode手动调节数据进行测试

### AI对话不更新
- 检查API Key是否正确配置
- 检查网络连接
- 查看控制台错误信息

## 开发者注意事项

- 项目使用 SwiftUI 和 Combine
- 最低支持 iOS 17.0
- 需要 Xcode 15.0 或更高版本
- Widget 使用 WidgetKit 框架
