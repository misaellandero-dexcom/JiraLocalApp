# JiraLocalApp

A macOS menu bar app that shows your assigned unresolved Jira tickets, groups them by project, and lets you start or resume GitHub Copilot CLI sessions directly from Terminal.app.

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
