import SwiftUI
import AVFoundation
import SwiftData

@MainActor
class VoiceRecordViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isProcessing = false
    @Published var transcript = ""
    @Published var workOrder = ""
    @Published var recordingTime = "0:00"
    @Published var showError = false
    @Published var errorMessage = ""

    var modelContext: ModelContext?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var seconds = 0
    private var audioURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("tradecraft_voice.m4a")
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "Microphone setup failed: \(error.localizedDescription)"
            showError = true
            return
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            recorder = try AVAudioRecorder(url: audioURL, settings: settings)
            recorder?.record()
            isRecording = true
            hasRecording = false
            transcript = ""
            workOrder = ""
            seconds = 0
            recordingTime = "0:00"
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.seconds += 1
                    let m = (self?.seconds ?? 0) / 60
                    let s = (self?.seconds ?? 0) % 60
                    self?.recordingTime = String(format: "%d:%02d", m, s)
                }
            }
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
            showError = true
        }
    }

    func stopRecording() {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        hasRecording = true
    }

    func transcribeAndGenerate() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            transcript = try await OpenAIService.transcribe(audioURL: audioURL)
            let system = """
            You are a trade service dispatcher. Convert the technician's voice note into a structured work order with:
            - Job Summary
            - Location / Customer
            - Work Performed
            - Parts Used
            - Time Spent
            - Follow-up Actions
            Be concise and professional.
            """
            workOrder = try await OpenAIService.chat(system: system, user: transcript)
            saveRecord()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveRecord() {
        guard let ctx = modelContext, !workOrder.isEmpty else { return }
        let record = JobRecord(
            type: .workOrder,
            trade: "General",
            title: String(transcript.prefix(60)).isEmpty ? "Work Order" : String(transcript.prefix(60)),
            inputText: transcript,
            resultText: workOrder
        )
        ctx.insert(record)
    }
}
