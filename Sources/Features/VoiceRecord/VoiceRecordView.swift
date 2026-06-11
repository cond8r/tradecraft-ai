import SwiftUI
import SwiftData

struct VoiceRecordView: View {
    @StateObject private var vm = VoiceRecordViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Record button
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(vm.isRecording ? Color.red.opacity(0.15) : Color.purple.opacity(0.1))
                                .frame(width: 140, height: 140)
                            Circle()
                                .fill(vm.isRecording ? Color.red : Color.purple)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: vm.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: vm.isRecording ? .red.opacity(0.4) : .purple.opacity(0.3), radius: 12)
                                .scaleEffect(vm.isRecording ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                           value: vm.isRecording)
                        }
                        .onTapGesture {
                            vm.isRecording ? vm.stopRecording() : vm.startRecording()
                        }

                        Text(vm.isRecording ? "Tap to stop" : "Tap to record")
                            .foregroundStyle(.secondary)

                        if vm.isRecording {
                            Text(vm.recordingTime)
                                .font(.title2.monospacedDigit())
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.top, 20)

                    // Transcribe button
                    if vm.hasRecording {
                        Button {
                            Task { await vm.transcribeAndGenerate() }
                        } label: {
                            HStack {
                                if vm.isProcessing { ProgressView().tint(.white) }
                                Text(vm.isProcessing ? "Processing…" : "Transcribe & Generate Work Order")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .padding(.horizontal)
                    }

                    // Transcript
                    if !vm.transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transcript").font(.headline)
                            Text(vm.transcript)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                    }

                    // Work order
                    if !vm.workOrder.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Work Order").font(.headline)
                            ResultCard(text: vm.workOrder)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Voice Record")
            .onAppear { vm.modelContext = modelContext }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage)
            }
        }
    }
}
