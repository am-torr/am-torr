#requires -Version 7.0
<#
.SYNOPSIS
    Reproducible builder for the am-torr GitHub profile README (task
    2026-07-29-portfolio-readme-update).

.DESCRIPTION
    Assembles README.md for https://github.com/am-torr/am-torr from three inputs:

      1. The existing README (everything outside the "Featured Projects" section is
         preserved verbatim except for typography -- see Convert-ToAscii).
      2. A canonical, in-script table of the four portfolio sections.
      3. A LIVE `gh repo view <owner>/<repo> --json isPrivate` read per repo. When a
         repo reports isPrivate=true the literal string " (Private Repository)" is
         appended to that section heading. Nothing about visibility is hardcoded.

    The whole output file is transliterated to 7-bit ASCII (no emoji, no middle dots,
    no smart quotes, no en/em dashes, no Unicode arrows) and written BOM-free. The
    script THROWS rather than silently dropping any byte it does not know how to map.

    The script is idempotent: it replaces the entire body of the "Featured Projects"
    section on every run, so re-running it against its own output reproduces the same
    file (modulo a change in live repo visibility).

.PARAMETER RepoPath
    Root of the am-torr/am-torr working copy. Auto-detected when omitted.

.PARAMETER SourceReadme
    README to read. Defaults to <RepoPath>\README.md.

.PARAMETER OutFile
    README to write. Defaults to <SourceReadme> (in-place).

.PARAMETER WhatIfOnly
    Build and verify in memory, print the report, write nothing.

.EXAMPLE
    pwsh -File build-readme.ps1
    pwsh -File build-readme.ps1 -RepoPath C:\src\am-torr -WhatIfOnly
