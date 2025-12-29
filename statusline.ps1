# Claude Code PowerShell Statusline
# Displays: Folder | Git branch | Model | Tokens | Time

param()

# Set UTF-8 output encoding for emoji support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Define emoji characters using Unicode
$EMOJI_FOLDER = [char]::ConvertFromUtf32(0x1F4C1)
$EMOJI_BRANCH = [char]::ConvertFromUtf32(0x1F33F)
$EMOJI_BRAIN = [char]::ConvertFromUtf32(0x1F9E0)
$EMOJI_MUSIC = [char]::ConvertFromUtf32(0x1F3B5)
$EMOJI_ZAP = [char]::ConvertFromUtf32(0x26A1)
$EMOJI_ROBOT = [char]::ConvertFromUtf32(0x1F916)
$EMOJI_CHART = [char]::ConvertFromUtf32(0x1F4CA)
$EMOJI_CLOCK = [char]::ConvertFromUtf32(0x1F550)
$EMOJI_PLUG = [char]::ConvertFromUtf32(0x1F50C)
$EMOJI_STOPWATCH = [char]::ConvertFromUtf32(0x23F1)

# Read JSON input from stdin
$inputJson = ""
try {
    $inputJson = [Console]::In.ReadToEnd()
} catch {
    $inputJson = ""
}

$currentDir = ""
$modelName = "Claude"

if ($inputJson) {
    try {
        # Fix Windows paths - escape backslashes for JSON parsing
        $fixedJson = $inputJson -replace '\\(?!["\\/ bfnrtu])', '\\'
        $jsonObj = $fixedJson | ConvertFrom-Json -ErrorAction Stop
        if ($jsonObj.workspace.current_dir) {
            $currentDir = $jsonObj.workspace.current_dir
        }
        if ($jsonObj.model.display_name) {
            $modelName = $jsonObj.model.display_name
        }
    } catch {
        # JSON parsing failed, try regex extraction as fallback
        if ($inputJson -match '"current_dir"\s*:\s*"([^"]+)"') {
            $currentDir = $Matches[1] -replace '\\\\', '\'
        }
        if ($inputJson -match '"display_name"\s*:\s*"([^"]+)"') {
            $modelName = $Matches[1]
        }
    }
}

# Fallback for current directory
if ([string]::IsNullOrEmpty($currentDir)) {
    $currentDir = (Get-Location).Path
}

# Use full path for display
$folderName = $currentDir

# Get git branch and status
$gitBranch = ""
$gitStatus = ""
try {
    $originalLocation = Get-Location
    Set-Location $currentDir -ErrorAction SilentlyContinue
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($gitBranch) {
        $gitDirty = git status --porcelain 2>$null
        if ($gitDirty) {
            $gitStatus = "*"
        } else {
            $gitStatus = "ok"
        }
    }
    Set-Location $originalLocation
} catch {
    $gitBranch = ""
}

# Get model indicator based on model name
$modelIndicator = $EMOJI_ROBOT
if ($modelName -match "Opus") {
    $modelIndicator = $EMOJI_BRAIN
} elseif ($modelName -match "Sonnet") {
    $modelIndicator = $EMOJI_MUSIC
} elseif ($modelName -match "Haiku") {
    $modelIndicator = $EMOJI_ZAP
}

# Shorten model name
$shortModel = $modelName -replace "Claude\s*", "" -replace "\s*\(.*\)", ""
if ([string]::IsNullOrEmpty($shortModel)) {
    $shortModel = "Claude"
}

