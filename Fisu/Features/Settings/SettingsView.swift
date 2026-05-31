import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var apiKey = ""
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
                            .onSubmit { appSettings.mmlApiKey = apiKey }
                    }
                    Button("Save API Key") {
                        appSettings.mmlApiKey = apiKey
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces) == appSettings.mmlApiKey)

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
            .onAppear { apiKey = appSettings.mmlApiKey }
        }
    }
}
