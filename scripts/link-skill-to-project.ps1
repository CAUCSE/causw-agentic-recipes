<#
.SYNOPSIS
  Link a skill from this repository into a target project's agent tool directory.

.EXAMPLE
  .\scripts\link-skill-to-project.ps1 causw-pr-writer C:\Projects\CAUSW_backend

.EXAMPLE
  .\scripts\link-skill-to-project.ps1 causw-pr-writer C:\Projects\CAUSW_backend codex
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SkillName,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateSet("claude", "codex", "cursor")]
    [string]$Tool = "claude"
)

$ErrorActionPreference = "Stop"

switch ($Tool) {
    "claude" { $ToolDir = ".claude" }
    "codex" { $ToolDir = ".codex" }
    "cursor" { $ToolDir = ".cursor" }
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SkillSource = Join-Path $RepoRoot "skills\$SkillName"
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$SkillsDir = Join-Path $ProjectRoot "$ToolDir\skills"
$LinkPath = Join-Path $SkillsDir $SkillName

if (-not (Test-Path -LiteralPath $SkillSource)) {
    Write-Error "Skill not found: $SkillSource"
}

if (-not (Test-Path -LiteralPath (Join-Path $SkillSource "SKILL.md"))) {
    Write-Error "Missing SKILL.md: $SkillSource"
}

New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

if (Test-Path -LiteralPath $LinkPath) {
    $item = Get-Item -LiteralPath $LinkPath -Force
    if ($item.LinkType -eq "SymbolicLink") {
        $currentTarget = (Get-Item -LiteralPath $LinkPath).Target
        if ($currentTarget -eq $SkillSource) {
            Write-Host "Already linked: $LinkPath -> $SkillSource"
            exit 0
        }
        Write-Error "Path already exists with another target: $LinkPath (target: $currentTarget)"
    }
    Write-Error "Path already exists: $LinkPath"
}

New-Item -ItemType SymbolicLink -Path $LinkPath -Target $SkillSource | Out-Null
Write-Host "Linked: $LinkPath -> $SkillSource"
