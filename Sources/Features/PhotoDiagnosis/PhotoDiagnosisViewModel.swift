import SwiftUI
import SwiftData

enum TradeType: String, CaseIterable, Identifiable {
    case plumbing, electrical, hvac, general
    var id: String { rawValue }
    var label: String {
        switch self {
        case .plumbing:   return "Plumbing"
        case .electrical: return "Electrical"
        case .hvac:       return "HVAC"
        case .general:    return "General"
        }
    }
    var systemPrompt: String {
        "You are an expert \(label.lowercased()) technician. The user will show you a photo of an issue. Identify: 1) What the problem is, 2) Likely cause, 3) Recommended repair steps, 4) Estimated time & materials needed. Be concise and practical."
    }
}

@MainActor
class PhotoDiagnosisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var trade: TradeType = .plumbing
    @Published var result = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    var modelContext: ModelContext?

    func analyse() async {
        guard let img = selectedImage else { return }
        isLoading = true
        result = ""
        defer { isLoading = false }
        do {
            result = try await OpenAIService.vision(
                prompt: "Please diagnose this \(trade.label.lowercased()) issue shown in the photo.",
                image: img
            )
            saveRecord()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveRecord() {
        guard let ctx = modelContext, !result.isEmpty else { return }
        let record = JobRecord(
            type: .diagnosis,
            trade: trade.label,
            title: "\(trade.label) Diagnosis",
            inputText: "",
            resultText: result
        )
        ctx.insert(record)
    }
}
