import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppSettings.apiKeyDefaultsKey) private var savedKey = ""
    @State private var apiKey = ""
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Welcome to Fisu")
                    .font(.largeTitle.bold())

                Text("Enter your MML Karttakuvapalvelu api-key to load the Finnish topo map with depth information.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MML API Key")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Paste your api-key here", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Button {
                    AppSettings.saveApiKey(apiKey)
                    savedKey = apiKey.trimmingCharacters(in: .whitespaces)
                    isPresented = false
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Skip for now") {
                    isPresented = false
                }
                .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
