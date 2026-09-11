import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Jira Connection") {
                SecureField("Jira token", text: $settings.jiraToken)
                    .textFieldStyle(.roundedBorder)

                Text("The token is saved to ~/.config/jira/.env as JIRA_PAT so the local jira CLI can connect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Agent Instructions") {
                TextEditor(text: $settings.agentInstructions)
                    .font(.body.monospaced())
                    .frame(minHeight: 180)

                Text("These instructions are passed to Copilot when you start a new ticket agent from the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if let status = settings.statusMessage {
                Text(status)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Save Settings") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 420)
    }

    private func save() {
        do {
            try settings.save()
            errorMessage = nil
            Task { await store.refresh() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
