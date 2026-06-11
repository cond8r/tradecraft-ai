import SwiftUI

struct JobRecordDetailView: View {
    let record: JobRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meta
                    HStack {
                        Label(record.type.rawValue, systemImage: record.type.icon)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(record.type.color.opacity(0.15), in: Capsule())
                            .foregroundStyle(record.type.color)
                        Spacer()
                        Text(record.createdAt.formatted(date: .long, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Input
                    if !record.inputText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Input").font(.headline)
                            Text(record.inputText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }

                    Divider()

                    // Result
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Result").font(.headline)
                        Text(record.resultText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
            .navigationTitle(record.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if record.type == .quote {
                        Button {
                            pdfData = InvoicePDFGenerator.generate(record: record)
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = pdfData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
