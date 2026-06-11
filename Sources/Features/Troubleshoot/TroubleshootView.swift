import SwiftUI
import SwiftData

struct TroubleshootView: View {
    @StateObject private var vm = TroubleshootViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Trade selector
                Picker("Trade", selection: $vm.trade) {
                    ForEach(TradeType.allCases) { t in Text(t.label).tag(t) }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Chat
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if vm.messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.system(size: 52))
                                        .foregroundStyle(.red.opacity(0.7))
                                    Text("Describe the problem you're facing on-site.\nAI will guide you step by step.")
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 60)
                            }
                            ForEach(vm.messages) { msg in
                                ChatBubble(message: msg).id(msg.id)
                            }
                            if vm.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking…").foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo(vm.messages.last?.id) }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Describe the issue…", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button {
                        Task { await vm.ask() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading ? .gray : .red)
                    }
                    .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
                }
                .padding()
            }
            .navigationTitle("Troubleshoot")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { vm.reset() }
                        .foregroundStyle(.red)
                }
            }
            .onAppear { vm.modelContext = modelContext }
        }
    }
}
