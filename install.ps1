<#
  Spirit of Fire SDD installer (Windows PowerShell 5.1+).

  Easiest: run it with no options and answer the questions.
    .\install.ps1
  It asks where to install (globally or this project only) and which project, shows what is
  already there, and waits for your Y before it copies anything.

  Two ways to install:
    Global        agents + skills go to %USERPROFILE%\.claude (every project sees them);
                  commander, supply depot and hooks go into the project.
    Project only  everything goes inside the project (agents + skills to <project>\.claude\).
                  Nothing is written to %USERPROFILE%\.claude, so your other projects and any
                  other SDD setup you run never see Spirit of Fire.

  Default: copies files only and never overwrites. Anything that already exists is listed as
  SKIPPED so you can merge it by hand.

  With -Update: files that already exist and DIFFER are replaced by the new version, after the
  old one is saved next to it as <name>.bak-<date-time>. Your own project files are never replaced,
  even with -Update (they are listed as KEPT): CLAUDE.md, .gitignore, .agents\supply\* (RULES,
  MEMORY, NOTEBOOK, DECISIONS), .agents\policies\*, and .claude\spirit-of-fire.json.

  Without questions (for scripts, or if you already know):
    .\install.ps1 -Scope Global  -Project "D:\path\to\your-project"
    .\install.ps1 -Scope Global                                     # agents + skills only
    .\install.ps1 -Scope Project -Project "D:\path\to\your-project"

  The older options still work the same way (global install):
    .\install.ps1 -UserLevel
    .\install.ps1 -Project "D:\path\to\your-project"
    .\install.ps1 -UserLevel -Project "D:\path\to\your-project"

  After a git pull of this folder, take the improved skills, agents, commander orders and hooks.
  Use the same scope you installed with:
    .\install.ps1 -Scope Global  -Project "D:\path\to\your-project" -Update
    .\install.ps1 -Scope Project -Project "D:\path\to\your-project" -Update
  (or just .\install.ps1 -Update and answer the questions)
