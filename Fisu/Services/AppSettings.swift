import Observation

@Observable @MainActor
final class AppSettings {
    var mmlApiKey: String {
        didSet {
            let trimmed = mmlApiKey.trimmingCharacters(in: .whitespaces)
            KeychainStore.mmlApiKey = trimmed.isEmpty ? nil : trimmed
            if mmlApiKey != trimmed { mmlApiKey = trimmed }
        }
    }

    init() {
        mmlApiKey = KeychainStore.mmlApiKey ?? ""
    }
}
