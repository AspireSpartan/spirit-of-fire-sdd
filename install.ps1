<#
  Spirit of Fire SDD installer (Windows PowerShell 5.1+).

  Easiest: run it with no options and answer the questions.
    .\install.ps1
  It asks where to install (globally or this project only), which project, and where the
  supply depot lives (specs, tasks, memory...). It shows what is already there and waits for
  your Y before it copies anything.

  Where to install (-Scope):
    Global        agents + skills go to %USERPROFILE%\.claude (every project sees them);
                  commander, hooks and settings go into the project.
    Project       everything goes inside the project (agents + skills to <project>\.claude\).
                  Nothing is written to %USERPROFILE%\.claude\agents or \skills.

  Where the supply depot lives (-Depot): RULES, MEMORY, DECISIONS, NOTEBOOK, policies,
  research, specs and tasks.
    Project         <project>\.agents\, committed with the code (the v0.3 layout)
    ProjectIgnored  <project>\.agents\, but listed in .gitignore so it is never committed
    Global          %USERPROFILE%\.claude\spirit-of-fire\<owner-repo>\, outside the repository:
                      RULES, MEMORY, DECISIONS, policies\, research\, archive\  shared by all branches
                      branches\<branch>\NOTEBOOK.md, specs\, tasks\               one set per branch
                    An existing <project>\.agents\ is COPIED in (never moved or overwritten).

  Skipping parts (-Skip), for when you already have your own setup for something:
    Agents     the Spartans and the ODST (agent files)
    Skills     the armory skills
    Commander  .claude\CPT_CUTTER.md and the CLAUDE.md loader lines (they are shown for you to add by hand)
    Hooks      .claude\settings.json and .claude\hooks\ (session brief, branch guard, notebook reminder, depot map)
    Depot      the supply depot template (.agents\ or the global depot folder)
    GitIgnore  the .gitignore file and the lines the installer adds to it
    Browser    browser checks: the pinned Playwright harness in %USERPROFILE%\.claude\tools\pw-harness
               (-Scope Project: <project>\.claude\tools\pw-harness). Needs Node.js and npm; downloads
               playwright-core and axe-core (exact versions) but never a browser.
  Interactive runs ask the same thing after the depot question: Enter installs everything,
  or type the numbers of the parts to skip. Then they ask "Install browser checks? (Y/N)".
    .\install.ps1 -Scope Global -Project "D:\path\to\project" -Skip Hooks,GitIgnore
    .\install.ps1 -Scope Global -Project "D:\path\to\project" -Skip Browser      # no browser checks

  Default: copies files only and never overwrites. Anything that already exists is listed as
  SKIPPED so you can merge it by hand.

  With -Update: framework files that already exist and DIFFER are replaced by the new version,
  after the old one is saved next to it as <name>.bak-<date-time>. Your own files are never
  replaced (they are listed as KEPT): CLAUDE.md, .gitignore, .agents\supply\*, .agents\policies\*,
  .claude\spirit-of-fire.json, and everything in a global depot.

  Without questions:
    .\install.ps1 -Scope Global  -Project "D:\path\to\project"                  # depot in the project
    .\install.ps1 -Scope Project -Project "D:\path\to\project" -Depot Global
    .\install.ps1 -Scope Project -Project "D:\path\to\project" -Depot ProjectIgnored
    .\install.ps1 -Scope Global                                                  # agents + skills only
    (-DepotName <name> sets the global depot's folder name; default: owner-repo from git)

  The older options still work the same way (global install, depot in the project):
    .\install.ps1 -UserLevel
    .\install.ps1 -Project "D:\path\to\project"

  After a git pull of this folder, take the improved files with -Update and the same choices:
    .\install.ps1 -Update
#>
param(
  [switch]$UserLevel,
  [string]$Project,
  [ValidateSet('Global', 'Project')]
  [string]$Scope,
  [ValidateSet('Project', 'ProjectIgnored', 'Global')]
  [string]$Depot,
  [string]$DepotName,
  [ValidateSet('Agents', 'Skills', 'Commander', 'Hooks', 'Depot', 'GitIgnore', 'Browser')]
  [string[]]$Skip = @(),
  [switch]$Update
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$userClaude = Join-Path $env:USERPROFILE '.claude'
$utf8 = New-Object System.Text.UTF8Encoding $false

# Parts the user can skip, in the order the interactive question lists them.
$partInfo = [ordered]@{
  'Agents'    = 'Spartans and ODST       agent files (jerome, alice, odst, douglas, anders)'
  'Skills'    = 'Armory skills           sdd-plan, sdd-code, sdd-review, sitrep, ...'
  'Commander' = 'Commander               .claude\CPT_CUTTER.md + the CLAUDE.md loader lines'
  'Hooks'     = 'Hooks                   .claude\settings.json + .claude\hooks\ (session brief, branch guard, notebook reminder)'
  'Depot'     = 'Supply depot            rules, memory, notebook, specs, tasks template'
  'GitIgnore' = '.gitignore              the template file and the lines added to it'
}
$skipSet = New-Object System.Collections.Generic.List[string]
foreach ($s in $Skip) { if (-not $skipSet.Contains($s)) { $skipSet.Add($s) } }
function Test-Skip([string]$part) { return $skipSet.Contains($part) }
function Add-Skip([string]$part) { if (-not $skipSet.Contains($part)) { $skipSet.Add($part) } }

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

function Copy-One([string]$source, [string]$target, [bool]$kept) {
  if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -Path $source -Destination $target
    Write-Host "added: $target" -ForegroundColor Green
    return
  }
  if (-not $Update) {
    Write-Host "SKIPPED (exists): $target" -ForegroundColor Yellow
    return
  }
  if ($kept) {
    Write-Host "KEPT (yours): $target" -ForegroundColor Yellow
    return
  }
  if ((Get-FileHash $source).Hash -eq (Get-FileHash $target).Hash) {
    Write-Host "same: $target" -ForegroundColor DarkGray
    return
  }
  Copy-Item -Path $target -Destination "$target.bak-$stamp"
  Copy-Item -Path $source -Destination $target -Force
  Write-Host "UPDATED: $target  (old copy: $(Split-Path -Leaf $target).bak-$stamp)" -ForegroundColor Cyan
}

function Get-Relative([string]$from, [string]$full) {
  return $full.Substring($from.Length).TrimStart('\', '/').Replace('/', '\')
}

function Copy-Tree([string]$from, [string]$to, [bool]$protectProjectFiles, [string[]]$exclude) {
  Get-ChildItem -Path $from -Recurse -File -Force | ForEach-Object {
    $relative = Get-Relative $from $_.FullName
    foreach ($x in @($exclude | Where-Object { $_ })) { if ($relative -like "$x*") { return } }
    Copy-One $_.FullName (Join-Path $to $relative) ($protectProjectFiles -and (Test-Kept $relative))
  }
}

# Where a file from a project's .agents\ folder goes in a global depot ($null = not carried over).
function Get-DepotTarget([string]$relative, [string]$base, [string]$branchDir) {
  $r = $relative.Replace('/', '\')
  if ($r -match '^(supply|skills)\\NOTEBOOK\.md$') { return Join-Path $branchDir 'NOTEBOOK.md' }
  if ($r -match '^(supply|skills)\\(RULES|MEMORY|DECISIONS)\.md$') { return Join-Path $base "$($Matches[2]).md" }
  if ($r -match '^supply\\(.+)$') { return Join-Path $base $Matches[1] }
  if ($r -match '^policies\\(.+)$') { return Join-Path $base "policies\$($Matches[1])" }
  if ($r -match '^research\\(.+)$') { return Join-Path $base "research\$($Matches[1])" }
  if ($r -match '^tasks\\archive\\(.+)$') { return Join-Path $base "archive\$($Matches[1])" }
  if ($r -match '^specs\\(.+)$') { return Join-Path $branchDir "specs\$($Matches[1])" }
  if ($r -match '^tasks\\(.+)$') { return Join-Path $branchDir "tasks\$($Matches[1])" }
  return $null
}

# Copy a .agents\ folder into the global depot. Depot files are always yours: never overwritten.
function Copy-ToDepot([string]$agentsDir, [string]$base, [string]$branchDir) {
  Get-ChildItem -Path $agentsDir -Recurse -File -Force | ForEach-Object {
    $relative = Get-Relative $agentsDir $_.FullName
    $target = Get-DepotTarget $relative $base $branchDir
    if (-not $target) { return }
    if ((Test-Path $target) -and $_.Name -eq '.gitkeep') { return }
    if (Test-Path $target) {
      Write-Host "KEPT (yours): $target" -ForegroundColor Yellow
      return
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -Path $_.FullName -Destination $target
    Write-Host "added: $target" -ForegroundColor Green
    $script:depotCopied++
  }
}

function Invoke-Git([string]$folder, [string[]]$arguments) {
  try {
    $output = & git -C $folder @arguments 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($output | Out-String).Trim()
  } catch {
    return $null
  }
}

function Get-RepoName([string]$folder) {
  $url = Invoke-Git $folder @('remote', 'get-url', 'origin')
  $name = ''
  if ($url -and $url -match '[:/]([^/:]+)/([^/]+?)(\.git)?/?$') { $name = "$($Matches[1])-$($Matches[2])" }
  if (-not $name) { $name = Split-Path -Leaf $folder }
  return ($name -replace '[^\w.-]+', '-')
}

# Same rule as .claude\hooks\depot.mjs, so the installer and the hook pick the same folder.
function Get-BranchSlug([string]$folder) {
  $branch = Invoke-Git $folder @('branch', '--show-current')
  if ($null -eq $branch) { return 'no-git' }
  if (-not $branch) { return 'detached-HEAD' }
  $slug = ($branch -replace '[\\/:*?"<>|\s]+', '-').Trim('-')
  if (-not $slug) { return 'unnamed' }
  return $slug
}

function Read-Json([string]$path) {
  if (Test-Path $path) {
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Trim()) { return ($text | ConvertFrom-Json) }
  }
  return New-Object PSObject
}

function Write-Json([string]$path, $object) {
  $text = ConvertTo-Json -InputObject $object -Depth 20
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
  [System.IO.File]::WriteAllText($path, $text + "`n", $utf8)
}

function Backup-File([string]$path) {
  if (Test-Path $path) { Copy-Item -Path $path -Destination "$path.bak-$stamp" }
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
      $answer = (Read-Host "Project folder to set up too (Enter = $current, S = skip, agents and skills only)").Trim().Trim('"')
      if ($answer -eq '-' -or $answer -eq 'S' -or $answer -eq 's') { return '' }
    }
    if (-not $answer) { $answer = $current }
    if (Test-Path $answer -PathType Container) { return (Resolve-Path $answer).Path }
    Write-Host "Folder not found: $answer" -ForegroundColor Yellow
  }
}

# --- Browser checks (pinned Playwright harness) -----------------------------------

# Newest cached Playwright build of one kind, e.g. chromium_headless_shell-1228 (or $null).
function Get-CachedBuild([string]$root, [string]$prefix, [string]$exeRelative) {
  if (-not $root -or -not (Test-Path $root)) { return $null }
  $pattern = '^' + [regex]::Escape($prefix) + '-(\d+)$'
  return Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match $pattern } |
    ForEach-Object { [pscustomobject]@{ Build = [int]($_.Name -replace '^.*-', ''); Exe = (Join-Path $_.FullName $exeRelative) } } |
    Where-Object { Test-Path $_.Exe } |
    Sort-Object Build -Descending |
    Select-Object -First 1
}

