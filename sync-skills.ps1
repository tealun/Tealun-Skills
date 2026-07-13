[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Skills
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot
$DryRun = $env:DRY_RUN -eq '1'

function Test-CliInstalled {
    param([string[]]$Commands, [string[]]$ConfigDirs)

    foreach ($command in $Commands) {
        if (Get-Command $command -ErrorAction SilentlyContinue) { return $true }
    }
    foreach ($dir in $ConfigDirs) {
        if (Test-Path -LiteralPath $dir -PathType Container) { return $true }
    }
    return $false
}

$targets = [System.Collections.Generic.List[object]]::new()
function Add-SkillTarget {
    param([string]$Label, [string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if ($targets.Path -contains $fullPath) { return }
    $targets.Add([pscustomobject]@{ Label = $Label; Path = $fullPath })
}

$agentsDir = Join-Path $HOME '.agents'
$codexDir = Join-Path $HOME '.codex'
if (Test-CliInstalled @('claude') @((Join-Path $HOME '.claude'))) {
    Add-SkillTarget 'Claude' (Join-Path $HOME '.claude/skills')
}
if ((Test-CliInstalled @('codex') @($codexDir)) -and -not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
    Add-SkillTarget 'Codex' (Join-Path $codexDir 'skills')
}
if (Test-CliInstalled @('cursor') @((Join-Path $HOME '.cursor'))) {
    Add-SkillTarget 'Cursor' (Join-Path $HOME '.cursor/skills')
}
if (Test-CliInstalled @('gemini') @((Join-Path $HOME '.gemini'))) {
    Add-SkillTarget 'Gemini' (Join-Path $HOME '.gemini/skills')
}
if (Test-CliInstalled @('kimi', 'kimi-cli', 'kimi-code') @((Join-Path $HOME '.kimi'), (Join-Path $HOME '.kimi-code'))) {
    Add-SkillTarget 'Kimi' (Join-Path $HOME '.kimi/skills')
}
if (Test-CliInstalled @('opencode') @((Join-Path $HOME '.config/opencode'))) {
    Add-SkillTarget 'OpenCode' (Join-Path $HOME '.config/opencode/skills')
}
if (Test-Path -LiteralPath $agentsDir -PathType Container) {
    Add-SkillTarget 'Shared agents' (Join-Path $agentsDir 'skills')
}

if ($targets.Count -eq 0) {
    throw 'No installed Windows CLI with a known SKILL.md directory was found.'
}

if ($Skills.Count -eq 1 -and $Skills[0] -eq '--list-targets') {
    foreach ($target in $targets) {
        '{0,-14} {1}' -f $target.Label, $target.Path
    }
    exit 0
}

if (-not $Skills -or $Skills.Count -eq 0) {
    $Skills = @(Get-ChildItem -LiteralPath $RepoDir -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
    } | Select-Object -ExpandProperty Name)
}

"Source: $RepoDir"
'Environment: Windows'
'Targets:'
foreach ($target in $targets) {
    "  $($target.Label) -> $($target.Path)"
}
if ($DryRun) { '[DRY-RUN: no writes]' }
''

foreach ($skill in $Skills) {
    $source = Join-Path $RepoDir $skill
    $manifest = Join-Path $source 'SKILL.md'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        "Skip ${skill}: missing $skill/SKILL.md"
        continue
    }

    $versionLine = Select-String -LiteralPath $manifest -Pattern '^version:' | Select-Object -First 1
    $version = if ($versionLine) { ($versionLine.Line -split ':', 2)[1].Trim() } else { '?' }
    "== $skill @ $version =="

    foreach ($target in $targets) {
        $destination = Join-Path $target.Path $skill
        if ($DryRun) {
            "  [dry] $($target.Label): overlay $source/* -> $destination"
            continue
        }

        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
        "  ok $($target.Label) -> $destination"
    }
    ''
}

'Done.'
