import SwiftUI

// Centralises API key reads/writes.
// mmlApiKey is @AppStorage so SwiftUI views re-render immediately when it changes.
// The key is also written to Keychain so it survives app reinstalls and iCloud backup.
@MainActor
final class AppSettings {
    // Backing UserDefaults key — used for SwiftUI reactivity only.
    static let apiKeyDefaultsKey = "mml_api_key"

    static func loadApiKey() -> String {
        UserDefaults.standard.string(forKey: apiKeyDefaultsKey) ?? KeychainStore.mmlApiKey ?? ""
    }

    static func saveApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(trimmed, forKey: apiKeyDefaultsKey)
        KeychainStore.mmlApiKey = trimmed.isEmpty ? nil : trimmed
    }
}
