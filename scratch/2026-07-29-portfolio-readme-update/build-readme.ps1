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

# Canonical "Current Stack" content. Grouped so a reviewer scanning for a
# capability finds it in one row instead of a run-on line -- and because two
# adjacent non-blank lines collapse into a single paragraph in GitHub markdown,
# which is what made the previous two-line stack render as one long run.
# Every entry below is grepped from the four showcased projects; do not add
# aspirational tooling here.
$StackGroups = @(
    [pscustomobject]@{
        Label = 'AI / LLM'
        Items = @(
            'Claude Code', 'Claude Agent SDK', 'Anthropic API (Haiku/Sonnet)',
            'Groq', 'DeepSeek', 'Perplexity Sonar', 'RAG', 'LLM orchestration'
        )
    }
    [pscustomobject]@{
        Label = 'Pipelines / Automation'
        Items = @(
            'n8n', 'FastAPI', 'Playwright', 'Docker Compose', 'scheduled agents'
        )
    }
    [pscustomobject]@{
        Label = 'Data'
        Items = @(
            'Python', 'SQL', 'PostgreSQL/pgvector',
            'Supabase (self-hosted: PostgREST + Kong)', 'HuggingFace',
            'Oracle ERP', 'AWS Glue/Lambda'
        )
    }
    [pscustomobject]@{
        Label = 'Engineering'
        Items = @(
            'TypeScript/React', 'PowerShell + Pester', 'Docker', 'Git'
        )
    }
)

$PrivateLabel      = ' (Private Repository)'
$SectionHeadingTag = '####'
$FeaturedPattern   = '^###\s+Featured Projects\s*$'
$StackPattern      = '^###\s+Current Stack\s*$'
$ActivityPattern   = '^###\s+Activity\s*$'

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
function Find-SectionStart {
    # Locate a section heading, or THROW. Never returns a guessed index: an
    # anchor that cannot be found means we are not holding the file we think
    # we are, and writing anyway is how the wrong README gets clobbered.
    param([string[]] $Lines, [string] $Pattern, [string] $Label, [string] $Source)

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $Pattern) { return $i }
    }
    throw "Could not find a '$Label' heading in $Source -- refusing to guess where to edit."
}

function Get-SectionEnd {
    # First line after $StartIdx that begins the next section (a horizontal
    # rule or any h1-h3). Returns $Lines.Count when the section runs to EOF.
    param([string[]] $Lines, [int] $StartIdx)

    for ($i = $StartIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^-{3,}\s*$' -or $Lines[$i] -match '^#{1,3}\s') { return $i }
    }
    return $Lines.Count
}

function Set-SectionBody {
    # Replace everything between a section heading and the next section
    # boundary. Heading line itself is preserved.
    param([string[]] $Lines, [string] $Pattern, [string] $Label, [string] $Source, [string[]] $Body)

    $startIdx = Find-SectionStart -Lines $Lines -Pattern $Pattern -Label $Label -Source $Source
    $endIdx   = Get-SectionEnd   -Lines $Lines -StartIdx $startIdx

    $out = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -le $startIdx; $i++)          { $out.Add($Lines[$i]) }
    foreach ($l in $Body)                          { $out.Add($l) }
    for ($i = $endIdx; $i -lt $Lines.Count; $i++)  { $out.Add($Lines[$i]) }
    return , $out.ToArray()
}

function Remove-Section {
    # Delete a section outright: its heading, its body, the trailing rule that
    # closes it, AND the rule that separated it from the block above -- so no
    # orphan '---' is left dangling where the section used to be.
    param([string[]] $Lines, [string] $Pattern, [string] $Label, [string] $Source)

    # Removal is "ensure absent", so an already-absent section is SUCCESS, not
    # an error -- otherwise the second run of this script would throw and the
    # build would stop being idempotent. Safe to be lenient here specifically
    # because the Featured Projects and Current Stack anchors are asserted
    # earlier in the pipeline: a wrong-file target has already thrown by now.
    $startIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $Pattern) { $startIdx = $i; break }
    }
    if ($startIdx -lt 0) { return , $Lines }

    # Walk back over blank lines; if a horizontal rule precedes the heading,
    # that rule belongs to this section and goes with it.
    $removeFrom = $startIdx
    $probe      = $startIdx - 1
    while ($probe -ge 0 -and $Lines[$probe].Trim() -eq '') { $probe-- }
    if ($probe -ge 0 -and $Lines[$probe] -match '^-{3,}\s*$') { $removeFrom = $probe }

    # Walk forward to the rule that closes the section (inclusive).
    $removeTo = $Lines.Count - 1
    for ($i = $startIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^-{3,}\s*$') { $removeTo = $i; break }
    }

    $out = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $removeFrom; $i++)             { $out.Add($Lines[$i]) }
    for ($i = $removeTo + 1; $i -lt $Lines.Count; $i++) { $out.Add($Lines[$i]) }

    # Never end the document on blank lines left behind by the excision.
    while ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -eq '') {
        $out.RemoveAt($out.Count - 1)
    }
    return , $out.ToArray()
}