function Get-ModuleVersion([string]$harness, [string]$name) {
  $pkg = Join-Path $harness "node_modules\$name\package.json"
  if (Test-Path $pkg) { try { return (Read-Json $pkg).version } catch { } }
  return ''
}

function Read-BrowserPath([string]$question) {
  while ($true) {
    $answer = (Read-Host $question).Trim().Trim('"')
    if (-not $answer) { return '' }
    if ((Test-Path $answer -PathType Leaf) -and $answer -like '*.exe') { return (Resolve-Path $answer).Path }
    Write-Host "Not an .exe file: $answer" -ForegroundColor Yellow
  }
}

# Installs or checks the harness; returns a one-line result for the final message.
function Install-BrowserHarness([string]$harness) {
  $ErrorActionPreference = 'Continue'   # npm and node write warnings to stderr; judge them by exit code
  $source = Join-Path $here 'user-level\tools\pw-harness'
  Write-Host "`n== Browser checks -> $harness" -ForegroundColor Cyan
  $node = Get-Command node -ErrorAction SilentlyContinue
  $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if (-not $node -or -not $npm) {
    Write-Host 'Node.js and npm are needed for browser checks and were not found. Install Node.js, then run the installer again.' -ForegroundColor Yellow
    return 'not installed (Node.js or npm missing)'
  }
  Copy-One (Join-Path $source 'package.json') (Join-Path $harness 'package.json') $false
  Copy-One (Join-Path $source 'smoke.cjs') (Join-Path $harness 'smoke.cjs') $false
  $pinned = (Read-Json (Join-Path $harness 'package.json')).dependencies
  $pwPinned = [string]$pinned.'playwright-core'
  $axePinned = [string]$pinned.'axe-core'
  if ($pwPinned -match '[\^~*]' -or $axePinned -match '[\^~*]') {
    Write-Host "package.json in $harness has a version range (^ or ~). Browser checks need exact versions; fix it, then run again." -ForegroundColor Yellow
    return 'not installed (version range in package.json)'
  }

  if ((Get-ModuleVersion $harness 'playwright-core') -eq $pwPinned -and (Get-ModuleVersion $harness 'axe-core') -eq $axePinned) {
    Write-Host "same: playwright-core $pwPinned, axe-core $axePinned already installed" -ForegroundColor DarkGray
  } else {
    Write-Host "npm install (playwright-core $pwPinned, axe-core $axePinned; no browser download, no install scripts)..."
    $oldSkip = $env:PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD
    $env:PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = '1'
    Push-Location $harness
    try {
      & $npm.Source install --save-exact --ignore-scripts --no-audit --no-fund | Out-Host
      $npmOk = ($LASTEXITCODE -eq 0)
    } finally {
      Pop-Location
      $env:PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = $oldSkip
    }
    if (-not $npmOk) {
      Write-Host 'npm install failed (see above). Browser checks are not ready; run the installer again when the network is back.' -ForegroundColor Yellow
      return 'not installed (npm install failed)'
    }
    Write-Host "added: playwright-core $pwPinned, axe-core $axePinned" -ForegroundColor Green
  }

  # The cached browser builds. The harness never downloads one: it reuses what Playwright already cached.
  $browsersDir = if ($env:PLAYWRIGHT_BROWSERS_PATH -and $env:PLAYWRIGHT_BROWSERS_PATH -ne '0') { $env:PLAYWRIGHT_BROWSERS_PATH } else { Join-Path $env:LOCALAPPDATA 'ms-playwright' }
  $expected = ''
  try {
    $manifest = Read-Json (Join-Path $harness 'node_modules\playwright-core\browsers.json')
    $expected = [string](@($manifest.browsers | Where-Object { $_.name -eq 'chromium-headless-shell' })[0].revision)
  } catch { }
  $headless = Get-CachedBuild $browsersDir 'chromium_headless_shell' 'chrome-headless-shell-win64\chrome-headless-shell.exe'
  $visible = Get-CachedBuild $browsersDir 'chromium' 'chrome-win64\chrome.exe'
  $headlessExe = if ($headless) { $headless.Exe } else { '' }
  $visibleExe = if ($visible) { $visible.Exe } else { '' }
  $buildNote = "playwright-core $pwPinned expects build $expected; executablePath is always passed."

  if (-not $headless) {
    Write-Host "No cached headless Chromium found in $browsersDir." -ForegroundColor Yellow
    Write-Host '  The harness never downloads a browser. A cached build appears once any Playwright project on this computer has installed Chromium.' -ForegroundColor Yellow
    if ($interactive) { $headlessExe = Read-BrowserPath 'Full path to chrome-headless-shell.exe or chrome.exe (Enter = skip for now)' }
    if (-not $headlessExe -and $visibleExe) { $headlessExe = $visibleExe; Write-Host "Using the visible Chromium in headless mode: $visibleExe" -ForegroundColor Yellow }
    $buildNote = "No cached headless build was found at install time; $buildNote"
  } elseif ($expected -and [string]$headless.Build -ne $expected) {
    Write-Host "Cached headless build $($headless.Build) differs from build $expected that playwright-core $pwPinned expects." -ForegroundColor Yellow
    Write-Host '  It usually works because executablePath is always passed; the smoke test below decides.' -ForegroundColor Yellow
    if ($interactive -and (Read-Choice "Use cached build $($headless.Build)? (Y/N)" @('Y', 'N')) -eq 'N') {
      $headlessExe = Read-BrowserPath 'Full path to another chrome-headless-shell.exe or chrome.exe (Enter = skip for now)'
    }
    $buildNote = "Cached build $($headless.Build); playwright-core $pwPinned expects build $expected, which is not cached, so always pass executablePath."
  }
  if (-not $visibleExe) { $visibleExe = $headlessExe }

  Write-Json (Join-Path $harness 'harness.json') ([pscustomobject]@{
    headless = $headlessExe; visible = $visibleExe; browsersDir = $browsersDir
    playwrightCore = $pwPinned; axeCore = $axePinned; expectedBuild = $expected
  })

  $smokeCmd = "node `"$(Join-Path $harness 'smoke.cjs')`""
  $harnessMd = Join-Path $harness 'HARNESS.md'
  if (Test-Path $harnessMd) {
    Write-Host "KEPT (yours): $harnessMd  (harness.json has the current browser paths)" -ForegroundColor Yellow
  } else {
    $text = [System.IO.File]::ReadAllText((Join-Path $source 'HARNESS.template.md'))
    $values = @{
      '{{HARNESS}}' = $harness; '{{SCOPE}}' = $(if ($Scope -eq 'Project') { 'project-only install, ignored by git' } else { 'outside every repo' })
      '{{PW_VERSION}}' = $pwPinned; '{{AXE_VERSION}}' = $axePinned; '{{DATE}}' = (Get-Date -Format 'yyyy-MM-dd')
      '{{BROWSERS_DIR}}' = $browsersDir; '{{HEADLESS}}' = $(if ($headlessExe) { $headlessExe } else { 'NOT FOUND: ask the user' })
      '{{VISIBLE}}' = $(if ($visibleExe) { $visibleExe } else { 'NOT FOUND: ask the user' }); '{{BUILD_NOTE}}' = $buildNote; '{{SMOKE}}' = $smokeCmd
    }
    foreach ($k in $values.Keys) { $text = $text.Replace($k, [string]$values[$k]) }
    $text = (($text -split "`r?`n") | Where-Object { $_ -notlike 'The installer writes this file*' }) -join "`r`n"
    [System.IO.File]::WriteAllText($harnessMd, $text, $utf8)
    Write-Host "added: $harnessMd" -ForegroundColor Green
  }

  if (-not $headlessExe) {
    Write-Host 'Smoke test skipped: no browser. Douglas will report "harness missing" until harness.json has a browser path.' -ForegroundColor Yellow
    return "installed, NO BROWSER (fill harness.json in $harness, then run: $smokeCmd)"
  }
  Write-Host "Smoke test: $smokeCmd"
  $smoke = (& $node.Source (Join-Path $harness 'smoke.cjs') 2>&1 | Out-String).Trim()
  $smokeOk = ($LASTEXITCODE -eq 0) -and ($smoke -eq "$pwPinned $axePinned ok")
  if ($smokeOk) {
    Write-Host "  $smoke" -ForegroundColor Green
    return "ready ($smoke)"
  }
  Write-Host "  $smoke" -ForegroundColor Yellow
  Write-Host "Smoke test did not print `"$pwPinned $axePinned ok`". Browser checks are not ready; see HARNESS.md." -ForegroundColor Yellow
  return "installed, smoke test FAILED ($smokeCmd)"
}