#>
[CmdletBinding()]
param(
    [string]$RepoPath,
    [string]$SourceReadme,
    [string]$OutFile,
    [switch]$WhatIfOnly
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Canonical portfolio content. Edit HERE, never in README.md directly.
# ---------------------------------------------------------------------------
$Sections = @(
    [pscustomobject]@{
        Heading  = 'EOS (Executive Operating System) & Ralph Loop | 2026'
        Repo     = 'am-torr/skills'
        RepoNote = ''
        Bullets  = @(
            'Built a human-gated autonomous build pipeline that carries a written spec from queue to verified, promoted code: each task is routed for required context, approved by a human, executed by a context-shielded agent, then graded by a separate agent that can fail the build.'
            'Completed 57 specs end to end and authored 56 reusable skills, on deterministic PowerShell tooling (sequence manifest, crash-recovery markers, promotion-reconciliation gates) covered by Pester suites.'
            'Compounds each build into reusable assets -- routing rules, lint rules, skills -- so a failure mode is diagnosed once and never re-debugged.'
        )
    }
    [pscustomobject]@{
        Heading  = 'Production n8n Service | 2026-Present'
        Repo     = 'am-torr/gunpla_project_01'
        RepoNote = ''
        Bullets  = @(
            'Operates a self-hosted 19-service Docker Compose stack in production: Python/Playwright scrapers, a scheduler, n8n workflow orchestration, self-hosted Supabase (PostgreSQL + PostgREST + Kong), nginx, and a URL shortener.'
            'Runs an end-to-end scrape -> queue -> batch -> publish pipeline turning scraped retail inventory into scheduled social posts, with idempotent dedup and repost-cooldown rules enforced in the database.'
            'Migrated the data layer off hosted Supabase onto self-hosted PostgreSQL + PostgREST + Kong, keeping the cloud project as a rollback path.'
        )
    }
    [pscustomobject]@{
        Heading  = 'Autonomous Operations Agent | 2026'
        Repo     = 'am-torr/gunpla_project_01'
        RepoNote = 'subsystem: `scripts/lowstock_agent`'
        Bullets  = @(
            'Built a Claude Agent SDK pipeline that detects low-stock inventory and drafts publish-ready copy for human review; it runs alongside the production n8n flow and never auto-publishes.'
            'Enforces a hard database write boundary -- the agent writes only to its own drafts and price-history tables and reads the live publishing queue read-only through a stored procedure -- so an agent fault cannot corrupt production data.'
            'Self-corrects with a generate-and-check loop that rewrites captions until an automated checker passes, using a two-tier model split (cheap classifier, stronger writer) and an offline dry-run mode for testing without live scrapes or writes.'
        )
    }
    [pscustomobject]@{
        Heading  = 'Resume-Diff Web App | 2026'
        Repo     = 'am-torr/i-want-a-text-diff-viewer'
        RepoNote = ''
        Bullets  = @(
            'Privacy-first local web app (React + TypeScript + Express) comparing two resume versions across all four DOCX/PDF pairings -- no upload, no third-party API call, no login.'
            'Extracts and normalizes text from both binary formats, groups changes by resume section using heading-synonym mapping, flags resume-specific risks, and exports a self-contained local HTML report.'
            'Covered by unit tests, a four-pairing smoke test, and Playwright end-to-end tests; the document-processing patterns it produced were captured as reusable skills.'
        )
    }
)

$PrivateLabel      = ' (Private Repository)'
$SectionHeadingTag = '####'
$FeaturedPattern   = '^###\s+Featured Projects\s*$'

# ---------------------------------------------------------------------------
# ASCII transliteration
# ---------------------------------------------------------------------------

# Emoji / pictograph run: astral-plane surrogate pairs plus the BMP symbol blocks
# and the variation selector. Matched together with at most one flanking space so a
# dropped emoji does not leave a stray or doubled space behind.
$script:EmojiRun = '(?:[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF\u2B00-\u2BFF\uFE0F])+'

# Ordered, explicit typography map. Anything NOT listed here and not an emoji is a
# hard error (see Assert-Ascii) -- we never guess and never silently drop.
$script:CharMap = @(
    @{ From = [string][char]0x00A0; To = ' '   }  # NO-BREAK SPACE
    @{ From = [string][char]0x00B7; To = ' | ' }  # MIDDLE DOT
    @{ From = [string][char]0x2022; To = '-'   }  # BULLET
    @{ From = [string][char]0x2018; To = "'"   }  # LEFT SINGLE QUOTATION MARK
    @{ From = [string][char]0x2019; To = "'"   }  # RIGHT SINGLE QUOTATION MARK
    @{ From = [string][char]0x201A; To = "'"   }  # SINGLE LOW-9 QUOTATION MARK
    @{ From = [string][char]0x201C; To = '"'   }  # LEFT DOUBLE QUOTATION MARK
    @{ From = [string][char]0x201D; To = '"'   }  # RIGHT DOUBLE QUOTATION MARK
    @{ From = [string][char]0x2013; To = '--'  }  # EN DASH
    @{ From = [string][char]0x2014; To = '--'  }  # EM DASH
    @{ From = [string][char]0x2015; To = '--'  }  # HORIZONTAL BAR
    @{ From = [string][char]0x2026; To = '...' }  # HORIZONTAL ELLIPSIS
    @{ From = [string][char]0x2190; To = '<-'  }  # LEFTWARDS ARROW
    @{ From = [string][char]0x2192; To = '->'  }  # RIGHTWARDS ARROW
    @{ From = [string][char]0x00A9; To = '(C)' }  # COPYRIGHT SIGN
    @{ From = [string][char]0x00AE; To = '(R)' }  # REGISTERED SIGN
    @{ From = [string][char]0x2122; To = '(TM)'}  # TRADE MARK SIGN
)

function Convert-ToAscii {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    # 1. Drop emoji. Keep exactly one space when the emoji sat between two spaces,
    #    otherwise absorb the single flanking space entirely.
    $Text = [regex]::Replace($Text, "( ?)($script:EmojiRun)( ?)", {
        param($m)
        if ($m.Groups[1].Value -ne '' -and $m.Groups[3].Value -ne '') { ' ' } else { '' }
    })

    # 2. Explicit typography substitutions.
    foreach ($pair in $script:CharMap) {
        $Text = $Text.Replace($pair.From, $pair.To)
    }

    # 3. Tidy mid-line double spaces left by steps 1-2. Leading indentation and
    #    trailing markdown hard-breaks are deliberately untouched.
    $Text = [regex]::Replace($Text, '(?<=\S) {2,}(?=\S)', ' ')

    return $Text
}

function Assert-Ascii {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Label
    )
    $bad = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $code = [int]$Text[$i]
        if ($code -gt 127) {
            $from = [Math]::Max(0, $i - 25)
            $len  = [Math]::Min(50, $Text.Length - $from)
            $bad.Add(('  offset {0}: U+{1:X4} near [{2}]' -f $i, $code, $Text.Substring($from, $len)))
        }
    }
    if ($bad.Count -gt 0) {
        throw ("{0}: {1} non-ASCII char(s) survived transliteration:`n{2}" -f $Label, $bad.Count, ($bad -join "`n"))
    }
}

