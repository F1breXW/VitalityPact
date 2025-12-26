//
//  AIService.swift
//  VitalityPact
//
//  AI 对话生成服务 - 使用硅基流动 Qwen2.5-7B-Instruct
//

import Foundation
import SwiftUI
import Combine

class AIService: ObservableObject {
    static let shared = AIService()
    
    // 内置配置 - 使用硅基流动
    private let apiKey = "sk-ffbccabsauzbarjyyclwhkzfqqneagqhzajfpzsnlswnzcwt"
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    private let model = "Qwen/Qwen2.5-7B-Instruct"
    
    // AI 功能默认启用
    let aiEnabled = true

    private init() {}

    /// 生成角色对话（支持不同角色类型）
    func generateDialogue(
        characterType: CharacterType,
        healthLevel: HealthLevel,
        healthData: HealthData
    ) async -> String {
        let prompt = buildPrompt(characterType: characterType, healthLevel: healthLevel, healthData: healthData)
        do {
            return try await callAPI(prompt: prompt, characterType: characterType)
        } catch {
            print("AI API 调用失败: \(error)")
            // 失败时使用本地模板作为备选
            return getLocalDialogue(characterType: characterType, healthLevel: healthLevel, healthData: healthData)
        }
    }
    
    /// 兼容旧接口
    func generateDialogue(state: CharacterState, healthData: HealthData) async -> String {
        let characterType = UserSettings.shared.selectedCharacterType
        let healthLevel = HealthLevel.from(score: healthData.overallScore)
        return await generateDialogue(characterType: characterType, healthLevel: healthLevel, healthData: healthData)
    }
    
    /// 聊天对话（支持上下文）
    func chat(
        userMessage: String,
        characterType: CharacterType,
        healthData: HealthData,
        conversationHistory: [ChatMessage]
    ) async throws -> String {
        let prompt = buildChatPrompt(userMessage: userMessage, healthData: healthData, history: conversationHistory)
        return try await callChatAPI(prompt: prompt, characterType: characterType, history: conversationHistory)
    }
    
    /// 构建聊天 Prompt
    private func buildChatPrompt(userMessage: String, healthData: HealthData, history: [ChatMessage]) -> String {
        let healthLevel = HealthLevel.from(score: healthData.overallScore)
        let stepsDesc = describeSteps(healthData.steps)
        let sleepDesc = describeSleep(healthData.sleepHours)
        
        return """
        用户当前健康状态：
        - 睡眠: \(String(format: "%.1f", healthData.sleepHours))小时（\(sleepDesc)）
        - 步数: \(healthData.steps)步（\(stepsDesc)）
        - 运动: \(healthData.exerciseMinutes)分钟
        - 综合健康等级: \(healthLevel.displayName)
        
        用户说：\(userMessage)
        
        请以你的角色特点回复用户。要求：
        1. 回复自然亲切，像朋友聊天
        2. 可以适当关注用户的健康状态，但不要每次都提
        3. 根据对话内容灵活回应
        4. 控制在50字以内
        5. 保持角色性格特点
        """
    }

    /// 构建 Prompt
    private func buildPrompt(characterType: CharacterType, healthLevel: HealthLevel, healthData: HealthData) -> String {
        let stepsDesc = describeSteps(healthData.steps)
        let sleepDesc = describeSleep(healthData.sleepHours)
        
        return """
        现在契约主的身体数据是：
        - 睡眠: \(String(format: "%.1f", healthData.sleepHours))小时（\(sleepDesc)）
        - 步数: \(healthData.steps)步（\(stepsDesc)）
        - 运动: \(healthData.exerciseMinutes)分钟
        - 综合健康等级: \(healthLevel.displayName)
        
        请根据这个数据和你的角色特点，说一句话。要求：
        1. 不超过30个字
        2. 符合角色性格，自然亲切
        3. 根据健康状态给出相应的鼓励或建议
        4. 不要使用"契约主"这个称呼，用"你"或不用称呼
        5. 语气要自然，像朋友聊天一样
        """
    }
    