function Get-PackageAgents { Get-ChildItem (Join-Path $here 'user-level\agents') -File -Filter *.md | ForEach-Object { $_.Name } }
function Get-PackageSkills { Get-ChildItem (Join-Path $here 'user-level\skills') -Directory | ForEach-Object { $_.Name } }

# The lines in CLAUDE.md that load the commander and the depot.
function Get-LoaderLines([string]$depotMode, [string]$name) {
  if ($depotMode -eq 'Global') {
    return @('@.claude/CPT_CUTTER.md', "@~/.claude/spirit-of-fire/$name/RULES.md", "@~/.claude/spirit-of-fire/$name/MEMORY.md")
  }
  return @('@.claude/CPT_CUTTER.md', '@.agents/supply/RULES.md', '@.agents/supply/MEMORY.md', '@.agents/supply/NOTEBOOK.md')
}

# Replace the Spirit of Fire loader lines in CLAUDE.md (v0.3 or v0.4 style) with the right ones.
function Set-LoaderLines([string]$path, [string[]]$loader) {
  $lines = [System.IO.File]::ReadAllLines($path)
  $result = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  foreach ($line in $lines) {
    $t = $line.Trim()
    $isLoader = $t -eq '@.agents/CPT_CUTTER.md' -or $t -eq '@.claude/CPT_CUTTER.md' -or
                $t -like '@.agents/supply/*' -or $t -like '@~/.claude/spirit-of-fire/*'
    if ($isLoader) {
      if (-not $inserted) { $loader | ForEach-Object { $result.Add($_) }; $inserted = $true }
      continue
    }
    $result.Add($line)
  }
  if (-not $inserted) {
    $result.Add('')
    $result.Add('This project uses the Spirit of Fire SDD workflow:')
    $loader | ForEach-Object { $result.Add($_) }
  }
  [System.IO.File]::WriteAllText($path, (($result -join "`r`n") + "`r`n"), $utf8)
}

