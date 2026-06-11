import Foundation
import Security

enum Config {
    static var openAIKey: String {
        get { KeychainHelper.read(key: "openai_api_key") ?? "" }
        set { KeychainHelper.save(key: "openai_api_key", value: newValue) }
    }
    static let baseURL    = "https://api.openai.com/v1"
    static let chatModel  = "gpt-4o"
    static let whisperModel = "whisper-1"
}

enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
