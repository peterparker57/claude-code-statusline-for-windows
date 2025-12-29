# Claude Code PowerShell Statusline

A Windows-native PowerShell statusline for Claude Code that displays real-time session information at the bottom of the terminal.

## What It Does

Displays a single-line status bar showing:

```
📁 H:\DevLaptop | 🌿 main (ok) | 🧠 Opus 4.5 | 📊 17.7M | 🔌 4 MCP | ⏱ 19m | 🕐 1:10PM
```

| Icon | Component | Description |
|------|-----------|-------------|
| 📁 | Folder | Full path of current working directory |
| 🌿 | Git Branch | Branch name + status (`ok` = clean, `*` = dirty) |
| 🧠/🎵/⚡ | Model | Claude model with emoji (Opus/Sonnet/Haiku) |
| 📊 | Tokens | Today's total token usage (requires ccusage) |
| 🔌 | MCP | Count of configured MCP servers |
| ⏱ | Session | Time since statusline first ran |
| 🕐 | Time | Current time (12-hour AM/PM format) |

## Why This Exists

The original [claude-code-statusline](https://github.com/rz1989s/claude-code-statusline) is a bash-based tool designed for Unix/macOS/WSL. It doesn't work on native Windows with Git Bash due to:
- Script hangs during initialization
- PATH issues with jq and ccusage
- Various bash compatibility problems

This PowerShell version provides the same core functionality but works natively on Windows.

## Requirements

- **Windows 10/11** with PowerShell 5.1+
- **Claude Code CLI** installed
- **ccusage** (optional, for token tracking): `npm install -g ccusage`
- **Git** (optional, for branch display)

## Installation

### 1. Copy the Script

Copy `statusline.ps1` to:
```
C:\Users\<YourUsername>\.claude\statusline\statusline.ps1
```

### 2. Configure Claude Code

Edit `C:\Users\<YourUsername>\.claude\settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Users\\<YourUsername>\\.claude\\statusline\\statusline.ps1"
  }
}
```

### 3. Restart Claude Code

The statusline should appear at the bottom of the terminal.

## How It Works

### Input/Output

Claude Code sends JSON to the statusline command via stdin:
```json
{
  "workspace": {
    "current_dir": "H:\\DevLaptop"
  },
  "model": {
    "display_name": "Claude Opus 4.5"
  }
}
```

The script outputs a single line of text that Claude Code displays at the bottom of the terminal.

### Data Sources

| Component | Source |
|-----------|--------|
| Folder | JSON input from Claude Code |
| Model | JSON input from Claude Code |
| Git Branch | `git rev-parse --abbrev-ref HEAD` |
| Git Status | `git status --porcelain` |
| Tokens | `ccusage daily --json --offline` |
| MCP Count | Parsed from `~/.claude.json` |
| Session Time | Tracked via temp file |

### Key Implementation Details

1. **UTF-8 Emojis**: Uses `[char]::ConvertFromUtf32()` for emoji support
2. **JSON Parsing**: Handles Windows path escaping issues with regex fallback
3. **MCP Counting**: Parses `~/.claude.json` with brace-depth tracking to handle nested objects
4. **Session Tracking**: Stores start time in `%TEMP%\claude_session_start.txt`

## File Locations

| File | Purpose |
|------|---------|
| `~\.claude\statusline\statusline.ps1` | Main script |
| `~\.claude\settings.json` | Claude Code configuration |
| `~\.claude.json` | MCP server configuration |
| `%TEMP%\claude_session_start.txt` | Session start timestamp |

## Troubleshooting

### Statusline not appearing
1. Check `settings.json` has correct path (use `\\` for backslashes)
2. Restart Claude Code completely
3. Test script manually:
   ```powershell
   echo '{"workspace":{"current_dir":"C:\\Test"},"model":{"display_name":"Claude"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\<You>\.claude\statusline\statusline.ps1
   ```

### Tokens not showing
1. Install ccusage: `npm install -g ccusage`
2. Verify it works: `ccusage daily --json --offline`

### MCP count wrong
- The script reads the last 200 lines of `~/.claude.json`
- It counts servers in the root-level `mcpServers` object (not `_disabled_mcpServers`)

### Emojis showing as `??` or boxes
- Ensure your terminal supports Unicode
- The script sets `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`

## Credits

- Inspired by [claude-code-statusline](https://github.com/rz1989s/claude-code-statusline) by rz1989s
- Built for Windows by Claude Code assistance

## License

MIT License - Feel free to use, modify, and distribute.
