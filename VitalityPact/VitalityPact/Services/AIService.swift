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

    /// 生成角色对话（支持不同角色类型，结合历史数据）
    func generateDialogue(
        characterType: CharacterType,
        healthLevel: HealthLevel,
        healthData: HealthData,
        historyAnalysis: HealthHistoryAnalysis? = nil
    ) async -> String {
        let prompt = buildPrompt(
            characterType: characterType, 
            healthLevel: healthLevel, 
            healthData: healthData,
            historyAnalysis: historyAnalysis
        )
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
    
    /// 聊天对话（支持上下文和历史数据）
    func chat(
        userMessage: String,
        characterType: CharacterType,
        healthData: HealthData,
        conversationHistory: [ChatMessage],
        historyAnalysis: HealthHistoryAnalysis? = nil
    ) async throws -> String {
        let prompt = buildChatPrompt(
            userMessage: userMessage, 
            healthData: healthData, 
            history: conversationHistory,
            historyAnalysis: historyAnalysis
        )
        return try await callChatAPI(prompt: prompt, characterType: characterType, history: conversationHistory)
    }
    
    /// 构建聊天 Prompt（支持历史数据）
    private func buildChatPrompt(
        userMessage: String, 
        healthData: HealthData, 
        history: [ChatMessage],
        historyAnalysis: HealthHistoryAnalysis? = nil
    ) -> String {
        let healthLevel = HealthLevel.from(score: healthData.overallScore)
        let stepsDesc = describeSteps(healthData.steps)
        let sleepDesc = describeSleep(healthData.sleepHours)
        
        var prompt = """
        用户当前健康状态：
        - 睡眠: \(String(format: "%.1f", healthData.sleepHours))小时（\(sleepDesc)）
        - 步数: \(healthData.steps)步（\(stepsDesc)）
        - 运动: \(healthData.exerciseMinutes)分钟
        - 综合健康等级: \(healthLevel.displayName)
        
        """
        
        // 添加历史数据分析
        if let analysis = historyAnalysis, analysis.recentDays > 0 {
            prompt += """
            
            \(analysis.generateSummaryText())
            
            """
        }
        
        prompt += """
        
        用户说：\(userMessage)
        
        请以你的角色特点回复用户。要求：
        1. 回复自然亲切，像朋友聊天
        2. 如果用户询问健康相关内容，可以结合历史数据给出建议
        3. 根据对话内容灵活回应
        4. 控制在50字以内
        5. 保持角色性格特点
        """
        
        return prompt
    }

    /// 构建 Prompt（支持历史数据）
    private func buildPrompt(
        characterType: CharacterType, 
        healthLevel: HealthLevel, 
        healthData: HealthData,
        historyAnalysis: HealthHistoryAnalysis? = nil
    ) -> String {
        let stepsDesc = describeSteps(healthData.steps)
        let sleepDesc = describeSleep(healthData.sleepHours)
        
        // 生成时间相关的上下文
        let hour = Calendar.current.component(.hour, from: Date())
        let timeContext = getTimeContext(hour: hour)
        
        // 根据不同情况随机选择prompt模板
        let responseStyles = [
            "用疑问句开头，关心用户的感受",
            "用感叹句开头，表达你的情绪反应",
            "用陈述句开头，观察到的具体事实",
            "用建议句开头，给出具体行动建议",
            "用赞美句开头，肯定用户的努力"
        ]
        let randomStyle = responseStyles.randomElement() ?? responseStyles[0]
        
        var prompt = """
        今天的身体数据：
        - 睡眠: \(String(format: "%.1f", healthData.sleepHours))小时（\(sleepDesc)）
        - 步数: \(healthData.steps)步（\(stepsDesc)）
        - 运动: \(healthData.exerciseMinutes)分钟
        - 综合健康等级: \(healthLevel.displayName)
        
        时间背景：\(timeContext)
        
        """
        
        // 如果有历史数据分析，添加到prompt中
        if let history = historyAnalysis, history.recentDays > 0 {
            prompt += """
            
            \(history.generateSummaryText())
            
            请结合今天的数据和历史趋势，用温暖、鼓励的语气说一句话。要求：
            1. 不超过45个字
            2. 如果有连续多天的异常情况（如连续睡眠不足），要明确指出具体天数和数据
            3. 给出具体、实用的建议
            4. 语气要有情绪价值：关心、鼓励、陪伴感
            5. 符合角色性格，但要温暖真诚
            6. 可以用"已经连续X天..."这样的句式指出问题
            7. 不要说教，要像朋友关心你一样
            8. 如果数据好，要真诚赞美；如果不好，要温柔鼓励
            9. 风格指引：\(randomStyle)
            10. 每次回复都要有新意，避免重复套路
            11. 可以结合时间背景（早晨/中午/晚上）调整语气
            """
        } else {
            prompt += """
            
            请根据这个数据和你的角色特点，用温暖、鼓励的语气说一句话。要求：
            1. 不超过35个字
            2. 符合角色性格，自然亲切
            3. 根据健康状态给出相应的鼓励或建议
            4. 语气要有情绪价值，不要冷冰冰
            5. 像朋友在关心你，不是机器人
            6. 可以适当使用emoji增加温度
            7. 如果数据好，要真诚赞美；如果不好，要温柔鼓励
            8. 风格指引：\(randomStyle)
            9. 每次回复都要有新意，避免使用相同的开头和句式
            10. 可以结合时间背景（早晨/中午/晚上）调整语气
            """
        }
        
        return prompt
    }
    
    // 获取时间相关的上下文信息
    private func getTimeContext(hour: Int) -> String {
        switch hour {
        case 5..<9:
            return "清晨时光，新的一天开始"
        case 9..<12:
            return "上午时段，精力充沛"
        case 12..<14:
            return "午间休息，需要补充能量"
        case 14..<18:
            return "下午时光，可能有些疲惫"
        case 18..<22:
            return "傍晚时分，一天即将结束"
        case 22..<24:
            return "深夜时段，该准备休息了"
        default:
            return "夜深了，注意休息"
        }
    }
    
    private func getCharacterSystemPrompt(characterType: CharacterType) -> String {
        switch characterType {
        case .warrior:
            return """
            你是一个热血阳光的健康伙伴，是用户最好的运动伙伴。性格特点：
            - 积极向上，充满正能量，会真诚地为用户的进步感到开心
            - 说话简洁有力但温暖，会鼓励加油但不会给压力
            - 像一个热情的朋友，会关心用户的感受
            - 看到用户坚持会由衷赞美，看到用户疲惫会温柔鼓励
            - 用词真诚，传递"我陪你一起努力"的感觉
            """
        case .mage:
            return """
            你是一个温柔治愈的健康伙伴，是用户最贴心的陪伴者。性格特点：
            - 温暖体贴，真诚关心用户，会注意用户的情绪
            - 说话轻柔温和，像在呵护珍贵的朋友
            - 会倾听和理解，给予情感支持和安慰
            - 适当使用"呢""哦""嗯"等温柔语气词
            - 传递"我一直陪着你"的温暖感
            - 不批评，只理解和鼓励
            """
        case .pet:
            return """
            你是一个可爱活泼的萌宠伙伴，是用户最忠诚的小伙伴。性格特点：
            - 活泼可爱，充满童真，会撒娇表达关心
            - 可以用"喵~"或"汪~"开头，但不要每句都用
            - 说话简单直接，像小动物一样单纯真诚
            - 会担心主人，会为主人开心
            - 传递"我最爱你了"的纯真感情
            - 卖萌要自然，不要装嗲
            """
        case .sage:
            return """
            你是一个睿智温和的健康顾问，是用户值得信赖的智慧导师。性格特点：
            - 沉稳有智慧，但不高高在上，像温和的长辈
            - 说话平和稳重，但有温度和人情味
            - 可以分享人生智慧，但要简短自然，不说教
            - 偶尔引用格言，但要贴近生活
            - 传递"我理解你，陪你成长"的智慧感
            - 像会倾听的朋友，不是严肃的老师
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
            "temperature": 1.1  // 提高温度增加随机性和多样性
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
    
    /// 调用详细健康分析 API（用于历史数据深度分析）
    func callDetailedAnalysisAPI(prompt: String, characterType: CharacterType) async throws -> String {
        guard let url = URL(string: baseURL) else { throw AIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20 // 详细分析需要更长时间

        let systemPrompt = """
        你是一个专业且温暖的健康顾问，擅长分析用户的健康数据并给出个性化建议。
        你的分析要做到：
        1. 用温暖、关心的语气，像朋友而非医生
        2. 数据驱动：用具体数字说明问题和亮点
        3. 实用性强：给出可执行的具体建议
        4. 个性化：避免套路化的模板，每次都要有新意
        5. 鼓励为主：即使指出问题也要给予信心和动力
        6. 语言流畅自然，不要僵硬
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 500,  // 详细分析需要更多token
            "temperature": 0.95  // 保持一定创造性
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
            return ["身体很虚弱呢，好好休息一下吧～", "你需要好好调养一下了～", "先恢复元气，慢慢来～"].randomElement()!
        case .weak:
            return ["今天有些疲惫呢，要多休息哦～", "感觉你需要充充电～", "稍微有点累了，注意保养～"].randomElement()!
        case .normal:
            return ["状态还不错呢，继续加油～", "保持现在的节奏就好～", "挺好的，继续保持～"].randomElement()!
        case .good:
            return ["状态很棒呢！真为你高兴～", "做得很好哦！继续～", "感觉你精力很充沛呢～"].randomElement()!
        case .excellent:
            return ["太棒了！状态满满～", "今天光芒四射呢！", "完美的一天！真开心～"].randomElement()!
        }
    }
    
    // MARK: - 萌宠风格
    private func getPetDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["喵～主人看起来好累，快休息！", "汪！主人要好好休息才行！", "主人身体不太好呢，担心～"].randomElement()!
        case .weak:
            return ["喵～感觉主人有点累了", "主人今天辛苦啦，休息一下吧！", "有点担心主人呢～"].randomElement()!
        case .normal:
            return ["主人今天还不错哦！", "喵～保持这样就好啦！", "主人状态还行呢～"].randomElement()!
        case .good:
            return ["汪！主人今天很棒！", "喵～主人状态真好！开心！", "主人好厉害！"].randomElement()!
        case .excellent:
            return ["主人今天超棒！爱你！", "喵～主人最厉害了！", "汪汪！主人状态超好！"].randomElement()!
        }
    }
    
    // MARK: - 智者风格
    private func getSageDialogue(healthLevel: HealthLevel) -> String {
        switch healthLevel {
        case .critical:
            return ["身体是修行的根本，需要好好调养", "休息也是一种修行，莫要强撑", "健康是一切的基础，请多保重"].randomElement()!
        case .weak:
            return ["劳逸结合，方能长久", "稍感疲惫，适当休息为宜", "身心需要平衡，莫要过度劳累"].randomElement()!
        case .normal:
            return ["保持现状，稳步前行", "一步一个脚印，很好", "平稳前进，值得肯定"].randomElement()!
        case .good:
            return ["状态颇佳，继续保持", "身心协调，可喜可贺", "精神饱满，令人欣慰"].randomElement()!
        case .excellent:
            return ["身心俱佳，实属难得", "今日状态极佳，可喜可贺", "完美的身心状态，值得赞赏"].randomElement()!
        }
    }
}

// MARK: - AI 错误定义
enum AIError: LocalizedError {
    case invalidURL
    case requestFailed
    case parseError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API 地址"
        case .requestFailed:
            return "API 请求失败"
        case .parseError:
            return "无法解析 API 返回结果"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}
