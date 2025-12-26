//
//  ChatView.swift
//  VitalityPact
//
//  与伙伴聊天的视图
//

import SwiftUI
import Combine

// MARK: - 聊天消息模型
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - 聊天管理器
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private let aiService = AIService.shared
    private let healthHistory = HealthHistoryManager.shared
    
    /// 发送消息并获取回复
    func sendMessage(_ content: String, characterType: CharacterType, healthData: HealthData) async {
        // 添加用户消息
        let userMessage = ChatMessage(content: content, isUser: true)
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
        }
        
        // 获取历史数据分析
        let historyAnalysis = healthHistory.analyzeRecent(days: 7)
        
        // 获取 AI 回复
        do {
            let reply = try await aiService.chat(
                userMessage: content,
                characterType: characterType,
                healthData: healthData,
                conversationHistory: messages,
                historyAnalysis: historyAnalysis
            )
            
            let aiMessage = ChatMessage(content: reply, isUser: false)
            await MainActor.run {
                messages.append(aiMessage)
                isLoading = false
            }
        } catch {
            let errorMessage = ChatMessage(content: "抱歉，我现在有点累，稍后再聊吧～", isUser: false)
            await MainActor.run {
                messages.append(errorMessage)
                isLoading = false
            }
        }
    }
    
    /// 清空聊天记录
    func clearMessages() {
        messages.removeAll()
    }
}

// MARK: - 聊天视图
struct ChatView: View {
    @EnvironmentObject var healthManager: HealthStoreManager
    @StateObject private var userSettings = UserSettings.shared
    @ObservedObject var imageCharacterManager = ImageCharacterManager.shared
    @StateObject private var chatManager = ChatManager()
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var currentCharacterType: CharacterType {
        if imageCharacterManager.useImageCharacter,
           let character = imageCharacterManager.selectedCharacter {
            return character.style
        }
        return userSettings.selectedCharacterType
    }
    
    var partnerName: String {
        if imageCharacterManager.useImageCharacter,
           let character = imageCharacterManager.selectedCharacter {
            return character.name
        }
        return userSettings.selectedCharacterType.displayName
    }
    
    var partnerIcon: String {
        if imageCharacterManager.useImageCharacter,
           let character = imageCharacterManager.selectedCharacter {
            return "🖼️"
        }
        return userSettings.selectedCharacterType.icon
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 欢迎消息
                            if chatManager.messages.isEmpty {
                                WelcomeMessageView(
                                    partnerName: partnerName,
                                    partnerIcon: partnerIcon
                                )
                                .padding(.top, 20)
                            }
                            
                            // 聊天消息
                            ForEach(chatManager.messages) { message in
                                MessageBubble(
                                    message: message,
                                    characterType: currentCharacterType
                                )
                                .id(message.id)
                            }
                            
                            // 加载指示器
                            if chatManager.isLoading {
                                TypingIndicator(characterType: currentCharacterType)
                                    .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatManager.messages.count) { _, _ in
                        // 滚动到最新消息
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatManager.isLoading) { _, isLoading in
                        if isLoading {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 输入框
                HStack(spacing: 12) {
                    TextField("输入消息...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                ? Color.gray 
                                : currentCharacterType.themeColor
                            )
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("与\(partnerName)聊天")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        chatManager.clearMessages()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                    }
                    .disabled(chatManager.messages.isEmpty)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        
        Task {
            await chatManager.sendMessage(
                message,
                characterType: currentCharacterType,
                healthData: healthManager.healthData
            )
        }
    }
}

// MARK: - 欢迎消息
struct WelcomeMessageView: View {
    let partnerName: String
    let partnerIcon: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text(partnerIcon)
                .font(.system(size: 60))
            
            Text("嗨！我是\(partnerName)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("有什么想聊的吗？")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - 消息气泡
struct MessageBubble: View {
    let message: ChatMessage
    let characterType: CharacterType
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                        ? characterType.themeColor.opacity(0.2)
                        : Color(UIColor.secondarySystemBackground)
                    )
                    .foregroundColor(.primary)
                    .cornerRadius(18)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 输入中指示器
struct TypingIndicator: View {
    let characterType: CharacterType
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(characterType.themeColor)
                        .frame(width: 8, height: 8)
                        .opacity(dotCount == index ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(18)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(HealthStoreManager.shared)
}
