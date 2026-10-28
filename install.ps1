# setup-claude-senior-5-tool - Windows installer (PowerShell 5.1+ / 7+)
#
# Installs 5 open-source tools that make Claude Code work like a senior developer:
#   1. agent-skills : Addy Osmani's Agent Skills (spec -> ship workflow skills)
#   2. context7     : up-to-date library docs MCP
#   3. graphify     : project knowledge graph (saves tokens)
#   4. 21st         : 21st MCP (UI component search / insert)
#   5. strix        : AI penetration testing agent
#
# Usage:
#   irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.ps1 | iex
#
#   # with options
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.ps1))) -Only context7,graphify
#
# Environment variables:
#   CONTEXT7_API_KEY   (optional) https://context7.com/dashboard
#   API_KEY_21ST       (required for 21st MCP) https://21st.dev/mcp
#   SENIOR_TOOLS_ONLY / SENIOR_TOOLS_SKIP  - same as -Only / -Skip (comma separated)
#
# This file is intentionally ASCII-only so it parses the same under every
# Windows code page (PowerShell 5.1 reads BOM-less files as ANSI).

param(
    [string[]]$Only = @(),
    [string[]]$Skip = @(),
    [switch]$Yes
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$AllTools = @('agent-skills', 'context7', 'graphify', '21st', 'strix')
if (-not $Only -and $env:SENIOR_TOOLS_ONLY) { $Only = $env:SENIOR_TOOLS_ONLY -split ',' }
if (-not $Skip -and $env:SENIOR_TOOLS_SKIP) { $Skip = $env:SENIOR_TOOLS_SKIP -split ',' }
# "-Only a,b" arrives as one element when passed through some hosts
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { $_.Trim() })
$Skip = @($Skip | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { $_.Trim() })

