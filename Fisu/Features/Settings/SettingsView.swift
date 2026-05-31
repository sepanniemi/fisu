import SwiftUI

struct SettingsView: View {
    @State private var apiKey = KeychainStore.mmlApiKey ?? ""
    @AppStorage("keepScreenAwake") private var keepScreenAwake = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Map") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MML API Key")
                            .font(.subheadline.weight(.medium))
                        SecureField("api-key", text: $apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { KeychainStore.mmlApiKey = apiKey.isEmpty ? nil : apiKey }
                    }
                    Button("Save API Key") {
                        KeychainStore.mmlApiKey = apiKey.isEmpty ? nil : apiKey
                    }
                    .disabled(apiKey == (KeychainStore.mmlApiKey ?? ""))

                    Text("© Maanmittauslaitos — open data licence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tracking") {
                    Toggle("Keep screen awake during trip", isOn: $keepScreenAwake)
                }

                Section("iCloud") {
                    HStack {
                        Text("Sync status")
                        Spacer()
                        Text("Synced")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
