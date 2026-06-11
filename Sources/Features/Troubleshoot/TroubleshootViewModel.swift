import SwiftUI
import SwiftData

@MainActor
class TroubleshootViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var trade: TradeType = .plumbing
    @Published var isLoading = false

    var modelContext: ModelContext?

    private var history: [[String: String]] = []

    private var systemPrompt: String {
        """
        You are an expert \(trade.label.lowercased()) technician providing real-time on-site troubleshooting assistance.
        The technician is on a job and needs step-by-step guidance.
        Rules:
        - Ask clarifying questions when needed (one at a time)
        - Give numbered, actionable steps
        - Mention safety warnings when relevant (⚠️)
        - Suggest parts/tools needed
        - Keep each response focused and scannable on a phone screen
        """
    }

    func ask() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        messages.append(ChatMessage(content: text, isUser: true))
        history.append(["role": "user", "content": text])
        isLoading = true
        defer { isLoading = false }
        do {
            let reply = try await OpenAIService.chatWithHistory(system: systemPrompt, history: history)
            messages.append(ChatMessage(content: reply, isUser: false))
            history.append(["role": "assistant", "content": reply])
            if history.count > 40 { history.removeFirst(2) }
        } catch {
            messages.append(ChatMessage(content: "⚠️ \(error.localizedDescription)", isUser: false))
        }
    }

    func reset() {
        saveIfNeeded()
        messages = []
        history = []
        input = ""
    }

    private func saveIfNeeded() {
        guard let ctx = modelContext else { return }
        let lastAI = messages.last(where: { !$0.isUser })?.content ?? ""
        guard !lastAI.isEmpty else { return }
        let userMessages = messages.filter { $0.isUser }.map { $0.content }
        let title = String((userMessages.first ?? "Troubleshoot Session").prefix(60))
        let inputSummary = userMessages.joined(separator: "\n\n")
        let record = JobRecord(
            type: .troubleshoot,
            trade: trade.label,
            title: title,
            inputText: inputSummary,
            resultText: lastAI
        )
        ctx.insert(record)
    }
}
