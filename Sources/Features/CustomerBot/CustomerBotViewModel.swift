import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

@MainActor
class CustomerBotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var isLoading = false
    @Published var showConfig = false

    // Business config
    @Published var businessName = ""
    @Published var tradeDescription = ""
    @Published var serviceArea = ""
    @Published var businessHours = ""
    @Published var emergencyContact = ""

    private var systemPrompt: String {
        """
        You are a professional customer service assistant for \(businessName.isEmpty ? "a trade service company" : businessName).
        Trade: \(tradeDescription.isEmpty ? "general contracting" : tradeDescription)
        Service area: \(serviceArea.isEmpty ? "local area" : serviceArea)
        Business hours: \(businessHours.isEmpty ? "Mon-Fri 8am-5pm" : businessHours)
        \(emergencyContact.isEmpty ? "" : "Emergency contact: \(emergencyContact)")

        Respond to customer inquiries professionally and concisely. Help with:
        - Scheduling appointments
        - Answering questions about services
        - Providing rough estimates (always note final pricing requires on-site assessment)
        - Emergency vs non-emergency triage
        Keep responses brief and friendly. Always end with a clear next step.
        """
    }

    private var history: [[String: String]] = []

    func send() async {
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
            // Keep history bounded to last 20 turns
            if history.count > 40 { history.removeFirst(2) }
        } catch {
            messages.append(ChatMessage(content: "⚠️ \(error.localizedDescription)", isUser: false))
        }
    }
}