# ---------------------------------------------------------------------------
# LIVE GitHub visibility read
# ---------------------------------------------------------------------------
function Get-RepoIsPrivate {
    param([Parameter(Mandatory)][string]$Slug)

    $raw  = & gh repo view $Slug --json isPrivate 2>&1
    $code = $LASTEXITCODE          # PROJECT CONVENTION: grab it IMMEDIATELY.

    if ($code -ne 0) {
        Write-Warning ("gh repo view {0} failed (exit {1}): {2}" -f $Slug, $code, ($raw -join ' '))
        Write-Warning ("Defaulting {0} to PRIVATE (safe default -- never advertise a repo as public unverified)." -f $Slug)
        return $true
    }

    $json = ($raw | Out-String).Trim()
    try {
        $obj = $json | ConvertFrom-Json
    } catch {
        Write-Warning ("Could not parse gh output for {0}: {1}" -f $Slug, $json)
        return $true
    }
    if ($null -eq $obj.isPrivate) {
        Write-Warning ("gh returned no isPrivate field for {0}; defaulting to PRIVATE." -f $Slug)
        return $true
    }
    return [bool]$obj.isPrivate
}

# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
if (-not $RepoPath) {
    $candidates = @(
        (Join-Path $PSScriptRoot '..\..')          # script lives at <repo>\scratch\<task>\
        (Join-Path $PSScriptRoot 'am-torr-profile') # script lives in the EOS scratch dir
        $PSScriptRoot
    )
    foreach ($c in $candidates) {
        $full   = [System.IO.Path]::GetFullPath($c)
        $probe  = Join-Path $full 'README.md'
        if (-not (Test-Path $probe)) { continue }
        # A README is only OUR README if it carries the anchor heading. Without this
        # guard the ..\..  candidate happily matches an unrelated parent project.
        # Transliterate first: in the pre-build README the anchor still wears an emoji.
        $probeText = Convert-ToAscii -Text ([System.IO.File]::ReadAllText($probe, [System.Text.UTF8Encoding]::new($false)))
        if ($probeText -match "(?m)$FeaturedPattern") { $RepoPath = $full; break }
    }
}
if (-not $RepoPath) { throw 'Could not locate the am-torr/am-torr working copy. Pass -RepoPath.' }
$RepoPath = [System.IO.Path]::GetFullPath($RepoPath)

if (-not $SourceReadme) { $SourceReadme = Join-Path $RepoPath 'README.md' }
if (-not $OutFile)      { $OutFile      = $SourceReadme }
if (-not (Test-Path $SourceReadme)) { throw "Source README not found: $SourceReadme" }

Write-Host "Repo path : $RepoPath"
Write-Host "Source    : $SourceReadme"
Write-Host "Output    : $OutFile"
Write-Host ''

# ---------------------------------------------------------------------------
# 1. Read + transliterate the existing README
# ---------------------------------------------------------------------------
$original = [System.IO.File]::ReadAllText($SourceReadme, [System.Text.UTF8Encoding]::new($false))
$newline  = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
$ascii    = Convert-ToAscii -Text $original

# ---------------------------------------------------------------------------
# 2. Live visibility read + section rendering
# ---------------------------------------------------------------------------
$report = [System.Collections.Generic.List[string]]::new()
$body   = [System.Collections.Generic.List[string]]::new()

$anyPrivate = $false

