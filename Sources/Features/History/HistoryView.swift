import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \JobRecord.createdAt, order: .reverse) private var records: [JobRecord]
    @Environment(\.modelContext) private var context
    @State private var selectedType: JobRecordType? = nil
    @State private var selectedRecord: JobRecord?

    private var filtered: [JobRecord] {
        guard let t = selectedType else { return records }
        return records.filter { $0.type == t }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No records yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your quotes, diagnoses and work orders will appear here.")
                    )
                } else {
                    List {
                        ForEach(filtered) { record in
                            Button { selectedRecord = record } label: {
                                RecordRow(record: record)
                            }
                            .tint(.primary)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(filtered[i]) }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { selectedType = nil }
                        Divider()
                        ForEach(JobRecordType.allCases, id: \.self) { t in
                            Button(t.rawValue) { selectedType = t }
                        }
                    } label: {
                        Image(systemName: selectedType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                JobRecordDetailView(record: record)
            }
        }
    }
}

private struct RecordRow: View {
    let record: JobRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.icon)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(record.type.color, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(record.trade).font(.caption).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.secondary)
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension JobRecordType {
    var icon: String {
        switch self {
        case .diagnosis:    return "camera.fill"
        case .quote:        return "doc.text.fill"
        case .workOrder:    return "mic.fill"
        case .troubleshoot: return "wrench.and.screwdriver.fill"
        }
    }
    var color: Color {
        switch self {
        case .diagnosis:    return .blue
        case .quote:        return .green
        case .workOrder:    return .purple
        case .troubleshoot: return .red
        }
    }
}
