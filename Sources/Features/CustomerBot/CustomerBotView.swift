import SwiftUI

struct CustomerBotView: View {
    @StateObject private var vm = CustomerBotViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Business info banner
                if vm.businessName.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Set your business name in the banner below to personalise replies.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                }

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if vm.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking…").foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo(vm.messages.last?.id) }
                    }
                }

                Divider()

                // Input row
                HStack(spacing: 10) {
                    TextField("Customer inquiry…", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button {
                        Task { await vm.send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading ? .gray : .orange)
                    }
                    .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
                }
                .padding()
            }
            .navigationTitle("Customer Bot")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Config") { vm.showConfig = true }
                }
            }
            .sheet(isPresented: $vm.showConfig) {
                BotConfigView(vm: vm)
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.orange : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(message.isUser ? .white : .primary)
                .textSelection(.enabled)
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct BotConfigView: View {
    @ObservedObject var vm: CustomerBotViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Business Info") {
                    TextField("Business name", text: $vm.businessName)
                    TextField("Trade (e.g. plumbing, electrical)", text: $vm.tradeDescription)
                    TextField("Service area (e.g. Los Angeles, CA)", text: $vm.serviceArea)
                }
                Section("Availability") {
                    TextField("Hours (e.g. Mon-Fri 7am-6pm)", text: $vm.businessHours)
                    TextField("Emergency line (optional)", text: $vm.emergencyContact)
                }
            }
            .navigationTitle("Bot Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