$Results = New-Object System.Collections.Generic.List[object]

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Info($m) { Write-Host "    $m" }
function Ok($m)   { Write-Host "    [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "    [!] $m" -ForegroundColor Yellow }
function Err($m)  { Write-Host "    [X] $m" -ForegroundColor Red }
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Record($n, $s, $note) { $Results.Add([pscustomobject]@{ Tool = $n; Status = $s; Note = $note }) }

function Is-Selected($t) {
    if ($Only.Count -gt 0 -and $Only -notcontains $t) { return $false }
    if ($Skip -contains $t) { return $false }
    return $true
}

function Ask-Secret($prompt) {
    if ($Yes -or -not [Environment]::UserInteractive) { return '' }
    try {
        $sec = Read-Host -Prompt "    $prompt" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    } catch { return '' }
}

function Add-PathEntry($dir) {
    if ((Test-Path $dir) -and (($env:Path -split ';') -notcontains $dir)) {
        $env:Path = "$dir;$env:Path"
    }
}

function Ensure-Uv {
    Add-PathEntry "$HOME\.local\bin"
    if (Have uv) { return $true }
    Info "uv not found - installing (https://astral.sh/uv)"
    powershell -NoProfile -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" | Out-Null
    Add-PathEntry "$HOME\.local\bin"
    return (Have uv)
}

# Re-register an existing MCP server so a changed key takes effect.
function Add-HttpMcp($name, $url, $header) {
    claude mcp remove $name --scope user *> $null
    if ($header) {
        claude mcp add --scope user --transport http $name $url --header $header
    } else {
        claude mcp add --scope user --transport http $name $url
    }
    return ($LASTEXITCODE -eq 0)
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
Write-Host "Claude Code Senior 5 Tools installer (Windows)" -ForegroundColor White

Step "Checking prerequisites"
Add-PathEntry "$HOME\.local\bin"
if (-not (Have claude)) {
    Err "Claude Code CLI (claude) not found."
    Info "Install it first: irm https://claude.ai/install.ps1 | iex"
    return
}
Ok ("claude " + (claude --version 2>$null | Select-Object -First 1))
if (Have git) { Ok "git" } else { Err "git is required -> winget install Git.Git"; return }
if (Have npx) { Ok ("node " + (node --version 2>$null)) } else { Warn "Node.js (npx) not found; some fallbacks unavailable -> winget install OpenJS.NodeJS.LTS" }

# ---------------------------------------------------------------------------
# 1. Agent Skills
# ---------------------------------------------------------------------------
function Install-AgentSkills {
    Step "[1/5] Agent Skills (addyosmani/agent-skills)"
    # HTTPS URL so it works without GitHub SSH keys
    claude plugin marketplace add https://github.com/addyosmani/agent-skills.git *> $null
    claude plugin install agent-skills@addy-agent-skills --scope user
    if ($LASTEXITCODE -eq 0) {
        Ok "installed as Claude Code plugin"
        Record 'agent-skills' 'OK' 'plugin agent-skills@addy-agent-skills'
        return
    }
    Warn "plugin install failed -> retrying with skills CLI"
    if (Have npx) {
        npx -y skills add addyosmani/agent-skills -g -a claude-code -y
        if ($LASTEXITCODE -eq 0) {
            Ok "installed with skills CLI (~/.claude/skills)"
            Record 'agent-skills' 'OK' 'npx skills add'
            return
        }
    }
    Err "install failed"
    Record 'agent-skills' 'FAIL' 'try /plugin marketplace add addyosmani/agent-skills inside Claude Code'
}

# ---------------------------------------------------------------------------
# 2. Context7
# ---------------------------------------------------------------------------
function Install-Context7 {
    Step "[2/5] Context7 MCP (upstash/context7)"
    $key = $env:CONTEXT7_API_KEY
    if (-not $key) {
        Info "API key is optional (higher rate limits with a key)."
        $key = Ask-Secret "CONTEXT7_API_KEY (Enter to skip)"
    }
    $header = $null
    if ($key) { $header = "Authorization: Bearer $key" }
    if (Add-HttpMcp 'context7' 'https://mcp.context7.com/mcp' $header) {
        Ok "MCP server 'context7' registered (user scope)"
        Record 'context7' 'OK' 'MCP https://mcp.context7.com/mcp'
    } else {
        Err "registration failed"
        Record 'context7' 'FAIL' 'claude mcp add failed'
    }
}

# ---------------------------------------------------------------------------
# 3. Graphify
# ---------------------------------------------------------------------------
function Install-Graphify {
    Step "[3/5] Graphify (PyPI: graphifyy)"
    if (-not (Ensure-Uv)) { Err "uv install failed"; Record 'graphify' 'FAIL' 'uv install failed'; return }
    # The official package name is graphifyy (double y)
    uv tool install --upgrade graphifyy
    if ($LASTEXITCODE -eq 0) {
        $bin = (uv tool dir --bin 2>$null)
        if ($bin) { Add-PathEntry $bin }
        graphify install --platform windows
        if ($LASTEXITCODE -eq 0) {
            Ok "graphify CLI + Claude Code skill registered (use: /graphify .)"
            Record 'graphify' 'OK' 'uv tool graphifyy + graphify install'
            return
        }
    }
    Err "install failed"
    Record 'graphify' 'FAIL' 'run: uv tool install graphifyy; graphify install'
}

# ---------------------------------------------------------------------------
# 4. 21st MCP
# ---------------------------------------------------------------------------
function Install-21st {
    Step "[4/5] 21st MCP (21st.dev)"
    $key = $env:API_KEY_21ST
    if (-not $key) {
        Info "An API key is required -> https://21st.dev/mcp (free)"
        $key = Ask-Secret "API_KEY_21ST (Enter to skip)"
    }
    if (-not $key) {
        Warn "no key, skipped. Later: `$env:API_KEY_21ST='...'; then re-run with -Only 21st"
        Record '21st' 'SKIP' 'no API_KEY_21ST'
        return
    }
    if (Add-HttpMcp '21st' 'https://21st.dev/api/mcp' "x-api-key: $key") {
        Ok "MCP server '21st' registered (user scope)"
        Record '21st' 'OK' 'MCP https://21st.dev/api/mcp'
    } else {
        Err "registration failed"
        Record '21st' 'FAIL' 'claude mcp add failed'
    }
}

# ---------------------------------------------------------------------------
# 5. Strix
# ---------------------------------------------------------------------------
function Install-Strix {
    Step "[5/5] Strix (usestrix/strix)"
    if (-not (Ensure-Uv)) { Err "uv install failed"; Record 'strix' 'FAIL' 'uv install failed'; return }
    # strix-agent requires Python 3.12+; uv downloads it if needed
    uv tool install --upgrade --python 3.12 strix-agent
    if ($LASTEXITCODE -ne 0) {
        Err "strix CLI install failed"
        Record 'strix' 'FAIL' 'run: uv tool install --python 3.12 strix-agent'
        return
    }
    $bin = (uv tool dir --bin 2>$null)
    if ($bin) { Add-PathEntry $bin }
    Ok "strix CLI installed (uv tool)"
    # Official skills so Claude Code can drive strix
    if (Have npx) {
        npx -y skills add usestrix/strix -g -a claude-code -y *> $null
        if ($LASTEXITCODE -eq 0) { Ok "Strix skills installed (~/.claude/skills)" }
        else { Warn "Strix skills skipped (npx skills add usestrix/strix)" }
    }
    if (-not (Have docker)) { Warn "Strix needs Docker Desktop running -> https://docs.docker.com/desktop/setup/install/windows-install/" }
    Info "Before running: `$env:STRIX_LLM='anthropic/claude-sonnet-5-5'; `$env:LLM_API_KEY='...'"
    Record 'strix' 'OK' 'strix CLI + skills'
}

foreach ($t in $AllTools) {
    if (-not (Is-Selected $t)) { continue }
    switch ($t) {
        'agent-skills' { Install-AgentSkills }
        'context7'     { Install-Context7 }
        'graphify'     { Install-Graphify }
        '21st'         { Install-21st }
        'strix'        { Install-Strix }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Step "Summary"
foreach ($r in $Results) {
    $color = switch ($r.Status) { 'OK' { 'Green' } 'SKIP' { 'Yellow' } default { 'Red' } }
    Write-Host ("    {0,-5} {1,-13} {2}" -f $r.Status, $r.Tool, $r.Note) -ForegroundColor $color
}
Write-Host ""
Write-Host "    Restart Claude Code to apply. Check with: claude mcp list / claude plugin list"
