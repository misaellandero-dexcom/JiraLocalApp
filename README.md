# JiraLocalApp

A macOS menu bar app that shows your assigned unresolved Jira tickets, groups them by project, and lets you start or resume GitHub Copilot CLI sessions directly from Terminal.app.

## Requirements

- macOS 13 or newer.
- Swift 5.9 or newer.
- GitHub Copilot CLI installed and available as `copilot`.
- The local Jira CLI installed at `~/.local/bin/jira`.
- A Jira personal access token with permission to read your assigned issues.

The Jira CLI is required for this app to fetch tickets. Copilot CLI does not need to "recognize" Jira by itself for the app to work; JiraLocalApp calls `~/.local/bin/jira` directly to load tickets, then starts Copilot sessions with the selected ticket context and your configured agent instructions.

## Features

- Fetches assigned unresolved Jira tickets through the local read-only `~/.local/bin/jira` CLI.
- Provides a settings panel to save your Jira token as `JIRA_PAT` in `~/.config/jira/.env`.
- Lets you define reusable agent instructions for new Copilot ticket sessions.
- Shows active Copilot agents grouped by Jira ticket.
- Reads local Copilot session state from `~/.copilot/session-state` and `~/.copilot/open-sessions-state.json`.
- Displays session todo progress from each session's local `session.db`.

## How ticket linking works

When you start a session from the app, it is named with the ticket key, for example:

```text
RDS-1234: Fix crash
```

The app later matches Copilot sessions to Jira tickets by looking for that ticket key in the session name.

## Configure Jira access

1. Install or provide the Jira CLI at:

   ```bash
   ~/.local/bin/jira
   ```

2. Make sure it is executable:

   ```bash
   chmod +x ~/.local/bin/jira
   ```

3. Save your Jira token in the app:

   - Open JiraLocalApp from the menu bar.
   - Click **Settings**.
   - Enter your Jira token in **Jira token**.
   - Click **Save Settings**.

   The app writes the token to:

   ```text
   ~/.config/jira/.env
   ```

   using this format:

   ```text
   JIRA_PAT="your-token"
   ```

4. Verify the Jira CLI can fetch tickets:

   ```bash
   ~/.local/bin/jira search 'assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC' --max 5
   ```

If the app shows a Jira error, first confirm that `~/.local/bin/jira` exists, is executable, and can read `JIRA_PAT` from `~/.config/jira/.env`.

## Configure agent instructions

1. Open JiraLocalApp from the menu bar.
2. Click **Settings**.
3. Edit **Agent Instructions**.
4. Click **Save Settings**.

These instructions are passed to Copilot when you start a new ticket agent from the app. They are stored locally in macOS `UserDefaults`.

## Use the app

1. Launch JiraLocalApp.
2. Open the menu bar item.
3. Review your assigned unresolved tickets grouped by project.
4. Click **Start** on a ticket to open Terminal.app and create a Copilot session for that ticket.
5. Click **Resume** on a ticket that already has a linked Copilot session.
6. Open **View agent instructions** to see your current instructions and active Copilot agents grouped by ticket.
7. Use **Open tickets dashboard** for the larger ticket/progress window.

## Build and run

```bash
swift build -c release
./.build/release/JiraLocalApp
```

The app runs as a menu-bar-only app and does not appear in the Dock.

## Start automatically at login

```bash
swift build -c release
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.local.jiralocalapp.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.local.jiralocalapp</string>
  <key>ProgramArguments</key>
  <array><string>$(pwd)/.build/release/JiraLocalApp</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><false/>
</dict>
</plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.local.jiralocalapp.plist
```

To remove the LaunchAgent:

```bash
launchctl unload ~/Library/LaunchAgents/com.local.jiralocalapp.plist
rm ~/Library/LaunchAgents/com.local.jiralocalapp.plist
```

## Jira query

The default JQL is defined in `Sources/JiraLocalApp/TicketStore.swift`:

```text
assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC
```
