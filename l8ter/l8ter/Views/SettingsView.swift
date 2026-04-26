import SwiftUI

/// Settings: Claude API key + proximity alerts toggle.
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var proximityEnabled: Bool = ProximityManager.shared.isEnabled

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    TextField("sk-ant-...", text: $apiKey)
                        .font(.dsBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                    HStack {
                        Button("Save") { save() }
                            .buttonStyle(.borderless)
                            .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .foregroundStyle(Color.accent)
                        Spacer()
                        Button("Clear", role: .destructive) { clear() }
                            .buttonStyle(.borderless)
                    }
                } header: {
                    SectionLabel(text: "Claude API")
                } footer: {
                    Text("Stored in iOS Keychain. Used for categorization and extraction.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    Toggle("Alerts when nearby", isOn: $proximityEnabled)
                        .tint(Color.accent)
                        .onChange(of: proximityEnabled) { _, newValue in
                            Task { await toggleProximity(newValue) }
                        }
                } header: {
                    SectionLabel(text: "Proximity")
                } footer: {
                    Text("Get a local notification when you're within 150m of a saved restaurant. Uses low-power region monitoring; no continuous GPS.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.dsMetaSmall)
                            .foregroundStyle(isError ? Color.accent : Color.accentBright)
                    }
                }

                Section {
                    Text("L8TER · v0.7.0")
                        .font(.dsMetaTiny)
                        .tracking(DSTracking.metaTiny)
                        .foregroundStyle(Color.textDisabled)
                }
                .listRowBackground(Color.bgBase)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Settings")
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadExisting)
    }

    private func toggleProximity(_ enabled: Bool) async {
        if enabled { await ProximityManager.shared.enable() }
        else       { ProximityManager.shared.disable() }
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
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try KeychainStore.save(trimmed, for: KeychainStore.claudeAPIKeyAccount)
            apiKey = trimmed
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