#>
param(
  [switch]$UserLevel,
  [string]$Project,
  [ValidateSet('Global', 'Project')]
  [string]$Scope,
  [switch]$Update
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$userClaude = Join-Path $env:USERPROFILE '.claude'

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
    $relative = $_.FullName.Substring($from.Length).TrimStart('\', '/')
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

function Read-Choice([string]$question, [string[]]$allowed) {
  while ($true) {
    $answer = (Read-Host $question).Trim()
    if ($allowed -contains $answer.ToUpper()) { return $answer.ToUpper() }
    Write-Host "Please type one of: $($allowed -join ', ')" -ForegroundColor Yellow
  }
}

function Read-ProjectPath([bool]$required) {
  $current = (Get-Location).Path
  while ($true) {
    if ($required) {
      $answer = (Read-Host "Project folder (Enter = $current)").Trim().Trim('"')
    } else {
      $answer = (Read-Host "Project folder to set up too (Enter = $current, '-' = skip, agents and skills only)").Trim().Trim('"')
      if ($answer -eq '-') { return '' }
    }
    if (-not $answer) { $answer = $current }
    if (Test-Path $answer -PathType Container) { return (Resolve-Path $answer).Path }
    Write-Host "Folder not found: $answer" -ForegroundColor Yellow
  }
}

# Names of the agents and skills this package installs.
function Get-PackageAgents { Get-ChildItem (Join-Path $here 'user-level\agents') -File -Filter *.md | ForEach-Object { $_.Name } }
function Get-PackageSkills { Get-ChildItem (Join-Path $here 'user-level\skills') -Directory | ForEach-Object { $_.Name } }

# Show what is already in place before anything is copied.
function Show-Preview([string]$agentsDir, [string]$skillsDir, [string]$projectDir, [string]$scopeName, [bool]$withAgents) {
  $action = if ($Update) { 'framework files that differ are replaced after a .bak copy; your own project files are KEPT' } else { 'these are SKIPPED, never overwritten' }
  Write-Host "`n== Preview ($scopeName install)" -ForegroundColor Cyan
  if ($withAgents) { Write-Host "Agents and skills go to: $(Split-Path -Parent $agentsDir)" } else { Write-Host 'Agents and skills:       not installed this run (add -UserLevel for them)' }
  if ($projectDir) { Write-Host "Project files go to:     $projectDir" } else { Write-Host 'Project files:           none (no project chosen)' }

  $found = @()
  if ($withAgents) {
    foreach ($name in Get-PackageAgents) {
      if (Test-Path (Join-Path $agentsDir $name)) { $found += "agent  $(Join-Path $agentsDir $name)" }
    }
    foreach ($name in Get-PackageSkills) {
      if (Test-Path (Join-Path $skillsDir $name)) { $found += "skill  $(Join-Path $skillsDir $name)" }
    }
  }
  if ($projectDir) {
    foreach ($item in @('CLAUDE.md', '.claude\settings.json', '.claude\hooks', '.claude\spirit-of-fire.json', '.agents')) {
      if (Test-Path (Join-Path $projectDir $item)) { $found += "file   $(Join-Path $projectDir $item)" }
    }
  }

  if ($found.Count -eq 0) {
    Write-Host 'Nothing of the same name is there yet. Everything will be added.' -ForegroundColor Green
  } else {
    Write-Host "Already there ($action):" -ForegroundColor Yellow
    $found | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    if (-not $Update) {
      Write-Host 'A skipped CLAUDE.md or .claude\settings.json means Spirit of Fire or its hooks will not load until you merge them by hand (see README, Step 2).' -ForegroundColor Yellow
    }
  }

  # Project only: a user-level agent or skill with the same name can still be picked up.
  if ($scopeName -eq 'Project only') {
    $shadow = @()
    foreach ($name in Get-PackageAgents) {
      if (Test-Path (Join-Path $userClaude "agents\$name")) { $shadow += "agent  $(Join-Path $userClaude "agents\$name")" }
    }
    foreach ($name in Get-PackageSkills) {
      if (Test-Path (Join-Path $userClaude "skills\$name")) { $shadow += "skill  $(Join-Path $userClaude "skills\$name")" }
    }
    if ($shadow.Count -gt 0) {
      Write-Host 'Your user folder also has these names. Claude Code may use those copies instead of the project ones:' -ForegroundColor Yellow
      $shadow | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    }
  }
}

# --- Decide what to do -------------------------------------------------------

$interactive = $false
if (-not $Scope -and -not $UserLevel -and -not $Project) {
  # No options: ask.
  $interactive = $true
  Write-Host "`nSpirit of Fire SDD installer" -ForegroundColor Cyan
  if ($Update) { Write-Host 'Update mode: framework files that changed are replaced (old copy kept as .bak).' -ForegroundColor Cyan }
  Write-Host 'Where do you want to install?'
  Write-Host '  [1] Globally      agents + skills for ALL projects (in your user .claude folder), plus one project'
  Write-Host '  [2] Project only  everything inside one project; other projects and SDD setups never see it'
  $Scope = if ((Read-Choice 'Choose 1 or 2' @('1', '2')) -eq '1') { 'Global' } else { 'Project' }
  $Project = Read-ProjectPath ($Scope -eq 'Project')
} elseif (-not $Scope) {
  # Older options (-UserLevel / -Project): global install, same as before.
  $Scope = 'Global'
}

if ($Scope -eq 'Global' -and ($interactive -or $PSBoundParameters.ContainsKey('Scope'))) { $UserLevel = $true }

if ($Scope -eq 'Project' -and -not $Project) {
  Write-Host '-Scope Project needs -Project "<path>". See README.md.'
  exit 1
}

$projectFull = ''
if ($Project) {
  if (-not (Test-Path $Project -PathType Container)) { throw "Project folder not found: $Project" }
  $projectFull = (Resolve-Path $Project).Path
}

if ($Scope -eq 'Project') {
  $agentsDir = Join-Path $projectFull '.claude\agents'
  $skillsDir = Join-Path $projectFull '.claude\skills'
  $scopeName = 'Project only'
  $copyAgentsAndSkills = $true
} else {
  $agentsDir = Join-Path $userClaude 'agents'
  $skillsDir = Join-Path $userClaude 'skills'
  $scopeName = 'Global'
  $copyAgentsAndSkills = [bool]$UserLevel
}

Show-Preview $agentsDir $skillsDir $projectFull $scopeName $copyAgentsAndSkills

if ($interactive) {
  if ((Read-Choice "`nContinue? (Y/N)" @('Y', 'N')) -ne 'Y') {
    Write-Host 'Stopped. Nothing was copied.'
    exit 0
  }
}

# --- Copy ----------------------------------------------------------------------

if ($copyAgentsAndSkills) {
  Write-Host "`n== Spartans -> $agentsDir" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\agents') $agentsDir $false
  Write-Host "`n== Armory skills -> $skillsDir" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\skills') $skillsDir $false
}

if ($projectFull) {
  Write-Host "`n== Project template -> $projectFull" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'project-template') $projectFull $true
}

Write-Host "`nDone ($scopeName). Restart Claude Code so it picks up new agents, skills and hooks." -ForegroundColor Cyan
if ($Scope -eq 'Project') {
  Write-Host 'The agents and skills are in the project''s .claude folder: commit them with the project, and run the installer again for each project you want Spirit of Fire in.' -ForegroundColor Cyan
}
if ($Update) {
  Write-Host 'Old copies of replaced files were saved as <name>.bak-<date-time>; delete them when you are happy.' -ForegroundColor Cyan
}
