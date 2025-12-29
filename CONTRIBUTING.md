# Contributing & Development Guide

## Publishing to GitHub

### 1. Create the Repository

```bash
# Navigate to project folder
cd H:\DevLaptop\ClaudeStatusLine

# Initialize git
git init

# Add files
git add .

# Initial commit
git commit -m "Initial release: PowerShell statusline for Claude Code on Windows"

# Create repo on GitHub (via gh cli or web interface)
gh repo create claude-code-statusline-windows --public --source=. --push

# Or manually:
# 1. Create repo at https://github.com/new
# 2. git remote add origin https://github.com/<username>/claude-code-statusline-windows.git
# 3. git push -u origin main
```

### 2. Recommended Repository Structure

```
claude-code-statusline-windows/
├── README.md           # Main documentation
├── CONTRIBUTING.md     # This file
├── LICENSE             # MIT License
├── statusline.ps1      # The main script
├── install.ps1         # Optional: installation script
└── examples/
    └── settings.json   # Example configuration
```

### 3. Create a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

Then create a release on GitHub with release notes.

---

## Making Changes to the Statusline

### Script Location

The active script is at:
```
C:\Users\<YourUsername>\.claude\statusline\statusline.ps1
```

### Testing Changes

1. **Edit the script** in your preferred editor

2. **Test manually** without restarting Claude Code:
   ```powershell
   echo '{"workspace":{"current_dir":"H:\\DevLaptop"},"model":{"display_name":"Claude Opus 4.5"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\pscjo\.claude\statusline\statusline.ps1
   ```

3. **Changes take effect immediately** - Claude Code re-runs the statusline command on each update

### Script Structure

```powershell
# 1. UTF-8 encoding setup
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. Emoji definitions (using Unicode code points)
$EMOJI_FOLDER = [char]::ConvertFromUtf32(0x1F4C1)
# ... more emojis

# 3. Read JSON from stdin
$inputJson = [Console]::In.ReadToEnd()

# 4. Parse JSON (with fallback for Windows path issues)
# ... parsing logic

# 5. Collect data from various sources
# - Git: git commands
# - Tokens: ccusage
# - MCP: parse ~/.claude.json
# - Session: temp file timestamp

# 6. Build output components array
$components = @()
$components += "📁 $folderName"
# ... more components

# 7. Output single line
$output = $components -join " | "
Write-Output $output
```

### Adding New Components

To add a new component (e.g., CPU usage):

```powershell
# 1. Add emoji at the top
$EMOJI_CPU = [char]::ConvertFromUtf32(0x1F4BB)  # laptop emoji

# 2. Collect data (after existing data collection)
$cpuUsage = ""
try {
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    if ($cpu) {
        $cpuUsage = "$cpu%"
    }
} catch {
    $cpuUsage = ""
}

# 3. Add to output (before the Time component)
if ($cpuUsage) {
    $components += "$EMOJI_CPU $cpuUsage"
}
```

### Modifying Existing Components

#### Change Token Display Format
Find the token formatting section (~line 110):
```powershell
if ($totalTokens -ge 1000000) {
    $tokenDisplay = "{0:N1}M" -f ($totalTokens / 1000000)
} elseif ($totalTokens -ge 1000) {
    $tokenDisplay = "{0:N1}K" -f ($totalTokens / 1000)
}
```

#### Change Model Emojis
Find the model indicator section (~line 77):
```powershell
if ($modelName -match "Opus") {
    $modelIndicator = $EMOJI_BRAIN  # Change this
}
```

#### Change Separator
Find the output line at the bottom:
```powershell
$output = $components -join " | "  # Change " | " to " • " or whatever
```

### Common Issues When Developing

1. **Emojis not displaying**: Use `[char]::ConvertFromUtf32(0xXXXXX)` for emojis above U+FFFF

2. **JSON parsing fails**: Windows paths have backslashes that break JSON. The script has a regex fallback.

3. **Script hangs**: Likely waiting for stdin. Always pipe input when testing.

4. **Changes not showing**: Claude Code caches nothing - if changes don't appear, check for PowerShell errors.

---

## Debugging

### Enable Verbose Output

Temporarily add at the start of the script:
```powershell
$DebugPreference = "Continue"
Write-Debug "Input: $inputJson"
Write-Debug "CurrentDir: $currentDir"
# etc.
```

### Check for Errors

Run with error details:
```powershell
echo '{"workspace":{"current_dir":"C:\\Test"},"model":{"display_name":"Claude"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\pscjo\.claude\statusline\statusline.ps1 2>&1
```

### Log to File

Add logging:
```powershell
$logFile = "$env:TEMP\statusline.log"
"$(Get-Date): Input=$inputJson" | Out-File $logFile -Append
```

---

## Version History

### v1.0.0 (2024-12-29)
- Initial release
- Features: folder, git, model, tokens, MCP count, session time, clock
- Windows-native PowerShell implementation
