import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var key = Config.openAIKey

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-...", text: $key)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Your key is stored locally on device and never sent anywhere except OpenAI.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Config.openAIKey = key
                        dismiss()
                    }
                    .bold()
                    .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