    private func getCharacterSystemPrompt(characterType: CharacterType) -> String {
        switch characterType {
        case .warrior:
            return """
            你是一个热血阳光的健康伙伴。性格特点：
            - 积极向上，充满活力
            - 说话简洁有力，会鼓励加油
            - 像一个热情的朋友，不是教练
            - 语气亲切自然，不要用感叹号过多
            """
        case .mage:
            return """
            你是一个温柔治愈的健康伙伴。性格特点：
            - 温暖体贴，关心他人
            - 说话轻柔温和，像在呵护朋友
            - 会关注对方的感受
            - 适当使用"呢""哦"等语气词
            """
        case .pet:
            return """
            你是一个可爱活泼的萌宠伙伴。性格特点：
            - 活泼可爱，会撒娇但不过度卖萌
            - 用可爱的语气说话
            - 像一只贴心的小猫或小狗
            - 可以适当用"喵~"或"汪~"开头，但不要每句都用
            """
        case .sage:
            return """
            你是一个睿智温和的健康顾问。性格特点：
            - 沉稳有智慧，见多识广
            - 给建议像温和的长辈朋友
            - 说话平和稳重，不急不躁
            - 偶尔可以引用一些人生哲理，但要自然
            """
        }
    }
    
    private func describeSteps(_ steps: Int) -> String {
        if steps < 2000 { return "很少" }
        if steps < 5000 { return "偏少" }
        if steps < 8000 { return "还行" }
        return "不错"
    }
    
    private func describeSleep(_ hours: Double) -> String {
        if hours < 5 { return "严重不足" }
        if hours < 6 { return "不太够" }
        if hours < 7 { return "还行" }
        return "充足"
    }