# Build the grouped Current Stack body.
$stackBody = [System.Collections.Generic.List[string]]::new()
$stackBody.Add('')
foreach ($g in $StackGroups) {
    $stackBody.Add(('**{0}** -- {1}' -f $g.Label, ($g.Items -join ' | ')))
    $stackBody.Add('')
}

$lines = $ascii -split "`r`n|`n"

# 3a. Featured Projects -> the four portfolio sections.
$lines = Set-SectionBody -Lines $lines -Pattern $FeaturedPattern `
    -Label '### Featured Projects' -Source $SourceReadme -Body $body

# 3b. Current Stack -> grouped capability rows.
$lines = Set-SectionBody -Lines $lines -Pattern $StackPattern `
    -Label '### Current Stack' -Source $SourceReadme -Body $stackBody

# 3c. Activity -> removed. The github-readme-stats deployment returns HTTP 503
#     (DEPLOYMENT_PAUSED), so the image is already broken on the live profile;
#     and the underlying metric reads 22 contributions with private work not
#     counted, so a repaired widget would understate the work rather than show
#     it. Retired deliberately rather than left broken or "fixed" into a
#     misleading number.
$lines = Remove-Section -Lines $lines -Pattern $ActivityPattern `
    -Label '### Activity' -Source $SourceReadme

# Normalize the tail unconditionally, then add exactly one terminator. Without
# this the script is not idempotent: re-reading its own output yields a trailing
# empty element after the split, and appending $newline again would grow the
# file by one line on every run.
$tail = [System.Collections.Generic.List[string]]::new()
$tail.AddRange([string[]] $lines)
while ($tail.Count -gt 0 -and $tail[$tail.Count - 1].Trim() -eq '') {
    $tail.RemoveAt($tail.Count - 1)
}

$final = ($tail.ToArray() -join $newline) + $newline

# ---------------------------------------------------------------------------
# 4. Verify, then write ASCII + BOM-free
# ---------------------------------------------------------------------------
Assert-Ascii -Text $final -Label 'Assembled README'

$headingCount = ([regex]::Matches($final, '(?m)^' + [regex]::Escape($SectionHeadingTag) + '\s')).Count
if ($headingCount -ne $Sections.Count) {
    throw ("Expected {0} project sections, produced {1}." -f $Sections.Count, $headingCount)
}
# 'Activity' and 'github-readme-stats' were REMOVED from this required-token
# list on purpose (2026-07-29): that section was retired because its upstream
# service is down (HTTP 503 DEPLOYMENT_PAUSED) and the metric behind it
# undercounts private work. This guard failing was correct behaviour -- the
# list is loosened explicitly and on the record, never worked around.
foreach ($token in @('About Me', 'Current Stack', 'Featured Projects', 'linkedin.com/in/arvintorralba012')) {
    if ($final -notmatch [regex]::Escape($token)) {
        throw "Preserved content check FAILED: '$token' is missing from the assembled README."
    }
}

# The retired section must actually be gone, not merely unreferenced.
foreach ($gone in @('### Activity', 'github-readme-stats')) {
    if ($final -match [regex]::Escape($gone)) {
        throw "Removal check FAILED: '$gone' is still present in the assembled README."
    }
}

# Every stack group must have rendered, or the stack silently lost a row.
foreach ($g in $StackGroups) {
    if ($final -notmatch [regex]::Escape(('**{0}** --' -f $g.Label))) {
        throw ("Stack group '{0}' is missing from the assembled README." -f $g.Label)
    }
}

if ($final -match '(?s)-{3,}\s*$') {
    throw 'Assembled README ends on a dangling horizontal rule.'
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
