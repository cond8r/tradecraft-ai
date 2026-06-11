import Foundation
import UIKit

struct OpenAIService {

    // MARK: - Chat completion (text)
    static func chat(system: String, user: String) async throws -> String {
        let body: [String: Any] = [
            "model": Config.chatModel,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ]
        ]
        return try await postChat(body: body)
    }

    // MARK: - Vision (image + text)
    static func vision(prompt: String, image: UIImage) async throws -> String {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw AppError.imageEncoding
        }
        let b64 = jpeg.base64EncodedString()
        let body: [String: Any] = [
            "model": Config.chatModel,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text",      "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)", "detail": "high"]]
                ]
            ]],
            "max_tokens": 1500
        ]
        return try await postChat(body: body)
    }

    // MARK: - Whisper transcription
    static func transcribe(audioURL: URL) async throws -> String {
        guard let endpoint = URL(string: "\(Config.baseURL)/audio/transcriptions") else {
            throw AppError.badResponse("Invalid transcription URL")
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        let audioData = try Data(contentsOf: audioURL)
        let filename  = audioURL.lastPathComponent
        let mime      = audioURL.pathExtension == "mp4" ? "audio/mp4" : "audio/m4a"

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(Config.whisperModel)\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
        data.append(audioData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = data

        let (respData, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any]
        guard let text = json?["text"] as? String else {
            throw AppError.transcriptionFailed(String(data: respData, encoding: .utf8) ?? "")
        }
        return text
    }

    // MARK: - Chat with history (for CustomerBot)
    static func chatWithHistory(system: String, history: [[String: String]]) async throws -> String {
        var messages: [[String: Any]] = [["role": "system", "content": system]]
        messages.append(contentsOf: history)
        let body: [String: Any] = ["model": Config.chatModel, "messages": messages]
        return try await postChat(body: body)
    }

    // MARK: - Private helper
    private static func postChat(body: [String: Any]) async throws -> String {
        guard !Config.openAIKey.isEmpty else { throw AppError.noAPIKey }
        guard let endpoint = URL(string: "\(Config.baseURL)/chat/completions") else {
            throw AppError.badResponse("Invalid chat URL")
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw AppError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        let json  = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let msg   = choices?.first?["message"] as? [String: Any]
        guard let content = msg?["content"] as? String else {
            throw AppError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AppError: LocalizedError {
    case noAPIKey
    case imageEncoding
    case transcriptionFailed(String)
    case httpError(Int, String)
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:               return "API Key not set. Go to Settings to add it."
        case .imageEncoding:          return "Failed to encode image."
        case .transcriptionFailed(let d): return "Transcription failed: \(d)"
        case .httpError(let c, let d):    return "HTTP \(c): \(d)"
        case .badResponse(let d):         return "Unexpected response: \(d)"
        }
    }
}
