import SwiftUI
import SwiftData

struct SmartQuoteView: View {
    @StateObject private var vm = SmartQuoteViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Job description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Job Description").font(.headline)
                        TextEditor(text: $vm.jobDescription)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Group {
                                    if vm.jobDescription.isEmpty {
                                        Text("e.g. Replace kitchen faucet, fix leak under sink, install new shut-off valves")
                                            .foregroundStyle(.tertiary)
                                            .padding(14)
                                            .allowsHitTesting(false)
                                    }
                                }, alignment: .topLeading
                            )
                    }

                    // Options row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trade").font(.subheadline).foregroundStyle(.secondary)
                            Picker("", selection: $vm.trade) {
                                ForEach(TradeType.allCases) { t in Text(t.label).tag(t) }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Region").font(.subheadline).foregroundStyle(.secondary)
                            Picker("", selection: $vm.region) {
                                ForEach(Region.allCases) { r in Text(r.label).tag(r) }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Button {
                        Task { await vm.generateQuote() }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView().tint(.white) }
                            Text(vm.isLoading ? "Generating…" : "Generate Quote")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(vm.jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)

                    if !vm.result.isEmpty {
                        ResultCard(text: vm.result)
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Quote")
            .onAppear { vm.modelContext = modelContext }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage)
            }
        }
    }
}