    /// 调用 AI API
    private func callAPI(prompt: String, characterType: CharacterType) async throws -> String {
        guard let url = URL(string: baseURL) else { throw AIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // 设置超时时间

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": getCharacterSystemPrompt(characterType: characterType)],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 80,
            "temperature": 0.8
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }
        
        // 处理各种 HTTP 状态码
        if httpResponse.statusCode != 200 {
            print("API 错误: HTTP \(httpResponse.statusCode)")
            if let errorText = String(data: data, encoding: .utf8) {
                print("错误详情: \(errorText)")
            }
            throw AIError.requestFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 调用聊天 API（支持上下文）
    private func callChatAPI(prompt: String, characterType: CharacterType, history: [ChatMessage]) async throws -> String {
        guard let url = URL(string: baseURL) else { throw AIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        // 构建消息历史（只保留最近6条消息以控制token）
        var messages: [[String: String]] = [
            ["role": "system", "content": getChatSystemPrompt(characterType: characterType)]
        ]
        
        // 添加最近的对话历史
        let recentHistory = history.suffix(6)
        for msg in recentHistory {
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        // 添加当前用户消息
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 150,
            "temperature": 0.9
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            print("API 错误: HTTP \(httpResponse.statusCode)")
            if let errorText = String(data: data, encoding: .utf8) {
                print("错误详情: \(errorText)")
            }
            throw AIError.requestFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 获取聊天系统提示词
    private func getChatSystemPrompt(characterType: CharacterType) -> String {
        switch characterType {
        case .warrior:
            return """
            你是一个热血阳光的健康伙伴，是用户的运动健康助手。性格特点：
            - 积极向上，充满活力和正能量
            - 说话简洁有力，但不会咄咄逼人
            - 像一个热情的朋友，会鼓励和加油
            - 对健康话题有见解，但不说教
            - 回复要自然，像日常聊天一样
            - 可以适当使用"加油""冲鸭"等鼓励词，但不要过度
            """
        case .mage:
            return """
            你是一个温柔治愈的健康伙伴，是用户的贴心陪伴者。性格特点：
            - 温暖体贴，关心他人感受
            - 说话轻柔温和，像在呵护朋友
            - 会倾听和理解，给予情感支持
            - 适当使用"呢""哦""嗯"等温柔语气词
            - 回复要温暖自然，像好朋友聊天
            - 关注情绪和感受，不只是数据
            """
        case .pet:
            return """
            你是一个可爱活泼的萌宠伙伴，是用户的贴心小伙伴。性格特点：
            - 活泼可爱，充满童趣
            - 会撒娇但不过度，保持可爱
            - 可以用"喵~""汪~"开头，但不要每句都用
            - 说话简单直接，像小动物一样单纯
            - 回复要可爱自然，不要装嗲
            - 偶尔卖萌，但要真诚不做作
            """
        case .sage:
            return """
            你是一个睿智温和的健康顾问，是用户的智慧导师。性格特点：
            - 沉稳有智慧，见多识广
            - 说话平和稳重，不急不躁
            - 可以分享人生道理，但要简短自然
            - 偶尔引用格言，但不要说教
            - 回复要有深度但通俗易懂
            - 像温和的长辈朋友，不是严肃的老师
            """
        }
    }

    /// 本地对话模板
    private func getLocalDialogue(characterType: CharacterType, healthLevel: HealthLevel, healthData: HealthData) -> String {
        switch characterType {
        case .warrior: return getWarriorDialogue(healthLevel: healthLevel)
        case .mage: return getMageDialogue(healthLevel: healthLevel)
        case .pet: return getPetDialogue(healthLevel: healthLevel)
        case .sage: return getSageDialogue(healthLevel: healthLevel)
        }
    }
    
    // MARK: - 战士风格
    private func getWarriorDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["身体是革命的本钱，先休息一下吧！", "这样可不行，我们需要恢复体力！", "别硬撑了，休息好才能继续战斗！"].randomElement()!
        case .weak:
            return ["有点累了吧？稍微休息下再出发！", "能量不太足，散个步充充电？", "状态一般，我相信你能调整过来！"].randomElement()!
        case .normal:
            return ["状态还行，继续保持！", "不错不错，保持这个节奏！", "稳定发挥，很棒！"].randomElement()!
        case .good:
            return ["状态不错啊！继续冲！", "很好！就是这种感觉！", "干得漂亮！保持住！"].randomElement()!
        case .excellent:
            return ["太强了！今天状态满分！", "完美！就是这样！", "巅峰状态！为你骄傲！"].randomElement()!
        }
    }
    
    // MARK: - 法师风格
    private func getMageDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["亲爱的，你需要好好休息一下呢...", "看起来很累呢，要不要早点睡？", "身体在发出警告哦，照顾好自己呢"].randomElement()!
        case .weak:
            return ["有些疲惫呢，记得照顾好自己哦", "稍微有点累了，喝杯水休息下？", "今天辛苦了，适当放松一下吧"].randomElement()!
        case .normal:
            return ["今天还不错呢，继续加油哦", "状态挺好的，保持下去吧", "嗯嗯，今天的你很棒呢"].randomElement()!
        case .good:
            return ["今天状态很好呢！开心~", "能感受到你的能量满满哦", "真棒！今天的你闪闪发光呢"].randomElement()!
        case .excellent:
            return ["哇！今天超级棒呢！好开心！", "满分状态！你真的太厉害了！", "能量满满！感觉什么都能做到呢！"].randomElement()!
        }
    }
    
    // MARK: - 萌宠风格
    private func getPetDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["喵呜...主人看起来好累，快休息嘛~", "汪...主人要好好照顾自己呀", "人家担心你呢...早点睡好不好？"].randomElement()!
        case .weak:
            return ["喵~主人有点累了吧，摸摸头~", "汪汪，陪主人走走散散心吧？", "主人加油呀，相信你的！"].randomElement()!
        case .normal:
            return ["喵~今天还不错呢！", "汪！主人状态可以哦！", "嘿嘿，今天的主人挺好的~"].randomElement()!
        case .good:
            return ["喵喵喵！主人今天好棒！", "汪汪汪！开心开心！", "耶！主人状态超好的！"].randomElement()!
        case .excellent:
            return ["喵呜！！主人太厉害了！！", "汪汪汪！！满分！超爱！", "主人最棒了！比心心~💕"].randomElement()!
        }
    }
    
    // MARK: - 智者风格
    private func getSageDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["身体是一切的根本，请务必注意休息。", "欲速则不达，先养精蓄锐吧。", "健康才是最大的财富，今天早点休息。"].randomElement()!
        case .weak:
            return ["劳逸结合，才能走得更远。", "适当的休息是为了更好的前进。", "状态稍有不足，注意调整节奏。"].randomElement()!
        case .normal:
            return ["中庸之道，稳定是一种力量。", "保持当前的节奏，循序渐进。", "平稳的一天，也是美好的一天。"].randomElement()!
        case .good:
            return ["很好的状态，继续保持。", "今天的付出，明天会看到收获。", "良好的习惯正在形成，值得肯定。"].randomElement()!
        case .excellent:
            return ["出色的状态！这是自律的回报。", "今天的你，展现了最好的自己。", "优秀！坚持的力量是无穷的。"].randomElement()!
        }
    }
}

enum AIError: Error {
    case invalidURL
    case requestFailed
    case parseError
}
