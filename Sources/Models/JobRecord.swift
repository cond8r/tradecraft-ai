import Foundation
import SwiftData

enum JobRecordType: String, Codable, CaseIterable {
    case diagnosis    = "Diagnosis"
    case quote        = "Quote"
    case workOrder    = "Work Order"
    case troubleshoot = "Troubleshoot"
}

@Model
final class JobRecord {
    var id: UUID
    var type: JobRecordType
    var trade: String
    var title: String
    var inputText: String
    var resultText: String
    var createdAt: Date

    init(type: JobRecordType, trade: String, title: String, inputText: String, resultText: String) {
        self.id         = UUID()
        self.type       = type
        self.trade      = trade
        self.title      = title
        self.inputText  = inputText
        self.resultText = resultText
        self.createdAt  = Date()
    }
}