# Get token usage from ccusage (today's total)
$tokenDisplay = ""
try {
    $ccusagePath = Join-Path $env:APPDATA "npm\ccusage.cmd"
    if (Test-Path $ccusagePath) {
        $today = Get-Date -Format "yyyyMMdd"
        $ccRaw = & cmd /c "$ccusagePath daily --json --offline -s $today" 2>$null
        if ($ccRaw) {
            $ccOutput = $ccRaw | ConvertFrom-Json -ErrorAction Stop
            if ($ccOutput.daily -and $ccOutput.daily.Count -gt 0) {
                $totalTokens = [long]$ccOutput.daily[0].totalTokens
                if ($totalTokens -gt 0) {
                    if ($totalTokens -ge 1000000) {
                        $tokenDisplay = "{0:N1}M" -f ($totalTokens / 1000000)
                    } elseif ($totalTokens -ge 1000) {
                        $tokenDisplay = "{0:N1}K" -f ($totalTokens / 1000)
                    } else {
                        $tokenDisplay = "$totalTokens"
                    }
                }
            }
        }
    }
} catch {
    $tokenDisplay = ""
}

# Get MCP server count from ~/.claude.json
$mcpCount = ""
try {
    $claudeJsonPath = Join-Path $env:USERPROFILE ".claude.json"
    if (Test-Path $claudeJsonPath) {
        # Read last 200 lines where global mcpServers is located
        $lines = Get-Content $claudeJsonPath -Tail 200
        $inMcpServers = $false
        $serverCount = 0
        $braceDepth = 0
        foreach ($line in $lines) {
            # Start counting when we hit "mcpServers": (not _disabled_mcpServers)
            if ($line -match '^\s*"mcpServers":\s*\{' -and $line -notmatch '_disabled') {
                $inMcpServers = $true
                $braceDepth = 1
                continue
            }
            # Stop when we hit _disabled_mcpServers
            if ($inMcpServers -and $line -match '_disabled_mcpServers') {
                break
            }
            if ($inMcpServers) {
                # Track brace depth
                $openBraces = ([regex]::Matches($line, '\{')).Count
                $closeBraces = ([regex]::Matches($line, '\}')).Count

                # Count server entries at depth 1 (direct children)
                # A server definition starts with "name": { at the right indent
                if ($braceDepth -eq 1 -and $line -match '^\s{4}"[^"]+"\s*:\s*\{') {
                    $serverCount++
                }

                $braceDepth += $openBraces - $closeBraces
                # Stop when we close the mcpServers object
                if ($braceDepth -le 0) {
                    break
                }
            }
        }
        if ($serverCount -gt 0) {
            $mcpCount = "$serverCount"
        }
    }
} catch {
    $mcpCount = ""
}

# Get session duration (track via temp file)
$sessionDisplay = ""
try {
    $sessionFile = Join-Path $env:TEMP "claude_session_start.txt"
    $now = Get-Date

    if (Test-Path $sessionFile) {
        $startTime = Get-Content $sessionFile -Raw | Get-Date -ErrorAction Stop
        $duration = $now - $startTime

        if ($duration.TotalHours -ge 1) {
            $sessionDisplay = "{0:N0}h {1:N0}m" -f [math]::Floor($duration.TotalHours), $duration.Minutes
        } else {
            $sessionDisplay = "{0:N0}m" -f [math]::Floor($duration.TotalMinutes)
        }
    } else {
        # First run - create session file
        $now.ToString("o") | Out-File $sessionFile -NoNewline
        $sessionDisplay = "0m"
    }
} catch {
    $sessionDisplay = ""
}

# Get current time
$currentTime = Get-Date -Format "h:mmtt"

# Build output components
$components = @()

# Folder
if ($folderName) {
    $components += "$EMOJI_FOLDER $folderName"
}

# Git (if available)
if ($gitBranch) {
    $components += "$EMOJI_BRANCH $gitBranch ($gitStatus)"
}

# Model
$components += "$modelIndicator $shortModel"

# Tokens (if available)
if ($tokenDisplay) {
    $components += "$EMOJI_CHART $tokenDisplay"
}

# MCP servers (if available)
if ($mcpCount) {
    $components += "$EMOJI_PLUG $mcpCount MCP"
}

# Session duration (if available)
if ($sessionDisplay) {
    $components += "$EMOJI_STOPWATCH $sessionDisplay"
}

# Time
$components += "$EMOJI_CLOCK $currentTime"

# Output single line
$output = $components -join " | "
Write-Output $output
