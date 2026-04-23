import SwiftUI

/// Settings: Claude API key + proximity alerts toggle.
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var proximityEnabled: Bool = ProximityManager.shared.isEnabled

    var body: some View {
        Form {
            Section {
                SecureField("sk-ant-...", text: $apiKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Claude API Key")
            } footer: {
                Text("Stored in iOS Keychain. Used for categorization and extraction.")
            }

            Section {
                Button("Save") { save() }
                    .disabled(apiKey.isEmpty)
                Button("Clear", role: .destructive) { clear() }
            }

            Section {
                Toggle("Proximity alerts", isOn: $proximityEnabled)
                    .onChange(of: proximityEnabled) { _, newValue in
                        Task { await toggleProximity(newValue) }
                    }
            } header: {
                Text("Nearby Restaurants")
            } footer: {
                Text("Get a local notification when you're within \("150m") of a saved restaurant. Uses low-power region monitoring; no continuous GPS.")
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(isError ? .red : .green)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadExisting)
    }

    private func toggleProximity(_ enabled: Bool) async {
        if enabled {
            await ProximityManager.shared.enable()
        } else {
            ProximityManager.shared.disable()
        }
    }

    private func loadExisting() {
        do {
            if let existing = try KeychainStore.load(KeychainStore.claudeAPIKeyAccount) {
                apiKey = existing
            }
        } catch {
            show("Failed to load: \(error)", isError: true)
        }
    }

    private func save() {
        do {
            try KeychainStore.save(apiKey, for: KeychainStore.claudeAPIKeyAccount)
            show("Saved.", isError: false)
        } catch {
            show("Save failed: \(error)", isError: true)
        }
    }

    private func clear() {
        do {
            try KeychainStore.delete(KeychainStore.claudeAPIKeyAccount)
            apiKey = ""
            show("Cleared.", isError: false)
        } catch {
            show("Clear failed: \(error)", isError: true)
        }
    }

    private func show(_ message: String, isError: Bool) {
        self.statusMessage = message
        self.isError = isError
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
