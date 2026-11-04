<#
  Spirit of Fire SDD installer (Windows PowerShell 5.1+).

  Default: copies files only and never overwrites. Anything that already exists is listed as
  SKIPPED so you can merge it by hand.

  With -Update: files that already exist and DIFFER are replaced by the new version, after the
  old one is saved next to it as <name>.bak-<date-time>. Your own project files are never replaced,
  even with -Update (they are listed as KEPT): CLAUDE.md, .gitignore, .agents\supply\* (RULES,
  MEMORY, NOTEBOOK, DECISIONS), .agents\policies\*, and .claude\spirit-of-fire.json.

  One-time, for your user (agents + skills, shared by all projects):
    .\install.ps1 -UserLevel

  For a project (commander, supply depot, hooks):
    .\install.ps1 -Project "D:\path\to\your-project"

  Both at once:
    .\install.ps1 -UserLevel -Project "D:\path\to\your-project"

  After a git pull of this folder, take the improved skills, agents, commander orders and hooks:
    .\install.ps1 -UserLevel -Update
    .\install.ps1 -Project "D:\path\to\your-project" -Update
#>
param(
  [switch]$UserLevel,
  [string]$Project,
  [switch]$Update
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Project files that belong to the project, not to the framework: -Update never replaces them.
$keepPatterns = @(
  'CLAUDE.md',
  '.gitignore',
  '.agents\supply\*',
  '.agents\policies\*',
  '.claude\spirit-of-fire.json'
)

function Test-Kept([string]$relative) {
  foreach ($pattern in $keepPatterns) {
    if ($relative -like $pattern) { return $true }
  }
  return $false
}

function Copy-Tree([string]$from, [string]$to, [bool]$protectProjectFiles) {
  Get-ChildItem -Path $from -Recurse -File -Force | ForEach-Object {
    $relative = $_.FullName.Substring($from.Length).TrimStart('\')
    $target = Join-Path $to $relative
    if (-not (Test-Path $target)) {
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
      Copy-Item -Path $_.FullName -Destination $target
      Write-Host "added: $target" -ForegroundColor Green
      return
    }
    if (-not $Update) {
      Write-Host "SKIPPED (exists): $target" -ForegroundColor Yellow
      return
    }
    if ($protectProjectFiles -and (Test-Kept $relative)) {
      Write-Host "KEPT (yours): $target" -ForegroundColor Yellow
      return
    }
    if ((Get-FileHash $_.FullName).Hash -eq (Get-FileHash $target).Hash) {
      Write-Host "same: $target" -ForegroundColor DarkGray
      return
    }
    Copy-Item -Path $target -Destination "$target.bak-$stamp"
    Copy-Item -Path $_.FullName -Destination $target -Force
    Write-Host "UPDATED: $target  (old copy: $relative.bak-$stamp)" -ForegroundColor Cyan
  }
}

if (-not $UserLevel -and -not $Project) {
  Write-Host 'Nothing to do. Use -UserLevel and/or -Project "<path>". See README.md.'
  exit 1
}

if ($UserLevel) {
  $claude = Join-Path $env:USERPROFILE '.claude'
  Write-Host "`n== Spartans -> $claude\agents" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\agents') (Join-Path $claude 'agents') $false
  Write-Host "`n== Armory skills -> $claude\skills" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\skills') (Join-Path $claude 'skills') $false
}

if ($Project) {
  if (-not (Test-Path $Project)) { throw "Project folder not found: $Project" }
  $projectFull = (Resolve-Path $Project).Path
  Write-Host "`n== Project template -> $projectFull" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'project-template') $projectFull $true
}

Write-Host "`nDone. Restart Claude Code so it picks up new agents, skills and hooks." -ForegroundColor Cyan
if ($Update) {
  Write-Host 'Old copies of replaced files were saved as <name>.bak-<date-time>; delete them when you are happy.' -ForegroundColor Cyan
}
