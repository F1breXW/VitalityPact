# VitalityPact（活力契约）

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift%205.9-orange.svg" alt="Language">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  一款创新的健康管理应用，通过虚拟伙伴陪伴和游戏化激励机制，让健康管理变得有趣而有效。
</p>

---

## ✨ 特色功能

### 🎮 虚拟伙伴系统
- **4种性格角色**：战士、法师、宠物、智者，各有独特对话风格
- **6+精美图片角色**：动漫、Q版、像素等多种风格
- **智能对话系统**：基于大语言模型的个性化对话
- **实时状态反馈**：根据健康数据动态变化表情和状态

### 📊 健康数据追踪
- **HealthKit集成**：自动同步步数、睡眠、运动、心率数据
- **综合评分系统**：实时计算并显示健康指数（0-100分）
- **90天历史记录**：完整保存每日健康数据
- **趋势分析**：7/14/30/90天多维度数据分析

### 🪙 金币激励系统
- **多维度奖励**：
  - 步数：每10步 = 1金币
  - 睡眠：6-8+小时可获10-50金币
  - 运动：15-60+分钟可获10-50金币
- **角色解锁**：使用金币解锁精美图片角色（500-1500金币）
- **永久拥有**：解锁后的角色永久可用

### 💬 AI健康顾问
- **个性化建议**：根据健康数据提供专业建议
- **详细分析报告**：150-200字深度健康分析
- **实时对话**：随时与虚拟伙伴交流健康问题

### 🔍 调试模式
- **快速场景切换**：11种预设健康场景
- **数据模拟**：自由调整步数、睡眠、运动等数据
- **演示友好**：便于展示各种健康状态

---

## 🏗️ 技术架构

### MVVM架构
```
VitalityPact/
├── Models/              # 数据模型层
│   ├── HealthData.swift           # 健康数据模型
│   ├── HealthHistory.swift        # 历史记录模型
│   ├── CharacterType.swift        # 角色类型定义
│   ├── ImageCharacter.swift       # 图片角色系统
│   └── PartnerAttributes.swift    # 伙伴成长属性
├── Views/               # 视图层
│   ├── ContentView.swift          # 主界面
│   ├── ChatView.swift             # 聊天界面
│   ├── HealthHistoryView.swift    # 健康历史
│   ├── ImageCharacterView.swift   # 角色选择
│   ├── PartnerStatsView.swift     # 伙伴属性
│   └── DebugPanelView.swift       # 调试面板
├── ViewModels/          # 视图模型层
│   └── GameStateManager.swift     # 游戏状态管理
├── Services/            # 服务层
│   ├── HealthStoreManager.swift   # HealthKit管理
│   └── AIService.swift            # AI对话服务
└── Utils/               # 工具层
    └── WidgetDataManager.swift    # Widget数据共享
```

### 核心技术栈
- **SwiftUI** - 现代化UI框架
- **Combine** - 响应式编程
- **HealthKit** - 健康数据集成
- **UserDefaults** - 本地数据持久化
- **URLSession** - 网络请求
- **WidgetKit** - 桌面小组件

### 设计模式
- **MVVM** - 清晰的架构分层
- **Singleton** - 全局状态管理
- **Observer** - 数据绑定和响应
- **Factory** - 角色创建
- **Strategy** - 多种对话策略

---

## 🚀 快速开始

### 环境要求
- macOS 14.0+
- Xcode 15.0+
- iOS 17.0+ 设备或模拟器
- Swift 5.9+

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/F1breXW/VitalityPact.git
cd VitalityPact
```

2. **打开项目**
```bash
open VitalityPact.xcodeproj
```

3. **配置API密钥**
   
   在 `AIService.swift` 中配置你的AI服务API密钥：
   ```swift
   private let apiKey = "YOUR_API_KEY"
   ```

4. **运行项目**
   - 选择目标设备（iOS 17.0+）
   - 点击 Run 或按 `⌘R`

### 首次使用

1. **授权HealthKit**：首次启动时授权健康数据访问
2. **选择伙伴**：从4种Emoji角色或多种图片角色中选择
3. **开始互动**：查看健康数据，与虚拟伙伴对话
4. **赚取金币**：通过健康行为积累金币，解锁更多角色

---

## 📱 功能演示

### 主界面
- 实时显示当前健康指数
- 虚拟伙伴根据健康状态变化
- 智能对话气泡提供建议
- 金币余额和查看按钮

### 健康历史
- 多时间维度查看（7/14/30/90天）
- 详细的每日数据记录
- 趋势分析和异常检测
- AI生成的健康报告

### 角色系统
- **Emoji角色**：战士⚔️、法师🧙、宠物🐱、智者📚
- **图片角色**：小狐狸🦊、元气少女👧、森林精灵🧚、智者猫头鹰🦉等
- 每个角色有独特的性格和对话风格

### 调试模式
- **开启方式**：长按设置按钮2秒
- **功能**：
  - 调整步数/睡眠/运动数据
  - 加载11种预设场景
  - 快速设置金币数量
  - 一键解锁所有角色

---

## 🎯 核心功能详解

### 1. 健康评分算法
```swift
综合分数 = (步数得分 + 睡眠得分 + 运动得分) / 3

步数得分 = min(100, 步数 / 100)     // 10000步满分
睡眠得分 = 分段评分(4-8+小时)        // 8小时满分
运动得分 = min(100, 运动分钟 × 100 / 60)  // 60分钟满分
```

### 2. 金币计算公式
```
基础金币 = 步数 / 10

额外奖励：
- 睡眠 ≥8小时：+50金币
- 睡眠 7-8小时：+30金币
- 睡眠 6-7小时：+10金币
- 运动 ≥60分钟：+50金币
- 运动 30-60分钟：+30金币
- 运动 15-30分钟：+10金币

每日最高可获得：1000+ 金币
```

### 3. 角色解锁价格
- 🦊 小狐狸·绒绒：500金币
- 🎮 像素勇者：600金币
- 🐻 抱抱熊·团团：700金币
- 🦉 智者·欧罗：800金币
- 👧 元气少女·小阳：1000金币
- 🧚 森林精灵·露娜：1500金币

---

## 🔧 开发指南

### 添加新角色

1. 在 `CharacterType.swift` 添加角色类型
2. 在 `AIService.swift` 定义对话风格
3. 在 `ImageCharacter.swift` 添加角色配置

### 修改评分规则

编辑 `HealthData.swift` 中的评分计算方法：
```swift
var stepsScore: Int { ... }
var sleepScore: Int { ... }
var exerciseScore: Int { ... }
```

### 自定义AI提示词

在 `AIService.swift` 的 `buildPrompt` 方法中修改：
```swift
private func buildPrompt(...) -> String {
    // 自定义提示词逻辑
}
```

---

## 📝 项目亮点

1. **完整的MVVM架构**：清晰的代码分层，易于维护和扩展
2. **HealthKit深度集成**：真实健康数据驱动应用逻辑
3. **AI驱动的个性化体验**：每次对话都是独特的
4. **游戏化激励机制**：让健康管理变得有趣
5. **精美的UI设计**：SwiftUI打造流畅用户体验
6. **完善的调试工具**：便于开发和演示

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---


## 🙏 致谢

- [SiliconFlow](https://siliconflow.cn) - 提供AI对话服务
- [Apple HealthKit](https://developer.apple.com/health-fitness/) - 健康数据框架
- [Swift Community](https://swift.org/community/) - 优秀的开发社区

---


<p align="center">Made with ❤️ for healthier life</p>
