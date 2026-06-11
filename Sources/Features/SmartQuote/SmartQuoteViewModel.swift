import SwiftUI
import SwiftData

enum Region: String, CaseIterable, Identifiable {
    case us_west, us_east, us_south, us_midwest, uk, australia, canada
    var id: String { rawValue }
    var label: String {
        switch self {
        case .us_west:    return "US West"
        case .us_east:    return "US East"
        case .us_south:   return "US South"
        case .us_midwest: return "US Midwest"
        case .uk:         return "UK"
        case .australia:  return "Australia"
        case .canada:     return "Canada"
        }
    }
}

@MainActor
class SmartQuoteViewModel: ObservableObject {
    @Published var jobDescription = ""
    @Published var trade: TradeType = .plumbing
    @Published var region: Region = .us_west
    @Published var result = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    var modelContext: ModelContext?

    func generateQuote() async {
        isLoading = true
        result = ""
        defer { isLoading = false }
        let system = """
        You are a professional \(trade.label.lowercased()) estimator in \(region.label).
        Generate a detailed job quote including:
        1. Labor hours and rate (use typical \(region.label) market rates)
        2. Materials list with estimated costs
        3. Total estimate (low / mid / high range)
        4. Notes or warnings
        Format clearly with sections and dollar amounts.
        """
        do {
            result = try await OpenAIService.chat(system: system, user: jobDescription)
            saveRecord()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveRecord() {
        guard let ctx = modelContext, !result.isEmpty else { return }
        let title = String(jobDescription.prefix(60))
        let record = JobRecord(
            type: .quote,
            trade: trade.label,
            title: title.isEmpty ? "Quote" : title,
            inputText: jobDescription,
            resultText: result
        )
        ctx.insert(record)
    }
}