foreach ($s in $Sections) {
    $isPrivate = Get-RepoIsPrivate -Slug $s.Repo
    $report.Add(('  {0,-34} isPrivate={1}' -f $s.Repo, $isPrivate))
    if ($isPrivate) { $anyPrivate = $true }

    $heading = $s.Heading
    if ($isPrivate) { $heading += $PrivateLabel }

    $link = ('Repository: [{0}](https://github.com/{0})' -f $s.Repo)
    if ($s.RepoNote) { $link += (' -- {0}' -f $s.RepoNote) }

    $body.Add('')
    $body.Add(('{0} {1}' -f $SectionHeadingTag, $heading))
    $body.Add('')
    $body.Add($link)
    $body.Add('')
    foreach ($b in $s.Bullets) { $body.Add(('- {0}' -f $b)) }
}

# Repos above are private by default. Emit an access note ONLY while at least one
# still is, so the line retires itself automatically if they are ever opened up.
if ($anyPrivate) {
    $body.Add('')
    $body.Add('_The repositories above are private. Read-only access can be granted on request -- happy to walk through any of the code._')
}

$body.Add('')

# ---------------------------------------------------------------------------
# 3. Replace the whole body of the "Featured Projects" section (idempotent:
#    drops the legacy markdown table AND any previously generated sections).
# ---------------------------------------------------------------------------
$lines    = $ascii -split "`r`n|`n"
$startIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $FeaturedPattern) { $startIdx = $i; break }
}
if ($startIdx -lt 0) {
    throw "Could not find a '### Featured Projects' heading in $SourceReadme -- refusing to guess where the portfolio goes."
}

$endIdx = $lines.Count
for ($i = $startIdx + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^-{3,}\s*$' -or $lines[$i] -match '^#{1,3}\s') { $endIdx = $i; break }
}

$out = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -le $startIdx; $i++) { $out.Add($lines[$i]) }
foreach ($l in $body)                { $out.Add($l) }
for ($i = $endIdx; $i -lt $lines.Count; $i++) { $out.Add($lines[$i]) }

$final = ($out -join $newline)

# ---------------------------------------------------------------------------
# 4. Verify, then write ASCII + BOM-free
# ---------------------------------------------------------------------------
Assert-Ascii -Text $final -Label 'Assembled README'

$headingCount = ([regex]::Matches($final, '(?m)^' + [regex]::Escape($SectionHeadingTag) + '\s')).Count
if ($headingCount -ne $Sections.Count) {
    throw ("Expected {0} project sections, produced {1}." -f $Sections.Count, $headingCount)
}
foreach ($token in @('About Me', 'Current Stack', 'Featured Projects', 'Activity', 'linkedin.com/in/arvintorralba012', 'github-readme-stats')) {
    if ($final -notmatch [regex]::Escape($token)) {
        throw "Preserved content check FAILED: '$token' is missing from the assembled README."
    }
}
if ($final -match '(?i)\b(TODO|FIXME|lorem ipsum|placeholder)\b') {
    throw 'Placeholder/TODO text detected in the assembled README.'
}

Write-Host 'Live gh visibility reads:'
$report | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host ('Project sections : {0}' -f $headingCount)
Write-Host ('Newline          : {0}' -f $(if ($newline -eq "`r`n") { 'CRLF' } else { 'LF' }))
Write-Host ('Chars            : {0}' -f $final.Length)
Write-Host ('Non-ASCII        : 0 (asserted)')

if ($WhatIfOnly) {
    Write-Host ''
    Write-Host 'WhatIfOnly: nothing written.'
    return
}

[System.IO.File]::WriteAllText($OutFile, $final, [System.Text.UTF8Encoding]::new($false))

$bytes = [System.IO.File]::ReadAllBytes($OutFile)
$hiBytes = @($bytes | Where-Object { $_ -gt 127 }).Count
$hasBom  = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
if ($hiBytes -ne 0) { throw "Wrote $hiBytes byte(s) above 127 to $OutFile." }
if ($hasBom)        { throw "Wrote a UTF-8 BOM to $OutFile." }

Write-Host ''
Write-Host ('WROTE {0} ({1} bytes, 0 bytes >127, BOM=False)' -f $OutFile, $bytes.Length)