function Get-DepotLabel([string]$depotMode) {
  switch ($depotMode) {
    'Project' { return 'project' }
    'ProjectIgnored' { return 'project-ignored' }
    'Global' { return 'global' }
  }
}

function Get-DepotModeFromLabel([string]$label) {
  switch ($label) {
    'project-ignored' { return 'ProjectIgnored' }
    'global' { return 'Global' }
    default { return 'Project' }
  }
}

# --- Decide what to do -------------------------------------------------------

$interactive = $false
if (-not $Scope -and -not $UserLevel -and -not $Project) {
  $interactive = $true
  Write-Host "`nSpirit of Fire SDD installer" -ForegroundColor Cyan
  if ($Update) { Write-Host 'Update mode: framework files that changed are replaced (old copy kept as .bak).' -ForegroundColor Cyan }
  Write-Host 'Where do you want to install the Spartans, the ODST and the skills?'
  Write-Host '  [1] Globally      for ALL projects (in your user .claude folder), plus one project'
  Write-Host '  [2] Project only  everything inside one project; other projects and SDD setups never see it'
  Write-Host '  [S] Skip          I have my own agents and skills: set up the project files only'
  $scopeAnswer = Read-Choice 'Choose 1, 2 or S' @('1', '2', 'S')
  if ($scopeAnswer -eq 'S') { Add-Skip 'Agents'; Add-Skip 'Skills' }
  $Scope = if ($scopeAnswer -eq '2') { 'Project' } else { 'Global' }
  $Project = Read-ProjectPath ($Scope -eq 'Project' -or $scopeAnswer -eq 'S')
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

# Depot: asked when there is a project; otherwise keep what the project already uses.
$depotChosen = $PSBoundParameters.ContainsKey('Depot')
$configPath = ''
$currentDepot = 'Project'
if ($projectFull) {
  $configPath = Join-Path $projectFull '.claude\spirit-of-fire.json'
  if (Test-Path $configPath) {
    try { $currentDepot = Get-DepotModeFromLabel (Read-Json $configPath).depot } catch { }
  }
  if ($interactive) {
    Write-Host "`nWhere should the supply depot live (rules, memory, notebook, specs, tasks)?"
    Write-Host '  [1] In the project, committed to git (.agents\, the v0.3 layout)'
    Write-Host '  [2] In the project, ignored by git (.agents\ is added to .gitignore)'
    Write-Host '  [3] Global folder, by project and branch (your user .claude\spirit-of-fire\, outside the repository)'
    Write-Host '  [S] Skip          I keep my own depot (or none): no depot files are created or changed'
    if (Test-Path $configPath) { Write-Host "  (this project uses: $(Get-DepotLabel $currentDepot))" }
    $depotAnswer = Read-Choice 'Choose 1, 2, 3 or S' @('1', '2', '3', 'S')
    if ($depotAnswer -eq 'S') {
      Add-Skip 'Depot'
      $Depot = $currentDepot
    } else {
      $Depot = switch ($depotAnswer) { '1' { 'Project' } '2' { 'ProjectIgnored' } '3' { 'Global' } }
      $depotChosen = $true
    }
  } elseif (-not $Depot) {
    $Depot = $currentDepot
  }
}

# Which parts to install: everything unless the user skips some (for a setup of their own).
if ($interactive) {
  $parts = @('Agents', 'Skills')
  if ($projectFull) { $parts += @('Commander', 'Hooks', 'Depot', 'GitIgnore') }
  Write-Host "`nWhich parts should be installed? Skip a part when you already have your own setup for it."
  for ($i = 0; $i -lt $parts.Count; $i++) {
    $mark = if (Test-Skip $parts[$i]) { '  (skipped)' } else { '' }
    Write-Host "  [$($i + 1)] $($partInfo[$parts[$i]])$mark"
  }
  while ($true) {
    $answer = (Read-Host 'Enter = install all of these, or type the numbers to SKIP (for example 2,4)').Trim()
    if (-not $answer) { break }
    $numbers = @($answer -split '[,\s]+' | Where-Object { $_ })
    $bad = @($numbers | Where-Object { -not ($_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $parts.Count) })
    if ($bad.Count -eq 0) {
      foreach ($n in $numbers) { Add-Skip $parts[[int]$n - 1] }
      break
    }
    Write-Host "Please type numbers from 1 to $($parts.Count), separated by commas, or press Enter." -ForegroundColor Yellow
  }
}
if ($interactive -and -not (Test-Skip 'Browser')) {
  Write-Host "`nBrowser checks: a small pinned Playwright harness (playwright-core + axe-core, exact versions, no browser download)"
  Write-Host 'that Douglas, Alice and the ODST use to test in a real browser. Needs Node.js and npm, and a Chromium that Playwright already cached.'
  if ((Read-Choice 'Install browser checks? (Y/N)' @('Y', 'N')) -ne 'Y') { Add-Skip 'Browser' }
}
if (Test-Skip 'Depot') { $depotChosen = $false }

$depotBase = ''
$branchSlug = ''
$branchDir = ''
if ($projectFull -and $Depot -eq 'Global') {
  if (-not $DepotName) {
    $existingName = ''
    if (Test-Path $configPath) { try { $existingName = (Read-Json $configPath).depotName } catch { } }
    $DepotName = if ($existingName) { $existingName } else { Get-RepoName $projectFull }
    if ($interactive) {
      $answer = (Read-Host "Depot folder name (Enter = $DepotName)").Trim()
      if ($answer) { $DepotName = $answer }
    }
  }
  $DepotName = $DepotName -replace '[^\w.-]+', '-'
  $depotBase = Join-Path $userClaude "spirit-of-fire\$DepotName"
  $branchSlug = Get-BranchSlug $projectFull
  $branchDir = Join-Path $depotBase "branches\$branchSlug"
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

$copyAgents = $copyAgentsAndSkills -and -not (Test-Skip 'Agents')
$harnessDir = if ($Scope -eq 'Project') { Join-Path $projectFull '.claude\tools\pw-harness' } else { Join-Path $userClaude 'tools\pw-harness' }
$installBrowser = -not (Test-Skip 'Browser')
$copySkills = $copyAgentsAndSkills -and -not (Test-Skip 'Skills')

# Project template files that belong to each skippable part.
$templateExclude = @()
if (Test-Skip 'Commander') { $templateExclude += @('CLAUDE.md', '.claude\CPT_CUTTER.md') }
if (Test-Skip 'Hooks') { $templateExclude += @('.claude\settings.json', '.claude\hooks\') }
if ((Test-Skip 'Depot') -or $Depot -eq 'Global') { $templateExclude += '.agents\' }
if (Test-Skip 'GitIgnore') { $templateExclude += '.gitignore' }

# --- Preview ---------------------------------------------------------------------

$action = if ($Update) { 'framework files that differ are replaced after a .bak copy; your own files are KEPT' } else { 'these are SKIPPED, never overwritten' }
Write-Host "`n== Preview ($scopeName install)" -ForegroundColor Cyan
if ($copyAgents -or $copySkills) { Write-Host "Agents and skills go to: $(Split-Path -Parent $agentsDir)" }
elseif ($copyAgentsAndSkills) { Write-Host 'Agents and skills:       skipped (you use your own)' }
else { Write-Host 'Agents and skills:       not installed this run (add -UserLevel for them)' }
if ($skipSet.Count -gt 0) { Write-Host "Skipped parts:           $($skipSet -join ', ')" -ForegroundColor Yellow }
if ($projectFull) { Write-Host "Project files go to:     $projectFull" } else { Write-Host 'Project files:           none (no project chosen)' }
if ($installBrowser) { Write-Host "Browser checks:          $harnessDir$(if (Test-Path $harnessDir) { ' (exists: checked, updated only where it differs)' })" }
else { Write-Host 'Browser checks:          skipped' }
if ($projectFull -and (Test-Skip 'Depot')) {
  Write-Host "Supply depot:            skipped (nothing created; Cutter's orders still expect the $(Get-DepotLabel $Depot) layout)"
} elseif ($projectFull) {
  switch ($Depot) {
    'Project' { Write-Host "Supply depot:            $projectFull\.agents (committed with the code)" }
    'ProjectIgnored' { Write-Host "Supply depot:            $projectFull\.agents (ignored by git)" }
    'Global' {
      Write-Host "Supply depot:            $depotBase$(if (Test-Path $depotBase) { ' (exists: your files there are kept)' })"
      Write-Host "  this branch's folder:  $branchDir"
    }
  }
}

$found = @()
if ($copyAgents) {
  foreach ($name in Get-PackageAgents) {
    if (Test-Path (Join-Path $agentsDir $name)) { $found += "agent  $(Join-Path $agentsDir $name)" }
  }
}
if ($copySkills) {
  foreach ($name in Get-PackageSkills) {
    if (Test-Path (Join-Path $skillsDir $name)) { $found += "skill  $(Join-Path $skillsDir $name)" }
  }
}
if ($projectFull) {
  $items = @('.claude\spirit-of-fire.json')
  if (-not (Test-Skip 'Commander')) { $items += 'CLAUDE.md' }
  if (-not (Test-Skip 'Hooks')) { $items += @('.claude\settings.json', '.claude\hooks') }
  if ($Depot -ne 'Global' -and -not (Test-Skip 'Depot')) { $items += '.agents' }
  foreach ($item in $items) {
    if (Test-Path (Join-Path $projectFull $item)) { $found += "file   $(Join-Path $projectFull $item)" }
  }
}
if ($found.Count -eq 0) {
  Write-Host 'Nothing of the same name is there yet. Everything will be added.' -ForegroundColor Green
} else {
  Write-Host "Already there ($action):" -ForegroundColor Yellow
  $found | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

if ($scopeName -eq 'Project only') {
  $shadow = @()
  if ($copyAgents) { foreach ($name in Get-PackageAgents) {
    if (Test-Path (Join-Path $userClaude "agents\$name")) { $shadow += "agent  $(Join-Path $userClaude "agents\$name")" }
  } }
  if ($copySkills) { foreach ($name in Get-PackageSkills) {
    if (Test-Path (Join-Path $userClaude "skills\$name")) { $shadow += "skill  $(Join-Path $userClaude "skills\$name")" }
  } }
  if ($shadow.Count -gt 0) {
    Write-Host 'Your user folder also has these names. Claude Code may use those copies instead of the project ones:' -ForegroundColor Yellow
    $shadow | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
  }
}

$claudeMd = ''
$claudeMdExisted = $false
$claudeMdKind = 'none'
if ($projectFull) {
  $claudeMd = Join-Path $projectFull 'CLAUDE.md'
  $claudeMdExisted = Test-Path $claudeMd
  if ($claudeMdExisted) {
    $text = [System.IO.File]::ReadAllText($claudeMd)
    if ($text -match '(?m)^\s*@\.claude/CPT_CUTTER\.md') { $claudeMdKind = 'v04' }
    elseif ($text -match '(?m)^\s*@\.agents/CPT_CUTTER\.md') { $claudeMdKind = 'v03' }
    else { $claudeMdKind = 'other' }
  }
  if ($Depot -eq 'Global' -and -not (Test-Skip 'Depot') -and (Test-Path (Join-Path $projectFull '.agents'))) {
    Write-Host "Existing $projectFull\.agents will be COPIED into the depot (nothing there is moved, deleted or overwritten)." -ForegroundColor Yellow
  }
  if (Test-Skip 'Commander') { $claudeMdKind = 'skipped' }
  if ((Test-Skip 'Hooks') -and $Depot -eq 'Global') {
    Write-Host 'Hooks skipped with a global depot: Cutter gets no Depot map at session start, so tell him where the depot is.' -ForegroundColor Yellow
  }
  switch ($claudeMdKind) {
    'v03' { Write-Host 'CLAUDE.md loads the v0.3 commander (.agents/CPT_CUTTER.md): its loader lines will be updated (backup kept).' -ForegroundColor Yellow }
    'other' { Write-Host 'CLAUDE.md is not a Spirit of Fire loader (another setup?). You will be asked before anything is added to it.' -ForegroundColor Yellow }
  }
}

if ($interactive) {
  if ((Read-Choice "`nContinue? (Y/N)" @('Y', 'N')) -ne 'Y') {
    Write-Host 'Stopped. Nothing was copied.'
    exit 0
  }
}

# --- Copy ----------------------------------------------------------------------

# Agents that are new or changed this run: Claude Code loads agents only at start, so these need a restart.
$agentsChanged = @()
if ($copyAgents) {
  foreach ($name in Get-PackageAgents) {
    $target = Join-Path $agentsDir $name
    $source = Join-Path $here "user-level\agents\$name"
    if (-not (Test-Path $target)) { $agentsChanged += $name }
    elseif ($Update -and (Get-FileHash $source).Hash -ne (Get-FileHash $target).Hash) { $agentsChanged += $name }
  }
}
if ($copyAgents) {
  Write-Host "`n== Spartans and ODST -> $agentsDir" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\agents') $agentsDir $false @()
}
if ($copySkills) {
  Write-Host "`n== Armory skills -> $skillsDir" -ForegroundColor Cyan
  Copy-Tree (Join-Path $here 'user-level\skills') $skillsDir $false @()
}

if ($projectFull) {
  $template = Join-Path $here 'project-template'
  Write-Host "`n== Project template -> $projectFull" -ForegroundColor Cyan
  Copy-Tree $template $projectFull $true $templateExclude

  $script:depotCopied = 0
  if ($Depot -eq 'Global' -and -not (Test-Skip 'Depot')) {
    $oldAgents = Join-Path $projectFull '.agents'
    if (Test-Path $oldAgents) {
      Write-Host "`n== Existing .agents -> depot $depotBase" -ForegroundColor Cyan
      Copy-ToDepot $oldAgents $depotBase $branchDir
    }
    Write-Host "`n== Depot template -> $depotBase" -ForegroundColor Cyan
    Copy-ToDepot (Join-Path $template '.agents') $depotBase $branchDir
    New-Item -ItemType Directory -Force -Path (Join-Path $branchDir 'tasks\requires-review'), (Join-Path $branchDir 'tasks\evidence'), (Join-Path $branchDir 'specs') | Out-Null

    # Let Claude Code read and write the depot without asking each time (per machine, not committed).
    $localSettings = Join-Path $projectFull '.claude\settings.local.json'
    $settings = Read-Json $localSettings
    if (-not $settings.permissions) { $settings | Add-Member -NotePropertyName permissions -NotePropertyValue (New-Object PSObject) -Force }
    $dirs = @(@($settings.permissions.additionalDirectories) | Where-Object { $_ })
    if ($dirs -notcontains $depotBase) {
      Backup-File $localSettings
      $dirs += $depotBase
      $settings.permissions | Add-Member -NotePropertyName additionalDirectories -NotePropertyValue $dirs -Force
      Write-Json $localSettings $settings
      Write-Host "added the depot to allowed folders: $localSettings" -ForegroundColor Green
    }
  }

  # .gitignore: settings.local.json is per machine; .agents\ when the depot is ignored by git.
  $gitignore = Join-Path $projectFull '.gitignore'
  $ignoreLines = @()
  if ($Depot -eq 'Global') { $ignoreLines += '.claude/settings.local.json' }
  if ($Depot -eq 'ProjectIgnored') { $ignoreLines += '.agents/' }
  if ($Depot -eq 'Project') { $ignoreLines += '.agents/evidence/' }
  if ($installBrowser -and $Scope -eq 'Project') { $ignoreLines += '.claude/tools/' }
  $currentIgnore = if (Test-Path $gitignore) { [System.IO.File]::ReadAllLines($gitignore) } else { @() }
  $missing = @($ignoreLines | Where-Object { $currentIgnore -notcontains $_ })
  if ((Test-Skip 'GitIgnore') -or (Test-Skip 'Depot')) {
    if ($missing.Count -gt 0 -and -not (Test-Skip 'Depot')) {
      Write-Host "GitIgnore skipped. Add these lines to your .gitignore yourself: $($missing -join ', ')" -ForegroundColor Yellow
    }
  } elseif ($missing.Count -gt 0) {
    $add = "`r`n# Spirit of Fire (depot, browser-check evidence, harness)`r`n" + ($missing -join "`r`n") + "`r`n"
    [System.IO.File]::AppendAllText($gitignore, $add, $utf8)
    Write-Host "added to .gitignore: $($missing -join ', ')" -ForegroundColor Green
  }
  if ($Depot -ne 'Project' -and -not (Test-Skip 'Depot')) {
    $tracked = Invoke-Git $projectFull @('ls-files', '.agents')
    if ($tracked) {
      Write-Host 'Note: .agents\ files are still tracked by git. To stop committing them (your files stay on disk):' -ForegroundColor Yellow
      Write-Host "  git -C `"$projectFull`" rm -r --cached .agents" -ForegroundColor Yellow
      Write-Host '  then commit that change. Their history stays in git.' -ForegroundColor Yellow
    }
  }

  # spirit-of-fire.json: record the depot choice (only when it was chosen this run).
  if ($depotChosen) {
    $config = Read-Json $configPath
    $label = Get-DepotLabel $Depot
    $changed = ($config.depot -ne $label) -or ($Depot -eq 'Global' -and $config.depotName -ne $DepotName)
    if ($changed) {
      Backup-File $configPath
      $config | Add-Member -NotePropertyName depot -NotePropertyValue $label -Force
      if ($Depot -eq 'Global') { $config | Add-Member -NotePropertyName depotName -NotePropertyValue $DepotName -Force }
      Write-Json $configPath $config
      Write-Host "set depot = $label in $configPath" -ForegroundColor Green
    }
  }

  # CLAUDE.md: make the loader lines match the depot.
  $loader = Get-LoaderLines $Depot $DepotName
  if (Test-Skip 'Commander') {
    Write-Host "`nCommander skipped. For Spirit of Fire to load, CLAUDE.md needs these lines (and .claude\CPT_CUTTER.md from this package):" -ForegroundColor Yellow
    $loader | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
  } elseif (-not $claudeMdExisted -or $claudeMdKind -eq 'v04' -or $claudeMdKind -eq 'v03') {
    $before = [System.IO.File]::ReadAllLines($claudeMd) -join "`n"
    $copy = "$claudeMd.tmp-$stamp"
    Copy-Item $claudeMd $copy
    Set-LoaderLines $copy $loader
    if (([System.IO.File]::ReadAllLines($copy) -join "`n") -ne $before) {
      if ($claudeMdExisted) { Backup-File $claudeMd }
      Move-Item -Force $copy $claudeMd
      Write-Host "CLAUDE.md loader lines set for the $(Get-DepotLabel $Depot) depot" -ForegroundColor Green
      if ($claudeMdKind -eq 'v03') { Write-Host "  The old $projectFull\.agents\CPT_CUTTER.md is no longer loaded; delete it when you are happy." -ForegroundColor Yellow }
    } else {
      Remove-Item $copy
    }
  } else {
    Write-Host "`nCLAUDE.md is your own (not a Spirit of Fire loader). Spirit of Fire needs these lines in it:" -ForegroundColor Yellow
    $loader | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    $addNow = if ($interactive) { (Read-Choice 'Add them to the end of your CLAUDE.md now? A backup is kept. (Y/N)' @('Y', 'N')) -eq 'Y' } else { $false }
    if ($addNow) {
      Backup-File $claudeMd
      Set-LoaderLines $claudeMd $loader
      Write-Host 'added the loader lines to CLAUDE.md' -ForegroundColor Green
    } else {
      Write-Host '  Add them by hand when you are ready, or ask Cutter for the setup mission to merge your old rules.' -ForegroundColor Yellow
    }
  }
}

$browserResult = 'skipped'
if ($installBrowser) { $browserResult = Install-BrowserHarness $harnessDir }

Write-Host "`nDone ($scopeName). Restart Claude Code so it picks up new agents, skills and hooks." -ForegroundColor Cyan
if ($agentsChanged.Count -gt 0) {
  Write-Host "RESTART CLAUDE CODE NOW: new or changed agents ($($agentsChanged -join ', ')) are not loaded until you do. Until then Cutter cannot send them (for example a missing odst: he would have to send Alice)." -ForegroundColor Yellow
}
Write-Host "Browser checks: $browserResult" -ForegroundColor Cyan
if ($installBrowser -and $projectFull -and -not (Test-Skip 'Depot')) {
  Write-Host 'Next for browser checks: ask Cutter for the setup mission (browser part). Jerome fills .agents\supply\BROWSER_CHECKS.md from the code and asks you the rest.' -ForegroundColor Cyan
}
if ($Scope -eq 'Project' -and ($copyAgents -or $copySkills)) {
  Write-Host 'The agents and skills are in the project''s .claude folder: commit them with the project, and run the installer again for each project you want Spirit of Fire in.' -ForegroundColor Cyan
}
if ($projectFull -and $Depot -eq 'Global' -and -not (Test-Skip 'Depot')) {
  Write-Host "Depot: $depotBase. The first session asks once to allow CLAUDE.md to load files from it; say yes." -ForegroundColor Cyan
  if ($script:depotCopied -gt 0 -and (Test-Path (Join-Path $projectFull '.agents'))) {
    Write-Host "Your old $projectFull\.agents was copied, not moved. Check the depot, then delete .agents\ yourself." -ForegroundColor Cyan
  }
}
if ($Update) {
  Write-Host 'Old copies of replaced files were saved as <name>.bak-<date-time>; delete them when you are happy.' -ForegroundColor Cyan
}
