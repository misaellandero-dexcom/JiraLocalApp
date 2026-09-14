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
                    .frame(minHeight: 140)

                Text("These instructions are passed to Copilot when you start a new ticket agent from the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Project Repositories") {
                Text("Saved repository locations per project. When starting an agent for a ticket without a saved path, the app will ask you to choose a folder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settings.projectDirectories.isEmpty {
                    Text("No project repositories configured yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(settings.projectDirectories.keys.sorted()), id: \.self) { projectKey in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(projectKey)
                                    .font(.headline)
                                Text(settings.projectDirectories[projectKey] ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("Browse...") {
                                settings.browseDirectory(for: projectKey)
                            }
                            Button {
                                settings.removeDirectory(for: projectKey)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
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
